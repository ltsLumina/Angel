class UManualReloadComponent : UActorComponent
{
// - config | reload

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
    TArray<FKey> GenerateReloadKeys()
    {
        // Shuffle and pick 3 unique keys
        LegalKeys.Shuffle();
        TArray<FKey> SequenceKeys;
        for (int i = 0; i < 3 && i < LegalKeys.Num(); ++i)
        {
            SequenceKeys.Add(LegalKeys[i]);
            if (!UseDebugReloadKeys) // Blueprint overrides this print.
            {
                Print(f"Key {i + 1}: {LegalKeys[i].GetDisplayName()}", 5, FLinearColor(0.58, 0.95, 0.49));   
            }
            else
            {
                SequenceKeys.Empty();
                SequenceKeys.Add(EKeys::One);
                SequenceKeys.Add(EKeys::Two);
                SequenceKeys.Add(EKeys::Three);
            }
        }
        return SequenceKeys;
    }

    FTimerHandle ReloadTimer;

    UFUNCTION()
    void OnKeyPressed(FKey Key)
    {
        if (TimeSinceInput < InputDelay)
        {
            // If the time since the last input is less than the delay, ignore this key press.
            return;
        }
        else
        {
            TimeSinceInput = 0; // Reset the timer for the next input
        }

        // if the reload is already running, ignore the call
        if (System::IsTimerActiveHandle(ReloadTimer))
        {
            Print("Reload already in progress!", System::GetTimerRemainingTimeHandle(ReloadTimer), FLinearColor(1.0, 0.0, 0.0));
            return;
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
            //Print(f"Wrong key! Expected: {NextKey.GetDisplayName()}, but got: {Key.GetDisplayName()}", 1.5, FLinearColor(1.0, 0.0, 0.0));
        }

        if (IncomingKeys == ExpectedKeys)
        {
            StartReload(GetAngelCharacter(GetOwner()).HolsterComponent.EquippedGun);
            IncomingKeys.Empty(); // Reset after successful reload
        }
    }

    // BlueprintCallable if you want to call this function from Blueprints earlier than intended.
    UFUNCTION(BlueprintCallable, Category = "Reload")
    void StartReload(AManualGun Gun)
    {
        // Create a new sequence of keys for the next reload
        ExpectedKeys = GenerateReloadKeys();

        OnReload(Gun);
    }

    UFUNCTION(NotBlueprintCallable, Category = "Reload")
    void OnReload(AManualGun Gun)
    {
       Gun.OnReload();
    }
};