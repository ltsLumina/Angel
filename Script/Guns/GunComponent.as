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
        IsADS = true;
    }

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void CancelledADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        IsADS = false;
    }


    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void OnADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        IsADS = true;
    }

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void EndADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        IsADS = false;
    }
};