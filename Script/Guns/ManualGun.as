UCLASS(Abstract)
class AManualGun : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent Root;

    UPROPERTY(DefaultComponent, Category = "Gun | Info")
    USkeletalMeshComponent GunMesh;

// - config

    UPROPERTY(Category = "Gun | Info", EditDefaultsOnly)
    FName GunName;
    default GunName = GetClass().GetName();

    UPROPERTY(Category = "Gun | Info", EditDefaultsOnly)
    bool HasMagazine;
    default HasMagazine = true;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
    int CurrentAmmo;
    default CurrentAmmo = 6;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
    int MaxAmmo;
    default MaxAmmo = 6;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
    bool IsReady;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly, Meta = (Units = "Percent"))
    float JamChance = 5;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
    bool IsJammed;

    UPROPERTY(Category = "Gun | Reload", EditAnywhere, Instanced)
    UReloadStrategyBase ReloadStrategy;

    UFUNCTION(BlueprintPure, Category = "Gun | Reload")
    bool GetIsReloading() const { return GetAngelCharacter(0).ManualReloadComponent.GetIsReloading(); }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        SetOwner(GetAngelCharacter(0));
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        SetActorEnableCollision(false);
        GetAngelCharacter(0).HolsterComponent.EquipGun(this);
    }

    UFUNCTION(BlueprintEvent, Category = "Gun")
    void Shoot()
    {
        if (GetIsReloading()) return;

        if (IsJammed)
        {
            PrintWarning(f"{GunName} is jammed! Clear the jam before firing.", 2, FLinearColor(1.0, 0.2, 0.2));
            return;
        }
        if (IsReady)
        {
            Print(f"{GunName} fired! Magazine: {CurrentAmmo - 1}/{MaxAmmo}", 2, FLinearColor(0.15, 0.32, 0.52));
            UGunComponent::Get(GetAngelCharacter(0)).BP_OnShoot(this);
            CurrentAmmo--;
            // random chance to jam the gun
            if ((Math::RandRange(0, 100) < JamChance) && CurrentAmmo > 0)
            {
                IsJammed = true;
                IsReady = false;
                PrintWarning(f"{GunName} jammed! Clear the jam before firing again.", 2, FLinearColor(1.0, 0.2, 0.2));
            }
            else if (CurrentAmmo == 0)
            {
                IsReady = false;
                PrintWarning(f"{GunName} is empty! Slide locked back.", 2, FLinearColor(1.0, 0.5, 0.0));
            }
            // else: gun stays ready for next shot
        }
        else
        {
            PrintWarning(f"{GunName} trigger pulled but not ready!", 2, FLinearColor(1.0, 0.2, 0.2));
        }
    }

    UFUNCTION(Category = "Gun | Reload")
    void Ready()
    {
        if (!IsReady && CurrentAmmo > 0 && !IsJammed)
        {
            IsReady = true;
            Print(f"{GunName} readied! Magazine: {CurrentAmmo}/{MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        }
        else if (IsJammed)
        {
            PrintWarning(f"{GunName} is jammed! Cannot ready.", 2, FLinearColor(1.0, 0.2, 0.2));
        }
        else if (CurrentAmmo <= 0)
        {
            PrintWarning(f"No ammo to ready! Gun is empty.", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }

    UFUNCTION(Category = "Gun | Reload")
    void Eject()
    {
        if (IsReady)
        {
            IsReady = false;
            CurrentAmmo--;
            if (CurrentAmmo < 0) CurrentAmmo = 0; // Prevent negative ammo
            Print(f"{GunName} ejected a round! Magazine: {CurrentAmmo}/{MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        }
        else if (IsJammed)
        {
            IsJammed = false;
            Print(f"{GunName} jam cleared! Ejected round.", 2, FLinearColor(0.58, 0.95, 0.49));
            Ready(); // After clearing jam, ready the gun
        }
        else
        {
            PrintWarning(f"{GunName} is not ready, nothing to eject.", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }
    /* Reload is handled by UReloadStrategyBase */
};