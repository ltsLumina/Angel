UCLASS(Abstract, EditInlineNew)
class UReloadStrategyBase : UObject
{
    AManualGun Gun;

    UFUNCTION(BlueprintPure, Category = "Reload")
    bool CanReload() { return true; } // Default implementation, can be overridden

    UPROPERTY(Category = "Reload", EditDefaultsOnly)
    int ReloadSteps = 3;

    UPROPERTY(Category = "Reload", EditDefaultsOnly)
    TArray<FText> ActionTexts;

    void Reload(int ActionIndex) { Gun = GetAngelCharacter(0).HolsterComponent.EquippedGun; }

    UFUNCTION(BlueprintEvent, Category = "Reload")
    void OnReload() { }
}

UENUM()
enum EMagazineReloadStep
{
    RemoveMagazine = 0,
    InsertMagazine = 1,
    ReadyOrEject = 2 // Renamed for clarity
};

UCLASS(EditInlineNew)
class UMagazineReloadStrategy : UReloadStrategyBase
{
    default ReloadSteps = 3;
    default ActionTexts.Add(FText::FromString("Remove Magazine"));
    default ActionTexts.Add(FText::FromString("Insert Magazine"));
    default ActionTexts.Add(FText::FromString("Ready/Eject"));

    bool CanReload() override
    {
        return true;
    }

    void RemoveMagazine()
    {
        if (!Gun.HasMagazine)
        {
            PrintWarning("Cannot remove magazine! Gun does not have a magazine.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        Gun.CurrentAmmo = 0;
        Gun.HasMagazine = false;
        Print(f"{Gun.GunName} magazine removed! Current ammo: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        Gun.IsReady = false; // Removing mag always un-readies
    }

    void InsertMagazine(int32 Amount = -1)
    {
        if (!Gun.HasMagazine)
        {
            Gun.HasMagazine = true; // Set magazine presence
        }
        else
        {
            PrintWarning("Magazine already inserted! Cannot insert again.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        int32 InsertAmount = (Amount < 0) ? Gun.MaxAmmo : Math::Clamp(Amount, 0, Gun.MaxAmmo);
        Gun.CurrentAmmo = InsertAmount;
        Print(f"{Gun.GunName} magazine inserted! Magazine: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        // After inserting mag, gun is NOT ready. Must perform Ready step next.
        Gun.IsReady = false;
    }

    void ReadyOrEject()
    {
        if (Gun.IsJammed)
        {
            // Always allow ejecting to clear jam
            Gun.Eject();
        }
        else if (Gun.IsReady)
        {
            // Eject a round (simulate losing it, do not decrement mag)
            Gun.Eject();
        }
        else if (!Gun.IsReady && Gun.CurrentAmmo > 0)
        {
            Gun.Ready();
        }
        else if (!Gun.IsReady && Gun.CurrentAmmo <= 0)
        {
            PrintWarning("No ammo to ready! Gun is empty.", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }

    void Reload(int ActionIndex) override
    {
        Super::Reload(ActionIndex);
        switch (ActionIndex)
        {
            case EMagazineReloadStep::RemoveMagazine:
                RemoveMagazine();
                break;
            case EMagazineReloadStep::InsertMagazine:
                InsertMagazine();
                break;
            case EMagazineReloadStep::ReadyOrEject:
                ReadyOrEject();
                break;
            default:
                PrintError("Invalid reload action index!", 5, FLinearColor(1.0, 0.5, 0.0));
                break;
        }
    }

    UFUNCTION(BlueprintOverride, Category = "Reload")
    void OnReload() override 
    { 
        Print(f"{Gun.GunName} reloaded!", 2, FLinearColor(0.58, 0.95, 0.49));
    }
}

UCLASS(EditInlineNew)
class UShotgunReloadStrategy : UReloadStrategyBase
{
    default ReloadSteps = 2; // Insert Shell, Ready
    default ActionTexts.Add(FText::FromString("Insert Shell"));
    default ActionTexts.Add(FText::FromString("Ready"));

    bool CanReload() override
    {
        Gun = GetAngelCharacter(0).HolsterComponent.EquippedGun;
        return Gun.CurrentAmmo < Gun.MaxAmmo || !Gun.IsReady;
    }

    void InsertShell()
    {
        if (Gun.CurrentAmmo < Gun.MaxAmmo)
        {
            Gun.CurrentAmmo++;
            Print(f"{Gun.GunName} shell inserted! Magazine: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
            Gun.IsReady = false;
        }
        else
        {
            PrintWarning("Magazine full!", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }

    void Ready()
    {
        Gun.Ready();
    }

    void Reload(int ActionIndex) override
    {
        Super::Reload(ActionIndex);
        switch (ActionIndex)
        {
            case 0:
                InsertShell();
                break;
            case 1:
                Ready();
                break;
            default:
                PrintError("Invalid reload action index!", 5, FLinearColor(1.0, 0.5, 0.0));
                break;
        }
    }

    UFUNCTION(BlueprintOverride, Category = "Reload")
    void OnReload() override 
    {
        Print(f"{Gun.GunName} reloaded!", 2, FLinearColor(0.58, 0.95, 0.49));
    }
}