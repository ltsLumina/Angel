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

// - jamming

    UPROPERTY(Category = "Gun | Magazine", VisibleAnywhere, BlueprintReadOnly, Meta = (Units = "Percent"))
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

    // Whether the gun is ready to fire. This is set to true when the gun is ready to shoot, and false when it has no ammo or is jammed.
    UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly)
    bool IsReady;

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

        if (TimeSinceLastShot < ShootCooldown) return;

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

            if (CurrentAmmo <= 0)
            {
                IsReady = false;
                ReloadStrategy.SetEmptyReloadStep();
                PrintWarning(f"{GunName} is empty! Slide locked back.", 2, FLinearColor(1.0, 0.5, 0.0));
                return; // Prevent jamming if no ammo left
            }

            // Recalculate JamChance before jam check
            JamChance = BaseJamChance + JamRisk;
            // random chance to jam the gun. The JamChance is calculated based on the BaseJamChance and JamRisk (accumulated risk).
            if ((Math::RandRange(0, 100) < JamChance) && CurrentAmmo > 1) // minimum 2 rounds to jam
            {
                IsJammed = true;
                IsReady = false;
                ReloadStrategy.GunState = EGunState::Jammed;
                PrintWarning(f"{GunName} jammed! Clear the jam before firing again.", 2, FLinearColor(1.0, 0.2, 0.2));
            }
        }
        else
        {
            //PrintWarning(f"{GunName} trigger pulled but not ready!", 2, FLinearColor(1.0, 0.2, 0.2));
        }

        BP_Shoot(ReloadStrategy.GunState);
    }

    UFUNCTION(BlueprintEvent, Category = "Gun | Shooting", DisplayName = "Shoot")
    void BP_Shoot(EGunState GunState) { }

    UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Remove Mag")
    void BP_RemoveMag() { }

    UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Insert Mag")
    void BP_InsertMag() { }

    UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Ready")
    void BP_Ready() { }

    UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Eject")
    void BP_Eject() { }

    void Ready()
    {
        if (!IsReady && CurrentAmmo > 0 && !IsJammed)
        {
            IsReady = true;
            ReloadStrategy.GunState = EGunState::Ready;
            BP_Ready();
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

    void Eject()
    {
        if (IsReady)
        {
            IsReady = false;
            ReloadStrategy.GunState = EGunState::NotReady;

            CurrentAmmo--;
            BP_Eject();
            Print(f"{GunName} ejected a round! Magazine: {CurrentAmmo}/{MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));

            if (CurrentAmmo <= 0)
            {
                PrintWarning("No ammo left after ejecting! Gun is empty.", 2, FLinearColor(1.0, 0.5, 0.0));
                ReloadStrategy.SetEmptyReloadStep();
            }
            else
            {
                ReloadStrategy.GunState = EGunState::NotReady;
            }
        }
        else if (IsJammed)
        {
            IsJammed = false;
            ReloadStrategy.GunState = EGunState::Jammed; // Clear jam, gun is not ready

            CurrentAmmo--; // Ejecting a round clears the jam
            BP_Eject();
            Print(f"{GunName} jam cleared! Ejected round.", 2, FLinearColor(0.58, 0.95, 0.49));

            Ready(); // Auto-ready after clearing jam

            if (CurrentAmmo <= 0)
            {
                ReloadStrategy.SetEmptyReloadStep();
            }
        }
        else
        {
            PrintWarning(f"{GunName} is not ready, nothing to eject.", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }
    

    /* Reload is handled by UReloadStrategyBase */
};