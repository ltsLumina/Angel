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
    void BeginPlay()
    {
        Ready();
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
        ShootCooldown = UseRPM ? (MINUTE / RPM) : ShootCooldown;

        if (TimeSinceLastShot < ShootCooldown) return;

        if (!HasMagazine)
        {
            //PrintWarning(f"{GunName} has no magazine! Cannot fire.", 2, FLinearColor(1.0, 0.5, 0.0));
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
                ReloadStrategy.GunState = EGunState::NotReady;
                PrintWarning(f"{GunName} is empty! Slide locked back.", 2, FLinearColor(1.0, 0.5, 0.0));
                return; // Prevent jamming if no ammo left
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

    UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Reload")
    void BP_OnReload() { }

    UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Ready")
    void BP_Ready() { }

    void Ready()
    {
        if (!IsReady && CurrentAmmo > 0)
        {
            IsReady = true;
            ReloadStrategy.GunState = EGunState::Ready;
            BP_Ready();
            Print(f"{GunName} readied! Magazine: {CurrentAmmo}/{MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
        }
        else if (CurrentAmmo <= 0)
        {
            PrintWarning(f"No ammo to ready! Gun is empty.", 2, FLinearColor(1.0, 0.5, 0.0));
        }
    }


    /* Reload is handled by UReloadStrategyBase */
};