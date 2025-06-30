//event void FOnInitiateReload(AManualGun Gun);
//event void FOnReloadComplete(AManualGun Gun);

class UManualReloadComponent : UActorComponent
{
// - config | reload

    UPROPERTY(Category = "Config | Reload", VisibleAnywhere)
    AManualGun EquippedGun;

    UPROPERTY(Category = "Config | Reload", BlueprintGetter = "GetIsReloading", VisibleAnywhere)
    bool IsReloading;

    UFUNCTION(BlueprintPure, Category = "Reload")
    bool GetIsReloading() const { return GeneratedKeys.Num() > 0; }

    UPROPERTY(Category = "Config | Reload", EditDefaultsOnly)
    TArray<FKey> LegalKeys;

    UPROPERTY(Category = "Config | Reload", VisibleAnywhere)
    TArray<FKey> GeneratedKeys;

    // Modifies the legal keys for the reload sequence to only use keys: 1, 2, and 3.
    UPROPERTY(Category = "Config | Reload | Debug", EditDefaultsOnly)
    bool UseDebugReloadKeys;
    default UseDebugReloadKeys = true;

// - config | input

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    float TimeSinceInput;

    UPROPERTY(Category = "Config | Input", EditDefaultsOnly)
    float InputDelay;
    default InputDelay = 0.5; // Time in seconds before the next input is considered valid

// - events

/*
    UPROPERTY(Category = "Events")
    FOnInitiateReload OnInitiateReloadEvent;

    UPROPERTY(Category = "Events")
    FOnReloadComplete OnReloadCompleteEvent;
*/

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        TimeSinceInput += DeltaSeconds;
        
        BP_Tick(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Tick"))
    void BP_Tick(float DeltaSeconds) { }

    UFUNCTION(BlueprintPure, Category = "Reload")
    TArray<FKey> GenerateReloadKeys(int ReloadSteps = 3)
    {
        TArray<FKey> SequenceKeys;

        if (UseDebugReloadKeys)
        {
            int Steps = Math::Clamp(ReloadSteps, 1, 3);
            if (Steps >= 1) SequenceKeys.Add(EKeys::One);
            if (Steps >= 2) SequenceKeys.Add(EKeys::Two);
            if (Steps >= 3) SequenceKeys.Add(EKeys::Three);

            for (int i = 0; i < ReloadSteps; ++i)
            {
                //Print(f"Debug Key: {i + 1}", Math::Min(ReloadSteps, 10), FLinearColor(0.58, 0.95, 0.49));
            }
        }
        else
        {
            // Ensure we don't request more unique keys than available
            int Steps = Math::Min(ReloadSteps, LegalKeys.Num());
            
            TArray<FKey> ShuffledKeys = LegalKeys;
            ShuffledKeys.Shuffle();

            for (int i = 0; i < Steps; ++i)
            {
                SequenceKeys.Add(ShuffledKeys[i]);
                Print(f"Key {i + 1}: {ShuffledKeys[i].GetDisplayName()}", Math::Min(ReloadSteps, 10), FLinearColor(0.58, 0.95, 0.49));
            }
        }

        GeneratedKeys = SequenceKeys;
        return SequenceKeys;
    }

    UFUNCTION(Category = "Reload")
    void InitiateReload(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        EquippedGun = GetAngelCharacter(GetOwner()).HolsterComponent.EquippedGun;

        if (!EquippedGun.ReloadStrategy.CanReload()) return;

        if (GetIsReloading())
        {
            CancelReload();
            return;
        }

        GeneratedKeys = GenerateReloadKeys(EquippedGun.ReloadStrategy.ReloadSteps);
        // Always show "Ready/Eject" for the last step
        EquippedGun.ReloadStrategy.ActionTexts.Last() = (EquippedGun.IsReady || EquippedGun.IsJammed) ? FText::FromString("Eject Round") : FText::FromString("Ready");

        BP_OnInitiateReload();
    }

    UFUNCTION(Category = "Reload")
    void CancelReload()
    {
        GeneratedKeys.Empty();
        TimeSinceInput = 0;

        Print("Reload cancelled!", 1.5f, FLinearColor(1.00, 0.45, 0.00));
    }

    UFUNCTION(BlueprintEvent, Category = "Reload", DisplayName = "On Initiate Reload")
    void BP_OnInitiateReload() { }

    UFUNCTION(NotBlueprintCallable)
    void OnKeyPressed(FKey Key)
    {
        if (!LegalKeys.Contains(Key) || GeneratedKeys.Num() == 0) return;

        if (TimeSinceInput < InputDelay)
        {
            Print(f"Input too fast! Wait {InputDelay - TimeSinceInput:.2f} seconds before the next key.", 1.5f, FLinearColor(1.0, 0.0, 0.0));
            return;
        }
        else { TimeSinceInput = 0; }

        int Index = GeneratedKeys.FindIndex(Key);
        EquippedGun.ReloadStrategy.Reload(Index);
        // If last step (Ready/Eject), clear sequence
        if (Index == EquippedGun.ReloadStrategy.ReloadSteps - 1)
        {
            GeneratedKeys.Empty();
        }

        BP_OnKeyPressed(Index);
    }

    UFUNCTION(BlueprintEvent, Category = "Reload", DisplayName = "Key Pressed")
    void BP_OnKeyPressed(int Index) { }
};