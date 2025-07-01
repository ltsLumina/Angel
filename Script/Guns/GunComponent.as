class UGunComponent : UActorComponent
{
    UPROPERTY(Category = "Config | Gun", VisibleAnywhere)
    AManualGun EquippedGun;

    UPROPERTY(Category = "Config | Gun", VisibleAnywhere)
    bool IsADS;

    UFUNCTION()
    void Fire(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        EquippedGun.Shoot();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Shoot"))
    void BP_OnShoot(AManualGun Gun) { }

// - ADS

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void StartADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        Print("Started ADS!", 2.0f, FLinearColor(0.15f, 0.32f, 0.52f));
    }

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void CancelledADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        Print("Cancelled ADS!", 2.0f, FLinearColor(0.15f, 0.32f, 0.52f));
        IsADS = false;
    }


    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void OnADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        Print("ADS action triggered!", 0.1f, FLinearColor(0.15f, 0.32f, 0.52f));
        IsADS = true;

        // zoom in camera
        AAngelPlayerCharacter Character = GetAngelCharacter(GetOwner());
        if (IsValid(Character))
        {
            UCameraComponent::Get(Character).SetFieldOfView(90.0f); // Example FOV for ADS
        }
        else
        {
            PrintWarning("Character or CameraComponent is not valid for ADS!", 2.0f, FLinearColor(1.0f, 0.5f, 0.0f));
        }
    }

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void EndADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        Print("Ended ADS!", 2.0f, FLinearColor(0.15f, 0.32f, 0.52f));
        IsADS = false;

        UCameraComponent::Get(GetAngelCharacter(0)).SetFieldOfView(110.0f); // Example FOV for ADS
    }
};