UCLASS(Abstract)
class AGunBase : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Root;

	UPROPERTY(DefaultComponent, Category = "Gun | Info")
	USkeletalMeshComponent GunMesh;

	// - config

	UPROPERTY(Category = "Gun | Info", EditDefaultsOnly)
	FName GunName;
	default GunName = GetClass().GetName();

	// - damage

    UPROPERTY(Category = "Gun | Damage", EditDefaultsOnly, Instanced)
    UDamageFalloff DamageFalloff;

	// - magazine

	UPROPERTY(Category = "Gun | Reload", Instanced)
	UReloadStrategyBase ReloadStrategy;

	UPROPERTY(Category = "Gun | Magazine", VisibleInstanceOnly)
	bool HasMagazine = true;

	UPROPERTY(Category = "Gun | Magazine", VisibleInstanceOnly, BlueprintReadWrite)
	int CurrentAmmo = 30;
	default CurrentAmmo = MaxAmmo;

	UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
	int MaxAmmo = 30;

	UPROPERTY(Category = "Gun | Magazine", VisibleInstanceOnly)
	int ReserveAmmo = 60;
	default ReserveAmmo = MaxReserveAmmo;

	UPROPERTY(Category = "Gun | Magazine", EditDefaultsOnly)
	int MaxReserveAmmo = 60;
	default MaxReserveAmmo = 60;

	// - shooting

	// Whether the gun is ready to fire. This is set to true when the gun is ready to shoot, and false when it has no ammo or is jammed.
	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = "GetIsReady")
	bool IsReady;

	UFUNCTION(BlueprintPure)
	bool GetIsReady() { return ReloadStrategy.GunState == EGunState::Ready; }

	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = "GetIsFiring")
	bool IsFiring;

	UFUNCTION(BlueprintPure)
	bool GetIsFiring() { return TimeSinceLastShot < ShootCooldown; }

	/**
	 * The fire rate of the gun, in rounds per second.
	 * This is used to calculate the shoot cooldown.
	 */
	UPROPERTY(Category = "Gun | Shooting", EditDefaultsOnly, BlueprintReadOnly, Meta = (ClampMin = "0.1", ClampMax = "30.0", UIMin = "0.1", UIMax = "30.0"))
	float FireRate = 9.75;

	/**
	 * The rounds per minute (RPM) of the gun, calculated from the fire rate.
	 * This is a derived property and is read-only.
	 */
	UPROPERTY(Category = "Gun | Shooting", VisibleAnywhere, BlueprintReadOnly)
	float RPM;
	default RPM = FireRate * MINUTE;

	UPROPERTY(Category = "Gun | Shooting", VisibleAnywhere, BlueprintReadOnly, Meta = (Units = "Seconds"))
	float ShootCooldown = 0.1;
	default ShootCooldown = 1.0 / FireRate;

	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, Meta = (Units = "Seconds"))
	float TimeSinceLastShot = 0;

	// - recoil

	UPROPERTY(Category = "Gun | Recoil", VisibleInstanceOnly, BlueprintReadOnly)
	int RecoilIndex;

	UPROPERTY(Category = "Gun | Recoil", VisibleInstanceOnly, Meta = (Units = "Seconds"))
	bool IsFirstShotAccurate = true;

	// - audio

	UPROPERTY(Category = "Gun | Audio", EditDefaultsOnly)
	USoundCue ShootSound;

	// - end

	const int MINUTE = 60;

	UFUNCTION(BlueprintPure, Category = "Gun | Info")
	bool GetIsADS()
	{
		return UGunComponent::Get(GetAngelCharacter(0)).IsADS;
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if (!OtherActor.IsA(AAngelPlayerCharacter))
			return;

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
		CurrentAmmo = MaxAmmo;

		ShootCooldown = 1.0 / FireRate;
		RPM = FireRate * MINUTE;

		Ready();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TimeSinceLastShot += DeltaSeconds;

		// Assumes player has not fired for a while, reset recoil index
		if (TimeSinceLastShot > ShootCooldown * 2)
			RecoilIndex = 0;

		// first shot accuracy
		IsFirstShotAccurate = TimeSinceLastShot > 3 && RecoilIndex == 0;

		if (RecoilIndex == 0)
			StopHorizontalRecoil();

		BP_Tick(DeltaSeconds);
	}

	UFUNCTION(BlueprintEvent)
	void StopHorizontalRecoil()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(float DeltaSeconds)
	{}

	UFUNCTION(BlueprintEvent, Category = "Gun")
	bool Shoot()
	{
		if (TimeSinceLastShot < ShootCooldown)
			return false;

		if (!HasMagazine || CurrentAmmo <= 0)
		{
			// PrintWarning(f"{GunName} has no magazine! Cannot fire.", 2, FLinearColor(1.0, 0.5, 0.0));
			return false;
		}

		if (GetIsReady())
		{
			// Print(f"{GunName} fired! Magazine: {CurrentAmmo - 1}/{MaxAmmo}", 2, FLinearColor(0.15, 0.32, 0.52));
			CurrentAmmo--;
			RecoilIndex++;

			BP_Shoot(ReloadStrategy.GunState);

			if (CurrentAmmo <= 0)
			{
				ReloadStrategy.GunState = EGunState::NotReady;
				PrintWarning(f"{GunName} is empty!", 2, FLinearColor(1.0, 0.5, 0.0));
			}

			TimeSinceLastShot = 0;
			return true;
		}

		return false;
	}

	void Reload()
	{
		ReloadStrategy.Reload();
	}

	void Ready()
	{
		if (!GetIsReady() && CurrentAmmo > 0)
		{
			ReloadStrategy.GunState = EGunState::Ready;
			BP_Ready();
			Print(f"{GunName} readied! Magazine: {CurrentAmmo}/{MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
		}
		else if (CurrentAmmo <= 0)
		{
			PrintWarning(f"No ammo to ready! Gun is empty.", 2, FLinearColor(1.0, 0.5, 0.0));
		}
	}

	UFUNCTION(BlueprintEvent, Category = "Gun | Shooting", DisplayName = "Shoot")
	void BP_Shoot(EGunState GunState)
	{}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Reload")
	void BP_OnReload()
	{}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Reload", DisplayName = "Ready")
	void BP_Ready()
	{}
};