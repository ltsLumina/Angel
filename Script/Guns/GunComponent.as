class UGunComponent : UActorComponent
{
    UPROPERTY(Category = "Config | Gun", VisibleAnywhere)
    AManualGun CurrentGun;

    UPROPERTY(Category = "Config | Gun", VisibleDefaultsOnly)
    UManualReloadComponent ReloadComponent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ReloadComponent = UManualReloadComponent::Get(GetOwner());

        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION()
    void OnShoot(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        if (CurrentGun.IsReady && !CurrentGun.GetIsReloading())
        {
            CurrentGun.Shoot();
        }
        else
        {
            PrintWarning("Cannot shoot! Gun is not ready or is reloading.", 2.0f, FLinearColor(1.0f, 0.5f, 0.0f));
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Shoot"))
    void BP_OnShoot(AManualGun Gun) { }
};