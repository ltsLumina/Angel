//event void FOnInitiateReload(AManualGun Gun);
//event void FOnReloadComplete(AManualGun Gun);

class UManualReloadComponent : UActorComponent
{
// - config | reload

    // Modifies the legal keys for the reload sequence to only use keys: 1, 2, and 3.
    UPROPERTY(Category = "Reload | Debug", EditDefaultsOnly)
    bool UseDebugReloadKeys;
    default UseDebugReloadKeys = true;

// - config | input

    UPROPERTY(Category = "Reload | Input", VisibleInstanceOnly)
    float TimeSinceInput;

    UPROPERTY(Category = "Reload | Input", EditDefaultsOnly)
    float InputDelay;
    default InputDelay = 0.5; // Time in seconds before the next input is considered valid

// - events

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BP_BeginPlay();
    }


    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        TimeSinceInput += DeltaSeconds;
        
        BP_Tick(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Tick"))
    void BP_Tick(float DeltaSeconds) { }

    UFUNCTION(NotBlueprintCallable)
    void Reload(FKey Key)
    {
        // NOTE: This is done on each key press in-case the reload keys change dynamically, in the future.
        auto EquippedGun = GetAngelCharacter(0).HolsterComponent.EquippedGun;

        if (TimeSinceInput < InputDelay)
        {
            Print(f"Input too fast! Wait {InputDelay - TimeSinceInput:.2f} seconds before the next key.", 1.5f, FLinearColor(1.0, 0.0, 0.0));
            return;
        }
        else { TimeSinceInput = 0; }

        EquippedGun.ReloadStrategy.Reload();

        BP_OnReload();
    }

    UFUNCTION(BlueprintEvent, Category = "Reload", DisplayName = "Reload Initiated")
    void BP_OnReload() { }
};