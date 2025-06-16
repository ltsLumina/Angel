class UManualReloadComponent : UActorComponent
{
// - config | reload

    UPROPERTY(Category = "Config | Reload", BlueprintGetter = "GetIsReloading", VisibleAnywhere)
    bool IsReloading;

    UFUNCTION(BlueprintPure, Category = "Reload")
    bool GetIsReloading() const { return ExpectedKeys.Num() > 0; }

    UPROPERTY(Category = "Config | Reload", VisibleAnywhere)
    TArray<FKey> IncomingKeys;

    UPROPERTY(Category = "Config | Reload", EditDefaultsOnly)
    TArray<FKey> LegalKeys;

    UPROPERTY(Category = "Config | Reload", VisibleAnywhere)
    TArray<FKey> ExpectedKeys;

    UPROPERTY(Category = "Config | Reload | Debug", EditDefaultsOnly)
    bool UseDebugReloadKeys;
    default UseDebugReloadKeys = true;

// - config | input

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    float TimeSinceInput;

    UPROPERTY(Category = "Config | Input", EditDefaultsOnly)
    float InputDelay;
    default InputDelay = 0.5; // Time in seconds before the next input is considered valid

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
            SequenceKeys.Add(EKeys::One);
            SequenceKeys.Add(EKeys::Two);
            SequenceKeys.Add(EKeys::Three);

            for (int i = 0; i < ReloadSteps; ++i)
            {
                Print(f"Debug Key: {i + 1}", Math::Min(ReloadSteps, 10), FLinearColor(0.58, 0.95, 0.49));
            }
        }
        else
        {
            for (int i = 0; i < ReloadSteps; ++i)
            {
                // Pick a random legal key for each step (can repeat)
                if (LegalKeys.Num() > 0)
                {
                    int idx = Math::RandRange(0, LegalKeys.Num() - 1);
                    SequenceKeys.Add(LegalKeys[idx]);
                    Print(f"Key {i + 1}: {LegalKeys[idx].GetDisplayName()}", Math::Min(ReloadSteps, 10), FLinearColor(0.58, 0.95, 0.49));
                }
            }
        }

        ExpectedKeys = SequenceKeys;
        return SequenceKeys;
    }

    UFUNCTION(Category = "Reload")
    void InitiateReload(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        if (GetIsReloading())
        {
            CancelReload(); // Cancel any ongoing reload if this is called again
            return;
        }

        ExpectedKeys = GenerateReloadKeys(); // Generate a new sequence of keys for the reload
    }

    UFUNCTION(Category = "Reload")
    void CancelReload()
    {
        IncomingKeys.Empty(); // Clear any incoming keys
        ExpectedKeys.Empty(); // Clear the expected keys
        TimeSinceInput = 0; // Reset the input timer

        Print("Reload cancelled!", 1.5f, FLinearColor(1.00, 0.45, 0.00));
    }

    UFUNCTION(BlueprintEvent, Category = "Reload", Meta = (DisplayName = "On Initiate Reload"))
    void BP_OnInitiateReload() { }

    FTimerHandle ReloadTimer;

    UFUNCTION()
    void OnKeyPressed(FKey Key)
    {
        if (!LegalKeys.Contains(Key) || ExpectedKeys.Num() == 0) return; // Ignore keys that are not in the legal keys list

        if (TimeSinceInput < InputDelay)
        {
            // If the time since the last input is less than the delay, ignore this key press.
            Print(f"Input too fast! Wait {InputDelay - TimeSinceInput:.2f} seconds before the next key.", 1.5f, FLinearColor(1.0, 0.0, 0.0));
            return;
        }
        else
        {
            TimeSinceInput = 0; // Reset the timer for the next input
        }

        FKey NextKey = ExpectedKeys[IncomingKeys.Num()];

        if (Key == NextKey)
        {
            IncomingKeys.Add(Key);
            Print(f"Correct key!", 0.5f, FLinearColor(0.44, 0.93, 0.29));
        }
        else if (LegalKeys.Contains(Key))
        {
            // If the key is legal but not the expected one, we can print a message.
            Print(f"Wrong key! Expected: {NextKey.GetDisplayName()}, but got: {Key.GetDisplayName()}", 1, FLinearColor(1.00, 0.45, 0.00));
        }

        if (IncomingKeys == ExpectedKeys)
        {
            ReloadComplete(GetAngelCharacter(GetOwner()).HolsterComponent.EquippedGun);
            IncomingKeys.Empty(); // Reset after successful reload
        }
    }

    // BlueprintCallable if you want to call this function from Blueprints earlier than intended.
    UFUNCTION(BlueprintCallable, Category = "Reload")
    void ReloadComplete(AManualGun Gun)
    {
        ExpectedKeys.Empty(); // Clear the expected keys

        UGunComponent::Get(GetOwner()).OnGunReloaded(Gun);
    }

    UFUNCTION(BlueprintEvent, Category = "Reload", Meta = (DisplayName = "On Reload Complete"))
    void BP_OnReloadComplete(AManualGun Gun) { }
};