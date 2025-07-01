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

// - magazine

    UPROPERTY(Category = "Gun | Reload", EditAnywhere, Instanced)
    UReloadStrategyBase ReloadStrategy;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
    bool HasMagazine;
    default HasMagazine = true;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
    int CurrentAmmo;
    default CurrentAmmo = 6;

    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
    int MaxAmmo;
    default MaxAmmo = 6;

    // Whether the gun is ready to fire. This is set to true when the gun is ready to shoot, and false when it has no ammo or is jammed.
    UPROPERTY(Category = "Gun | Magazine", VisibleInstanceOnly, BlueprintReadOnly)
    bool IsReady;

// - jamming

    UPROPERTY(Category = "Gun | Magazine", VisibleDefaultsOnly, BlueprintReadOnly, Meta = (Units = "Percent"))
    float JamChance = 0;

    // Base chance of jamming the gun, used to calculate the risk of jamming.
    UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly, Meta = (Units = "Percent"))
    float BaseJamChance = 1;

    // Accumulated risk of jamming. This increases with each shot fired and resets after a cooldown period.
    UPROPERTY(Category = "Gun | Magazine", VisibleInstanceOnly, BlueprintReadOnly, Meta = (Units = "Percent"))
    float JamRisk = 0;

    UPROPERTY(Category = "Gun | Magazine", VisibleInstanceOnly, BlueprintReadOnly)
    bool IsJammed;

// - shooting

    // Whether the gun is in full-auto mode. If true, the gun will fire continuously while the trigger is held.
    UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly)
    bool IsAutomatic = false;

    // Whether the gun uses RPM (Rounds Per Minute) for firing rate. If true, the gun will fire at a rate based on RPM.
    // If false, the gun will fire based on the ShootCooldown time.
    UPROPERTY(Category = "Gun | Shooting", EditDefaultsOnly, BlueprintReadOnly)
    bool UseRPM = false;

    UPROPERTY(Category = "Gun | Shooting", EditDefaultsOnly, Meta = (Units = "Seconds", EditCondition = "!UseRPM", EditConditionHides))
    float ShootCooldown = 0.5;

    UPROPERTY(Category = "Gun | Shooting", EditDefaultsOnly, BlueprintReadOnly, Meta = (EditCondition = "UseRPM", EditConditionHides))
    float RPM = 600;

    UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, Meta = (Units = "Seconds"))
    float TimeSinceLastShot = 0;

// - end

    const int MINUTE = 60;

    UFUNCTION(BlueprintPure, Category = "Gun | Info")
    bool GetIsADS() const { return UGunComponent::Get(GetAngelCharacter(0)).IsADS; }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        SetOwner(GetOwner());
        IsReady = false;
        IsJammed = false;
        JamRisk = 0;
        CurrentAmmo = MaxAmmo; // Reset ammo to max on construction
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        if (!OtherActor.IsA(AAngelPlayerCharacter)) return;

        if (GetAngelCharacter(0).HolsterComponent.Guns.Num() >= GetAngelCharacter(0).HolsterComponent.MaxGuns)
        {
            PrintWarning("Holster is full! Cannot equip more guns.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }
        
        SetActorEnableCollision(false);
        GetAngelCharacter(0).HolsterComponent.EquipGun(this);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        TimeSinceLastShot += DeltaSeconds;

        BP_Tick(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Tick")
    void BP_Tick(float DeltaSeconds) { }

    UFUNCTION(BlueprintEvent, Category = "Gun")
    void Shoot()
    {
        JamChance = BaseJamChance + JamRisk;
        ShootCooldown = UseRPM ? (MINUTE / RPM) : ShootCooldown;

        if (TimeSinceLastShot < ShootCooldown)
        {
            //PrintWarning(f"{GunName} is cooling down! Wait {ShootCooldown - TimeSinceLastShot:.2f} seconds before firing again.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        if (!HasMagazine)
        {
            PrintWarning(f"{GunName} has no magazine! Cannot fire.", 2, FLinearColor(1.0, 0.5, 0.0));
            return;
        }

        if (IsJammed)
        {
            JamRisk = 0;
            return;
        }
        if (IsReady)
        {
            Print(f"{GunName} fired! Magazine: {CurrentAmmo - 1}/{MaxAmmo}", 2, FLinearColor(0.15, 0.32, 0.52));
            TimeSinceLastShot = 0;
            CurrentAmmo--;
            UGunComponent::Get(GetAngelCharacter(0)).BP_OnShoot(this);

            if (CurrentAmmo == 0)
            {
                IsReady = false;
                PrintWarning(f"{GunName} is empty! Slide locked back.", 2, FLinearColor(1.0, 0.5, 0.0));

                // Only MagazineReloadStrategy handles removing the magazine
                if (ReloadStrategy.IsA(UMagazineReloadStrategy)) 
                { 
                    ReloadStrategy.CurrentReloadStep = EReloadStep::RemoveMagazine; 
                }
                else if (ReloadStrategy.IsA(UShotgunReloadStrategy))
                {
                    ReloadStrategy.CurrentReloadStep = EReloadStep::InsertMagazine;
                }

                return; // Prevent jamming if no ammo left
            }

            // Recalculate JamChance before jam check
            JamChance = BaseJamChance + JamRisk;
            // random chance to jam the gun. The JamChance is calculated based on the BaseJamChance and JamRisk (accumulated risk).
            if ((Math::RandRange(0, 100) < JamChance) && CurrentAmmo > 1) // minimum 2 rounds to jam
            {
                IsJammed = true;
                IsReady = false;
                ReloadStrategy.CurrentReloadStep = EReloadStep::Eject;
                PrintWarning(f"{GunName} jammed! Clear the jam before firing again.", 2, FLinearColor(1.0, 0.2, 0.2));
            }
        }
        else
        {
            //PrintWarning(f"{GunName} trigger pulled but not ready!", 2, FLinearColor(1.0, 0.2, 0.2));
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
            CurrentAmmo--; // Ejecting a round clears the jam
            Print(f"{GunName} jam cleared! Ejected round.", 2, FLinearColor(0.58, 0.95, 0.49));
            //Ready(); // After clearing jam, ready the gun

            if (CurrentAmmo <= 0)
            {
                if (ReloadStrategy.IsA(UMagazineReloadStrategy)) 
                { 
                    ReloadStrategy.CurrentReloadStep = EReloadStep::RemoveMagazine; 
                }
                else if (ReloadStrategy.IsA(UShotgunReloadStrategy))
                {
                    ReloadStrategy.CurrentReloadStep = EReloadStep::InsertMagazine;
                }
            }
        }
        else
        {
            PrintWarning(f"{GunName} is not ready, nothing to eject.", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }
    /* Reload is handled by UReloadStrategyBase */
};