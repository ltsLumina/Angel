UENUM()
enum EGunState
{
    RemoveMagazine = 0,
    InsertMagazine = 1,
    NotReady = 2,
    Ready = 3,
};

UCLASS(Abstract, EditInlineNew)
class UReloadStrategyBase : UObject
{
    UGunComponent GunComponent;

    UFUNCTION(BlueprintPure, Category = "Reload")
    bool CanReload() { return true; } // Default implementation, can be overridden

    UPROPERTY(Category = "Reload", VisibleInstanceOnly)
    EGunState GunState = EGunState::NotReady;

    // Setup gun stuff, like getting a reference to the gun.
    void Reload() { GunComponent = UGunComponent::Get(Game::Controller); }
}

UCLASS(EditInlineNew)
class UMagazineReloadStrategy : UReloadStrategyBase
{
    void Reload() override
    {
        Super::Reload();

        if (!CanReload()) return;
        GunComponent.HolsterComponent.EquippedGun.BP_OnReload();

        RemoveMagazine();
    }

    bool CanReload() override
    {
        return GunComponent.CurrentAmmo < GunComponent.WeaponDefinition.MaxAmmo && GunComponent.HasMagazine && GunComponent.ReserveAmmo > 0;
    }

    UFUNCTION()
    void RemoveMagazine()
    {
        if (!GunComponent.HasMagazine)
        {
            PrintWarning("Cannot remove magazine! Gun does not have a magazine.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        GunComponent.HasMagazine = false;

        Print(f"{GunComponent.WeaponDefinition.WeaponName}'s magazine removed! Current ammo: {GunComponent.CurrentAmmo}/{GunComponent.WeaponDefinition.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        GunState = EGunState::InsertMagazine;
    }

    UFUNCTION() // Called in Blueprint when the animation has completed.
    void InsertMagazine(int Amount)
    {
        if (!GunComponent.HasMagazine)
        {
            GunComponent.HasMagazine = true;
        }
        else
        {
            PrintWarning("Magazine already inserted! Cannot insert again.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        int InsertAmount = Math::Clamp(Math::Min(Amount, GunComponent.ReserveAmmo), 0, GunComponent.WeaponDefinition.MaxAmmo - GunComponent.CurrentAmmo);
        GunComponent.CurrentAmmo += InsertAmount;
        GunComponent.ReserveAmmo = Math::Max(GunComponent.ReserveAmmo - InsertAmount, 0);
        Print(f"{GunComponent.WeaponDefinition.WeaponName} magazine inserted! Magazine: {GunComponent.CurrentAmmo}/{GunComponent.WeaponDefinition.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));

        // After inserting mag, gun is NOT ready. Ready state is set by animation completion in Blueprint event graph.
        GunState = EGunState::NotReady;
    }

    UFUNCTION() // Called in Blueprint when the animation has completed.
    void Ready() 
    {
        GunComponent.Ready();
    }
}

UCLASS(EditInlineNew)
class UShotgunReloadStrategy : UReloadStrategyBase
{
    bool CanReload() override
    {
        GunComponent = UGunComponent::Get(Game::Player);
        return GunComponent.CurrentAmmo < GunComponent.WeaponDefinition.MaxAmmo || !GunComponent.IsReady();
    }

    void InsertShell()
    {
        if (GunComponent.CurrentAmmo < GunComponent.WeaponDefinition.MaxAmmo)
        {
            GunComponent.CurrentAmmo++;
            Print(f"{GunComponent.WeaponDefinition.WeaponName} shell inserted! Magazine: {GunComponent.CurrentAmmo}/{GunComponent.WeaponDefinition.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));

            if (GunComponent.CurrentAmmo >= GunComponent.WeaponDefinition.MaxAmmo)
            {
                PrintWarning("Magazine full!", 2, FLinearColor(1.0, 0.5, 0.0));
                if (GunState == EGunState::InsertMagazine)
                {
                    GunState = EGunState::NotReady; // After inserting shell, gun is NOT ready
                }
            }
        }
        else
        {
            PrintWarning("Magazine full!", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }

    void Reload() override
    {
        Super::Reload();
        InsertShell();
    }
}