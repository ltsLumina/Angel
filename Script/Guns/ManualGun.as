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
            //Print(f"{GunName} fired! Magazine: {CurrentAmmo - 1}/{MaxAmmo}", 2, FLinearColor(0.15, 0.32, 0.52));
            TimeSinceLastShot = 0;
            CurrentAmmo--;
            //System::SetTimer(this, n"TryStartRecoil", RecoilKickDuration, false);
            //BP_RecoilStarted();

            //System::SetTimer(this, n"BP_RecoilEnded", RecoilKickDuration, false);
            RecoilIndex++;
            
            UGunComponent::Get(GetAngelCharacter(0)).BP_OnShoot(this);

            if (CurrentAmmo <= 0)
            {
                BP_Shoot(ReloadStrategy.GunState);
                
                IsReady = false;
                ReloadStrategy.GunState = EGunState::NotReady;
                PrintWarning(f"{GunName} is empty!", 2, FLinearColor(1.0, 0.5, 0.0));
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

    UPROPERTY(Category = "Gun | Recoil", EditDefaultsOnly)
    float VerticalRecoil = 0.15;

    UPROPERTY(Category = "Gun | Recoil", EditDefaultsOnly)
    FVector2D HorizontalRecoil = FVector2D(5, -5);

    UPROPERTY(Category = "Gun | Recoil", EditDefaultsOnly)
    TArray<FVector2D> RecoilRange;

    UPROPERTY(Category = "Gun | Recoil", VisibleInstanceOnly)
    int RecoilIndex;

    UFUNCTION(BlueprintPure, Category = "Gun | Magazine")
    bool IsWithinRecoilRange(int RecoilStep)
    {
        if (RecoilStep < 0 || RecoilStep >= RecoilRange.Num()) return false;
        return RecoilIndex >= RecoilRange[RecoilStep].X && RecoilIndex <= RecoilRange[RecoilStep].Y;
    }

    FTimerHandle RecoilSettleTimerHandle;

    /**
     * Applies recoil to the player's view based on predefined recoil patterns.
     * This function checks the current recoil index against defined recoil ranges
     * and applies vertical or horizontal recoil accordingly.
     */
    UFUNCTION(Category = "Gun | Magazine")
    void Recoil()
    {
        if (IsWithinRecoilRange(0))
        {
            //Pitch(VerticalRecoil);
            RecoilVerticalTest();
        }
        else if (IsWithinRecoilRange(1)) // left
        {
            //Pitch(Math::RandRange(0, 0.01));
            //Yaw(HorizontalRecoil.X);
            RecoilSidewaysTest();
        }
        else if (IsWithinRecoilRange(2)) // right
        {
            //Pitch(Math::RandRange(0, 0.01));
            //Yaw(HorizontalRecoil.Y);
            RecoilSidewaysTest();
        }
        else if (IsWithinRecoilRange(3)) // left again
        {
            //Pitch(Math::RandRange(-0.05, 0.05));
            //Yaw(HorizontalRecoil.X);
            RecoilSidewaysTest();
        }
        else
        {
            PrintError("Recoil index out of range!");
        }
    }

    UFUNCTION(BlueprintEvent)
    void RecoilVerticalTest() { }

    UFUNCTION(BlueprintEvent)
    void RecoilSidewaysTest() { }

    /**
     * The duration (in seconds) for which the recoil effect is applied.
     * This value determines how quickly the recoil settles back to the original position.
     * Default is set to 0.05 seconds.
     */
    UPROPERTY(Category = "Gun | Recoil", EditDefaultsOnly)
    float RecoilKickDuration = 0.05;

    UFUNCTION(NotBlueprintCallable)
    void TryStartRecoil()
    {
        if (TimeSinceLastShot > 0.2)
        {
            RecoilSettleTimerHandle = System::SetTimer(this, n"SettleRecoil", 0.01, true, true);
            System::SetTimer(this, n"StopRecoil", RecoilKickDuration, false);
        }
        else
        {
            System::SetTimer(this, n"TryStartRecoil", 0.01, false);
        }
    }

    UFUNCTION(NotBlueprintCallable)
    void StopRecoil()
    {
        System::ClearAndInvalidateTimerHandle(RecoilSettleTimerHandle);
        RecoilIndex = 0;

        BP_RecoilEnded();
    }

    UFUNCTION()
    void SettleRecoil()
    {
        Pitch(-VerticalRecoil);
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Recoil Started")
    void BP_RecoilStarted() { }

    UFUNCTION(BlueprintEvent, DisplayName = "Recoil Ended")
    void BP_RecoilEnded() { }

    /** 
     * Positive Value means look up, Negative means look down
     * @param Value The amount to pitch the view.
    */
    UFUNCTION()
    void Pitch(float Value)
    {
        auto Character = GetAngelCharacter(0);
        Character.AddControllerPitchInput(Value * -1);
    }

    /** 
     * Positive Value means look right, Negative means look left
     * @param Value The amount to yaw the view.
    */
    UFUNCTION()
    void Yaw(float Value)
    {
        auto Character = GetAngelCharacter(0);
        Character.AddControllerYawInput(Value * -1);
    }
};