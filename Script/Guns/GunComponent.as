class UGunComponent : UActorComponent
{
    UPROPERTY(Category = "Config | Gun", VisibleAnywhere)
    AManualGun CurrentGun;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION()
    void OnShoot(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        bool ShootSuccess = false;
        CurrentGun.Shoot(ShootSuccess);

        if (ShootSuccess)
        {
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