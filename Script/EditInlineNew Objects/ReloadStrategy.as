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
    AGunBase Gun;

    UFUNCTION(BlueprintPure, Category = "Reload")
    bool CanReload() { return true; } // Default implementation, can be overridden

    UPROPERTY(Category = "Reload", VisibleInstanceOnly)
    EGunState GunState = EGunState::NotReady;

    // Setup gun stuff, like getting a reference to the gun.
    void Reload() { Gun = GetAngelCharacter(0).HolsterComponent.EquippedGun; }
}

UCLASS(EditInlineNew)
class UMagazineReloadStrategy : UReloadStrategyBase
{
    void Reload() override
    {
        Super::Reload();

        if (!CanReload()) return;
        Gun.BP_OnReload();

        RemoveMagazine();
    }

    bool CanReload() override
    {
        return Gun.CurrentAmmo < Gun.MaxAmmo && Gun.HasMagazine && Gun.ReserveAmmo > 0;
    }

    UFUNCTION()
    void RemoveMagazine()
    {
        if (!Gun.HasMagazine)
        {
            PrintWarning("Cannot remove magazine! Gun does not have a magazine.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        Gun.HasMagazine = false;

        Print(f"{Gun.GunName}'s magazine removed! Current ammo: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        GunState = EGunState::InsertMagazine;
    }

    UFUNCTION() // Called in Blueprint when the animation has completed.
    void InsertMagazine(int Amount)
    {
        if (!Gun.HasMagazine)
        {
            Gun.HasMagazine = true;
        }
        else
        {
            PrintWarning("Magazine already inserted! Cannot insert again.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        int InsertAmount = Math::Clamp(Math::Min(Amount, Gun.ReserveAmmo), 0, Gun.MaxAmmo - Gun.CurrentAmmo);
        Gun.CurrentAmmo += InsertAmount;
        Gun.ReserveAmmo = Math::Max(Gun.ReserveAmmo - InsertAmount, 0);
        Print(f"{Gun.GunName} magazine inserted! Magazine: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));

        // After inserting mag, gun is NOT ready. Ready state is set by animation completion in Blueprint event graph.
        GunState = EGunState::NotReady;
    }

    UFUNCTION() // Called in Blueprint when the animation has completed.
    void Ready() 
    {
        Gun.Ready();
    }
}

UCLASS(EditInlineNew)
class UShotgunReloadStrategy : UReloadStrategyBase
{
    bool CanReload() override
    {
        Gun = GetAngelCharacter(0).HolsterComponent.EquippedGun;
        return Gun.CurrentAmmo < Gun.MaxAmmo || !Gun.GetIsReady();
    }

    void InsertShell()
    {
        if (Gun.CurrentAmmo < Gun.MaxAmmo)
        {
            Gun.CurrentAmmo++;
            Print(f"{Gun.GunName} shell inserted! Magazine: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));

            if (Gun.CurrentAmmo >= Gun.MaxAmmo)
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