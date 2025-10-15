class UGunComponent : UActorComponent
{
    UPROPERTY(Category = "Config | Gun", VisibleAnywhere)
    bool IsADS;

    UHolsterComponent HolsterComponent;

    UFUNCTION()
    void Fire(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        if (!IsValid(HolsterComponent))
            HolsterComponent = UHolsterComponent::Get(GetOwner());

        if (HolsterComponent.IsEquipping) return;

        if (HolsterComponent.EquippedGun.Shoot(ElapsedTime, TriggeredTime))
        {
            BP_OnShoot(HolsterComponent.EquippedGun);
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Shoot"))
    void BP_OnShoot(AGunBase Gun) { }

// - ADS

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void StartADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        IsADS = false;
    }

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void CancelledADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        IsADS = false;
    }


    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void TriggeredADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        IsADS = true;
    }

    UFUNCTION(NotBlueprintCallable, Category = "ADS")
    void EndADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        IsADS = false;
    }
};