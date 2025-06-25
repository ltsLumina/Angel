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
        if (CurrentGun.GetCanShoot())
        {
            CurrentGun.Shoot();
            BP_OnShoot(CurrentGun);
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Shoot"))
    void BP_OnShoot(AManualGun Gun) { }

    void OnGunReloaded(AManualGun Gun)
    {
        Gun.OnReload();

        BP_OnGunReloaded(Gun);
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Gun Reloaded"))
    void BP_OnGunReloaded(AManualGun Gun) { }
};