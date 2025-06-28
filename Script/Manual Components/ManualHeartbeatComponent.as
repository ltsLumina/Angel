event void FOnHeartBeat(float CurrentBPM);
event void FOnDeath();

class UManualHeartbeatComponent : UActorComponent
{
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    bool UseHeartbeat;
    default UseHeartbeat = true;

    UPROPERTY(Category = "Config | Heartbeat", VisibleAnywhere)
    bool IsHeartbeatPaused;
    default IsHeartbeatPaused = false;

    // The current heart rate in beats per minute (BPM). Average resting heart rate is around 60-100 BPM.
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    float CurrentBPM;
    default CurrentBPM = 60;

    // The upper limit for the heart rate. Reaching this will kill the player.
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    float MaxBPM;
    default MaxBPM = 220;

    // The minimum heart rate for the player. Reaching this will kill the player.
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    float MinBPM;
    default MinBPM = 20;

    UPROPERTY(Category = "Config | State | Fatigue", VisibleAnywhere, BlueprintGetter = "GetBeatInterval", Meta=(Units="Seconds"))
    float BeatInterval;
    default BeatInterval = SecondsInMinute / CurrentBPM;

    UFUNCTION(BlueprintPure, Category = "Config | Heartbeat")
    float GetBeatInterval() const { return SecondsInMinute / CurrentBPM; }

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

    // Is the player dead.
    UPROPERTY(Category = "Config | Cardiac Arrest", VisibleAnywhere)
    bool IsFlatlined;

#if EDITOR
    UPROPERTY(Category = "Config | Cardiac Arrest", VisibleAnywhere, BlueprintGetter = GetAverageSurvivalTimeAtHighBPM, Meta=(Units="Seconds"))
    float AverageSurvivalTime;
#endif

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

    UPROPERTY(Category = "Events")
    FOnHeartBeat OnHeartBeat;

    UPROPERTY(Category = "Events")
    FOnDeath OnDeath;

// - Constants & References

    const int SecondsInMinute = 60; // Total seconds in a minute. Used for 'beats per minute' calculations.
    FTimerHandle HeartBeatTimer;
    AAngelPlayerCharacter Character;

    // Helper to convert percent property (1 = 1%) to normalized value (0.01 = 1%)
    float PercentToNormalized(float PercentValue)
    {
        if (PercentValue < 0.0f || PercentValue > 100.0f)
        {
            Print("Percent value out of range! Must be between 0 and 100.", 2.0f, FLinearColor::Red);
            return 0.0f;
        }

        return PercentValue * 0.01f;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Character = GetAngelCharacter(GetOwner());

        BP_BeginPlay();

        Heartbeat(); // Trigger the first heartbeat immediately
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (CurrentBPM <= MinBPM)
        {
            if (IsFlatlined) return;

            // Trigger cardiac arrest if BPM is less than minimum
            OnCardiacArrest();
        }

        BP_Tick(DeltaSeconds);   
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Tick")
    void BP_Tick(float DeltaSeconds) { }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(NotBlueprintCallable)
    void Heartbeat()
    {
        if (!UseHeartbeat) return;
        if (IsFlatlined) return;

        // Decrement BPM if heartbeat is not paused
        if (!IsHeartbeatPaused) CurrentBPM = Math::Clamp(CurrentBPM - 1, MinBPM, MaxBPM);

        HeartBeatTimer = System::SetTimer(this, n"Heartbeat", GetBeatInterval(), false);
        Print(!IsHeartbeatPaused ? f"Heartbeat: {CurrentBPM} BPM" : "Heartbeat is paused!", GetBeatInterval(), FLinearColor(0.79, 0.25, 0.55));

        if (CurrentBPM > FlowRange.Y)
        {
            Print("Heart rate too high! Cardiac arrest imminent!", GetBeatInterval(), FLinearColor::Red);

            ConsecutiveHighBPMBeats++; // Increment counter

            // Randomly increase between 0% and 1% per beat (1 = 1%)
            float RandomIncrease = Math::RandRange(0.0f, 0.1f); // 0.1 = 0.1%
            CardiacArrestChance = Math::Clamp(CardiacArrestChance + RandomIncrease, 0.0f, 100.0f);

            // Combine current chance with persistent risk (all in percent)
            float ChancePerBeat = CardiacArrestChance + PersistentRisk;
            ChancePerBeat = Math::Clamp(ChancePerBeat, 0.0f, 100.0f);
            float NormalizedChance = PercentToNormalized(ChancePerBeat);
            float CardiacArrestValue = Math::RandRange(0.0f, 1.0f);

            LastCumulativeChance = ChancePerBeat;

            Print(f"Normalized Chance: {NormalizedChance}", GetBeatInterval(), FLinearColor::Yellow);
            Print(f"Cardiac Arrest Chance: {ChancePerBeat}%", GetBeatInterval(), FLinearColor::Yellow);
            Print(f"Consecutive High BPM Beats: {ConsecutiveHighBPMBeats}", GetBeatInterval(), FLinearColor::Yellow);
            Print(f"Persistent Risk: {PersistentRisk}%", GetBeatInterval(), FLinearColor::Yellow);

            // Only allow cardiac arrest if chance is above the minimum threshold
            if (ChancePerBeat >= MinCardiacArrestChance && CardiacArrestValue < NormalizedChance)
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
        if (CurrentBPM <= FlowRange.Y && CurrentBPM >= FlowRange.X)
        {
            Print("Heart rate in flow state!", GetBeatInterval(), FLinearColor::Green);
            
            // If the flow state tag is not already present, trigger the effect gained event
            if (!GameplayTag::HasTag(Character.GameplayTags, GameplayTags::Buffs_State_Flow, true))
            {
                GameplayTag::AddGameplayTag(GetAngelCharacter(GetOwner()).GameplayTags, GameplayTags::Buffs_State_Flow);
                OnEffectGained(GameplayTags::Buffs_State_Flow);
            }
        }
        else 
        {
            if (GameplayTag::HasTag(Character.GameplayTags, GameplayTags::Buffs_State_Flow, true))
            {
                GameplayTag::RemoveGameplayTag(Character.GameplayTags, GameplayTags::Buffs_State_Flow);
                OnEffectLost(GameplayTags::Buffs_State_Flow);
            }
        }

        // Check for fatigue state (BPM within fatigue range)
        if (CurrentBPM < FatigueRange.Y && CurrentBPM >= FatigueRange.X)
        {
            Print("Heart rate in fatigue state!", GetBeatInterval(), FLinearColor::Blue);
            
            // If the fatigue state tag is not already present, trigger the effect gained event
            if (!GameplayTag::HasTag(Character.GameplayTags, GameplayTags::Buffs_State_Fatigue, true))
            {
                GameplayTag::AddGameplayTag(Character.GameplayTags, GameplayTags::Buffs_State_Fatigue);
                OnEffectGained(GameplayTags::Buffs_State_Fatigue);
            }
        }
        else
        {
            if (GameplayTag::HasTag(Character.GameplayTags, GameplayTags::Buffs_State_Fatigue, true))
            {
                GameplayTag::RemoveGameplayTag(Character.GameplayTags, GameplayTags::Buffs_State_Fatigue);
                OnEffectLost(GameplayTags::Buffs_State_Fatigue);
            }
        }
        
        OnHeartBeat.Broadcast(CurrentBPM);
        BP_OnHeartBeat(CurrentBPM);
    }

    void OnEffectGained(FGameplayTag Tag)
    {
        Character.OnEffectGained.Broadcast(Tag, GetOwner());
    }

    void OnEffectLost(FGameplayTag Tag)
    {
        Character.OnEffectLost.Broadcast(Tag, GetOwner());
    }


    UFUNCTION(CallInEditor, DisplayName = "Induce Cardiac Arrest")
    void OnCardiacArrest()
    {
        if (IsFlatlined) return;

        IsFlatlined = true;

        CurrentBPM = 0;
        System::ClearAndInvalidateTimerHandle(HeartBeatTimer);

        UCameraComponent Camera = UCameraComponent::Get(Character);
        Camera.PostProcessSettings.ColorGamma = FVector4(0.5f,0.5f,0.5f,0.5f);
        Camera.bUsePawnControlRotation = false;
        Camera.SetRelativeRotation(FRotator(0,0,90));

        OnDeath.Broadcast();
        BP_OnCardiacArrest();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Cardiac Arrest")
    void BP_OnCardiacArrest() { }

    UFUNCTION(BlueprintEvent, DisplayName = "Heart Beat")
    void BP_OnHeartBeat(float InCurrentBPM) { }

// - Utility

    UFUNCTION(CallInEditor)
    void IncreaseBPM(float Amount = 5.0f)
    {
        CurrentBPM = Math::Clamp(CurrentBPM + Amount, MinBPM, MaxBPM);
        UpdateHeartBeatTimer();
    }

    UFUNCTION(CallInEditor)
    void DecreaseBPM(float Amount = 5.0f)
    {
        CurrentBPM = Math::Clamp(CurrentBPM - Amount, MinBPM, MaxBPM);
        UpdateHeartBeatTimer();
    }

    void UpdateHeartBeatTimer()
    {
        System::ClearAndInvalidateTimerHandle(HeartBeatTimer);
        HeartBeatTimer = System::SetTimer(this, n"Heartbeat", GetBeatInterval(), false);
    }

    UFUNCTION()
    void PauseHeartbeat()
    {
        IsHeartbeatPaused = true;
    }

    UFUNCTION()
    void ResumeHeartbeat()
    {
        IsHeartbeatPaused = false;
    }

    UFUNCTION(BlueprintPure)
    bool IsAlive()
    {
        return IsValid(this) && UseHeartbeat && !IsFlatlined;
    }

// - utility func

#if EDITOR
/**
 * Calculate and return the average survival time in seconds at 220 BPM,
 * given the current cardiac arrest settings.
 */
UFUNCTION(NotBlueprintCallable, BlueprintPure)
float GetAverageSurvivalTimeAtHighBPM()
{
    // Use 220 BPM for calculation regardless of current BPM
    float bpm = 220.0f;
    float beatsPerSecond = bpm / 60.0f;

    // Use current CardiacArrestChance and MinCardiacArrestChance
    float chancePerBeat = CardiacArrestChance;
    float minChance = MinCardiacArrestChance;

    // Average increase per beat (assuming random between 0 and CardiacArrestChance)
    float avgIncreasePerBeat = CardiacArrestChance * 0.5f;

    // Beats needed to reach minChance
    float beatsToMinChance = (minChance > 0.0f && avgIncreasePerBeat > 0.0f) ? (minChance / avgIncreasePerBeat) : 0.0f;
    float timeToMinChance = beatsToMinChance / beatsPerSecond;

    // Once at minChance, expected beats before arrest = 1 / (minChance * 0.01)
    float normalizedMinChance = minChance * 0.01f;
    float expectedBeatsAfterMin = (normalizedMinChance > 0.0f) ? (1.0f / normalizedMinChance) : 0.0f;
    float timeAfterMinChance = expectedBeatsAfterMin / beatsPerSecond;

    return timeToMinChance + timeAfterMinChance;
}
#endif
};