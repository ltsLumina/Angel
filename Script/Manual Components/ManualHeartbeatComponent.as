class UManualHeartbeatComponent : UActorComponent
{
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    bool UseHeartbeat;
    default UseHeartbeat = true;

    // The current heart rate in beats per minute (BPM). Average resting heart rate is around 60-100 BPM.
    UPROPERTY(Category = "Config | Heartbeat", VisibleAnywhere)
    float CurrentBPM;
    default CurrentBPM = 60; // Default to 60 beats per minute

    // The upper limit for the heart rate. Reaching this will kill the player.
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    float MaxBPM;
    default MaxBPM = 220;

    // The minimum heart rate for the player. Reaching this will kill the player.
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    float MinBPM;
    default MinBPM = 0;

    // The time window in which the player must press the beat key to register a successful beat.
    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    float BeatWindow;
    default BeatWindow = .5f; // in ms

    // The time window in which the player can successfully press the beat key (as a percentage, 1 = 1%)
    UPROPERTY(Category = "Config | Input", EditDefaultsOnly)
    float BeatWindowPercent;
    default BeatWindowPercent = 30.0f; // 30%

    UPROPERTY(Category = "Config | Input", EditDefaultsOnly)
    float HeartbeatLeadTime = 0.15f; // seconds before beat to play the heartbeat sound cue

    // Tracks the last time the beat was pressed to prevent spamming
    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    float LastBeatPressTime;
    default LastBeatPressTime = -999.0f; // Start with a negative value to allow immediate first press

    // Within this threshold , the player is considered in a fatigue state, which slows down the game speed.
    UPROPERTY(Category = "Config | State | Fatigue", EditDefaultsOnly)
    FVector2D FatigueRange;
    default FatigueRange = FVector2D(20, 40);

    UPROPERTY(Category = "Config | State | Fatigue", EditDefaultsOnly)
    float FatigueSpeedMultiplier;
    default FatigueSpeedMultiplier = 0.75f;

    // Within this threshold, the player is considered in a 'flow' state, which speeds up their actions.
    UPROPERTY(Category = "Config | State | Flow", EditDefaultsOnly)
    FVector2D FlowRange;
    default FlowRange = FVector2D(180, 200);

    UPROPERTY(Category = "Config | State | Flow", EditDefaultsOnly)
    float FlowSpeedMultiplier;

    UPROPERTY(Category = "Config | Cardiac Arrest", VisibleAnywhere, BlueprintGetter = "GetIsInCardiacArrest")
    bool IsInCardiacArrest;

    UFUNCTION(BlueprintPure, Category = "Config | Cardiac Arrest")
    bool GetIsInCardiacArrest() const { return CurrentBPM == 0; }

    // The chance of cardiac arrest occurring when the heart rate is above a certain threshold for a sustained period, which accumulates while the player is in a high BPM state.
    UPROPERTY(Category = "Config | Cardiac Arrest", EditDefaultsOnly,  Meta=(Units="Percent"))
    float CardiacArrestChance;
    default CardiacArrestChance = 0.1f; // 0.1% chance per beat (1 = 1%)

    // Threshold for minimum cardiac arrest chance. If the cumulative chance is below this, cardiac arrest will not occur.
    UPROPERTY(Category = "Config | Cardiac Arrest", EditDefaultsOnly, Meta=(Units="Percent"))
    float MinCardiacArrestChance;
    default MinCardiacArrestChance = 1.0f; // 1% minimum threshold

    
    // An accumulated risk of cardiac arrest that persists even after leaving high BPM states.
    UPROPERTY(Category = "Config | Cardiac Arrest", VisibleAnywhere, Meta=(Units="Percent"))
    float PersistentRisk;
    default PersistentRisk = 0.0f;

    // The percentage of the last risk that is retained after leaving high BPM.
    UPROPERTY(Category = "Config | Cardiac Arrest", EditDefaultsOnly, Meta=(Units="Percent"))
    float PersistentRiskRetention;
    default PersistentRiskRetention = 10;

    // The last cumulative chance of cardiac arrest based on consecutive high BPM beats.
    UPROPERTY(Category = "Config | Cardiac Arrest", VisibleAnywhere, Meta=(Units="Percent"))
    float LastCumulativeChance;

    // Tracks the number of consecutive high BPM beats.
    UPROPERTY(Category = "Config | Cardiac Arrest", VisibleAnywhere, DisplayName = "Consecutive High BPM Beats")
    int ConsecutiveHighBPMBeats = 0;

    const int SecondsInMinute = 60; // Total seconds in a minute. Used for 'beats per minute' calculations.

    // Tracks the next time the beat should occur based on the current BPM.
    float NextBeatTime;
    bool bBeatPressed = false;

    FTimerHandle HeartBeatTimer;

    int SurvivalTicks = 0;
    bool bSimulatingSurvival = false;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BP_BeginPlay();

        float BeatInterval = SecondsInMinute / CurrentBPM;
        NextBeatTime = System::GetGameTimeInSeconds() + BeatInterval;
        HeartBeatTimer = System::SetTimer(this, n"OnHeartBeat", BeatInterval, true);

        OnHeartBeat(); // Trigger the first heartbeat immediately
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    // Helper to convert percent property (1 = 1%) to normalized value (0.01 = 1%)
    float PercentToNormalized(float PercentValue)
    {
        return PercentValue * 0.01f;
    }

    // This is likely going to be deprecated.
    UFUNCTION(NotBlueprintCallable)
    void OnKeyPressed(FKey _)
    {
        float CurrentTime = System::GetGameTimeInSeconds();
        float BeatInterval = SecondsInMinute / CurrentBPM;
        // Use normalized percent for BeatWindowPercent
        BeatWindow = BeatInterval * PercentToNormalized(BeatWindowPercent);

        // Prevent spamming: ignore if pressed too soon after last press
        if (CurrentTime - LastBeatPressTime < BeatInterval * 0.6f)
        {
            Print("Too soon!", .3f, FLinearColor::Yellow);
            return;
        }

        LastBeatPressTime = CurrentTime;

        // Check if within window
        if (Math::Abs(CurrentTime - NextBeatTime) <= BeatWindow)
        {
            bBeatPressed = true;
            Print(f"On Beat! ({CurrentBPM} BPM)", .5f, FLinearColor::Green);
        }
    }

    UFUNCTION()
    void OnHeartBeat()
    {
        if (!UseHeartbeat) return;
        if (GetIsInCardiacArrest()) return;

        if (!bBeatPressed)
        {
            CurrentBPM = Math::Clamp(CurrentBPM - 1, MinBPM, MaxBPM);
            //Print("Missed Beat!", 0.5f, FLinearColor::Red);
        }
        else
        {
            bBeatPressed = false;
        }

        if (CurrentBPM == 0) { return; }
        float BeatInterval = SecondsInMinute / CurrentBPM;
        NextBeatTime = System::GetGameTimeInSeconds() + BeatInterval;

        System::SetTimer(this, n"OnHeartBeat", BeatInterval, true);
        Print(f"Heartbeat: {CurrentBPM} BPM", BeatInterval, FLinearColor(0.79, 0.25, 0.55));

        if (CurrentBPM > FlowRange.Y)
        {
            Print("Heart rate too high! Cardiac arrest imminent!", BeatInterval, FLinearColor::Red);

            ConsecutiveHighBPMBeats++; // Increment counter

            // Randomly increase between 0% and 1% per beat (1 = 1%)
            float RandomIncrease = Math::RandRange(0.0f, 0.1f); // 0.1 = 0.1%
            CardiacArrestChance = Math::Clamp(CardiacArrestChance + RandomIncrease, 0.0f, 100.0f);

            // Combine current chance with persistent risk (all in percent)
            float Chance = CardiacArrestChance + PersistentRisk;
            Chance = Math::Clamp(Chance, 0.0f, 100.0f);

            LastCumulativeChance = Chance;

            Print(f"Cardiac Arrest Chance: {Chance}%", BeatInterval, FLinearColor::Yellow);
            Print(f"Consecutive High BPM Beats: {ConsecutiveHighBPMBeats}", BeatInterval, FLinearColor::Yellow);
            Print(f"Persistent Risk: {PersistentRisk}%", BeatInterval, FLinearColor::Yellow);

            // Only allow cardiac arrest if chance is above the minimum threshold
            if (Chance >= MinCardiacArrestChance && Math::RandRange(0.0f, 1.0f) < PercentToNormalized(Chance))
            {
                Print("Cardiac arrest occurred!", 10.0f, FLinearColor::Red);
                
                OnCardiacArrest();
            }
        }
        else
        {
            // When leaving high BPM, retain a portion of the last risk
            if (ConsecutiveHighBPMBeats > 0)
            {
                PersistentRisk += LastCumulativeChance * PercentToNormalized(PersistentRiskRetention);
                PersistentRisk = Math::Clamp(PersistentRisk, 0.0f, 100.0f);
            }
            ConsecutiveHighBPMBeats = 0; // Reset if not in high BPM
            LastCumulativeChance = 0.0f;
        }

        // Check for flow state (BPM within flow range)
        if (CurrentBPM < FlowRange.Y && CurrentBPM > FlowRange.X)
        {
            Print("Heart rate in flow state!", BeatInterval, FLinearColor::Green);
            GameplayTag::AddGameplayTag(GetAngelCharacter(GetOwner()).GameplayTags, GameplayTags::Buffs_State_Flow);
        }
        else 
        {
            GameplayTag::RemoveGameplayTag(GetAngelCharacter(GetOwner()).GameplayTags, GameplayTags::Buffs_State_Flow);
        }

        // Check for fatigue state (BPM within fatigue range)
        if (CurrentBPM < FatigueRange.Y && CurrentBPM > FatigueRange.X)
        {
            Print("Heart rate in fatigue state!", BeatInterval, FLinearColor::Blue);
            GameplayTag::AddGameplayTag(GetAngelCharacter(GetOwner()).GameplayTags, GameplayTags::Buffs_State_Fatigue);
        }
        else
        {
            GameplayTag::RemoveGameplayTag(GetAngelCharacter(GetOwner()).GameplayTags, GameplayTags::Buffs_State_Fatigue);
        }
        
        BP_OnHeartBeat(CurrentBPM);
    }

    UFUNCTION(BlueprintEvent, DisplayName = "On Cardiac Arrest")
    void BP_OnCardiacArrest() { }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Heart Beat"))
    void BP_OnHeartBeat(float InCurrentBPM) { }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Heart Beat (Early)"))
    void BP_OnHeartBeatEarly() { }

    // utility functions

    UFUNCTION(CallInEditor)
    void IncreaseBPM(float Amount = 5.0f)
    {
        CurrentBPM = Math::Clamp(CurrentBPM + Amount, MinBPM, MaxBPM);
        UpdateHeartBeatTimer();
        //Print(f"BPM Increased: {CurrentBPM}", 1.0f, FLinearColor::Green);
    }

    UFUNCTION(CallInEditor)
    void DecreaseBPM(float Amount = 5.0f)
    {
        CurrentBPM = Math::Clamp(CurrentBPM - Amount, MinBPM, MaxBPM);
        UpdateHeartBeatTimer();
        //Print(f"BPM Decreased: {CurrentBPM}", 1.0f, FLinearColor::Red);
    }

    void UpdateHeartBeatTimer()
    {
        float BeatInterval = SecondsInMinute / CurrentBPM;
        System::ClearAndInvalidateTimerHandle(HeartBeatTimer);
        NextBeatTime = System::GetGameTimeInSeconds() + BeatInterval;
        HeartBeatTimer = System::SetTimer(this, n"OnHeartBeat", BeatInterval, true);
    }

    UFUNCTION(CallInEditor, DisplayName = "Induce Cardiac Arrest")
    void OnCardiacArrest()
    {
        CurrentBPM = 0; // Set BPM to 0 to simulate cardiac arrest
        System::ClearAndInvalidateTimerHandle(HeartBeatTimer); // Stop heartbeat timer

        UCameraComponent::Get(GetAngelCharacter(GetOwner())).PostProcessSettings.ColorGamma = FVector4(0.5f,0.5f,0.5f,0.5f);
        UCameraComponent::Get(GetAngelCharacter(GetOwner())).bUsePawnControlRotation = false;
        UCameraComponent::Get(GetAngelCharacter(GetOwner())).SetRelativeRotation(FRotator(0,0,90));

        BP_OnCardiacArrest();
    }
};

UFUNCTION(BlueprintPure)
bool IsAlive(UManualHeartbeatComponent Target)
{
    return IsValid(Target) && Target.UseHeartbeat && !Target.GetIsInCardiacArrest();
}