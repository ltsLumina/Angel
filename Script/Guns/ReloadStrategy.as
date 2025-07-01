UENUM()
enum EReloadStep
{
    RemoveMagazine = 0,
    InsertMagazine = 1,
    NotReady = 2,
    Ready = 3,
    Eject = 4, // AKA 'Jammed'
};

UCLASS(Abstract, EditInlineNew)
class UReloadStrategyBase : UObject
{
    AManualGun Gun;

    UFUNCTION(BlueprintPure, Category = "Reload")
    bool CanReload() { return true; } // Default implementation, can be overridden

    UPROPERTY(Category = "Reload", VisibleDefaultsOnly, BlueprintGetter = "GetReloadSteps")
    int ReloadSteps = -1;

    // The hotkeys used for reloading, e.g. 1, 2, 3, or R, X, V
    UPROPERTY(Category = "Reload", EditDefaultsOnly)
    TArray<FKey> ReloadKeys;
    default ReloadKeys.Add(EKeys::X);
    default ReloadKeys.Add(EKeys::R);
    default ReloadKeys.Add(EKeys::V);

    UPROPERTY(Category = "Reload | Config", VisibleInstanceOnly)
    EReloadStep CurrentReloadStep = EReloadStep::NotReady;

    UFUNCTION(BlueprintPure, Category = "Reload")
    int GetReloadSteps() const { return ReloadPrompts.Num(); }

    UPROPERTY(Category = "Reload", EditDefaultsOnly)
    TArray<FText> ReloadPrompts;

    void Reload(int ActionIndex) { Gun = GetAngelCharacter(0).HolsterComponent.EquippedGun; }
}

UENUM()
enum EMagazineReloadStep
{
    RemoveMagazine = 0,
    InsertMagazine = 1,
    ReadyOrEject = 2
};

UCLASS(EditInlineNew)
class UMagazineReloadStrategy : UReloadStrategyBase
{
    default ReloadSteps = 3;
    default ReloadPrompts.Add(FText::FromString("Remove Magazine"));
    default ReloadPrompts.Add(FText::FromString("Insert Magazine"));
    default ReloadPrompts.Add(FText::FromString("Ready/Eject"));

    bool CanReload() override
    {
        return true;
    }

    void RemoveMagazine()
    {
        if (!Gun.HasMagazine)
        {
            PrintWarning("Cannot remove magazine! Gun does not have a magazine.", 2, FLinearColor(1.0, 0.5, 0.0));
            CurrentReloadStep = EReloadStep::NotReady;
            return;
        }

        Gun.CurrentAmmo = 0;
        Gun.HasMagazine = false;
        Print(f"{Gun.GunName} magazine removed! Current ammo: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        Gun.IsReady = false; // Removing mag always un-readies
        CurrentReloadStep = EReloadStep::InsertMagazine;
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
            CurrentReloadStep = EReloadStep::InsertMagazine;
            return;
        }

        int32 InsertAmount = (Amount < 0) ? Gun.MaxAmmo : Math::Clamp(Amount, 0, Gun.MaxAmmo);
        Gun.CurrentAmmo = InsertAmount;
        Print(f"{Gun.GunName} magazine inserted! Magazine: {Gun.CurrentAmmo}/{Gun.MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        // After inserting mag, gun is NOT ready. Must perform Ready step next.
        Gun.IsReady = false;
        CurrentReloadStep = EReloadStep::NotReady;
    }

    void ReadyOrEject()
    {
        if (!Gun.HasMagazine)
        {
            PrintWarning("Cannot ready or eject! No magazine inserted.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        if (Gun.IsJammed)
        {
            // Always allow ejecting to clear jam
            Gun.Eject();
            CurrentReloadStep = EReloadStep::NotReady;
        }
        else if (Gun.IsReady)
        {
            // Eject a round (simulate losing it, do not decrement mag)
            Gun.Eject();
            CurrentReloadStep = EReloadStep::Eject;
        }
        else if (!Gun.IsReady && Gun.CurrentAmmo > 0)
        {
            Gun.Ready();
            CurrentReloadStep = EReloadStep::Ready;
        }
        else if (!Gun.IsReady && Gun.CurrentAmmo <= 0)
        {
            PrintWarning("No ammo to ready! Gun is empty.", 2, FLinearColor(1.0, 0.5, 0.0));
            CurrentReloadStep = EReloadStep::RemoveMagazine;
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
                CurrentReloadStep = EReloadStep::NotReady;
                break;
        }
    }
}

UENUM()
enum EShotgunReloadStep
{
    InsertShell = 0, // equivalent to InsertMagazine
    ReadyOrEject = 1 // equivalent to ReadyOrEject
};

UCLASS(EditInlineNew)
class UShotgunReloadStrategy : UReloadStrategyBase
{
    default ReloadSteps = 2; // Insert Shell, ReadyOrEject
    default ReloadPrompts.Add(FText::FromString("Insert Shell"));
    default ReloadPrompts.Add(FText::FromString("Ready"));

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

            if (Gun.CurrentAmmo >= Gun.MaxAmmo)
            {
                PrintWarning("Magazine full!", 2, FLinearColor(1.0, 0.5, 0.0));
                if (CurrentReloadStep == EReloadStep::InsertMagazine)
                {
                    CurrentReloadStep = EReloadStep::NotReady; // After inserting shell, gun is NOT ready
                }
            }
        }
        else
        {
            PrintWarning("Magazine full!", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }

    void ReadyOrEject()
    {
        if (Gun.CurrentAmmo <= 0)
        {
            PrintWarning("Cannot ready or eject! No ammo in the gun.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        if (Gun.IsJammed)
        {
            // Always allow ejecting to clear jam
            Gun.Eject();
            CurrentReloadStep = EReloadStep::NotReady;
        }
        else if (Gun.IsReady)
        {
            // Eject a round
            Gun.Eject();
            CurrentReloadStep = EReloadStep::Eject;
        }
        else if (!Gun.IsReady && Gun.CurrentAmmo > 0)
        {
            Gun.Ready();
            CurrentReloadStep = EReloadStep::Ready;
        }
        else if (!Gun.IsReady && Gun.CurrentAmmo <= 0)
        {
            PrintWarning("No ammo to ready! Gun is empty.", 2, FLinearColor(1.0, 0.5, 0.0));
            CurrentReloadStep = EReloadStep::NotReady;
        }
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
                ReadyOrEject();
                break;
            default:
                PrintError("Invalid reload action index!", 5, FLinearColor(1.0, 0.5, 0.0));
                break;
        }
    }
}