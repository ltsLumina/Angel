UCLASS(Abstract)
class AGunBase : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Root;

	UPROPERTY(DefaultComponent, Category = "Gun | Info")
	USkeletalMeshComponent GunMesh;

	// - info

	UPROPERTY(Category = "Gun | Info", EditDefaultsOnly)
	FName GunName;
	default GunName = GetClass().GetName();

	UPROPERTY(Category = "Gun | Info", EditDefaultsOnly, BlueprintReadOnly, Meta = (ClampMin = "0", UIMin = "0", ClampMax = "5000", UIMax = "5000"))
	int Price = 2900;

	// - movement
	UPROPERTY(Category = "Gun | Movement", EditDefaultsOnly, Meta = (ClampMin = "0.1", UIMin = "0.1", ClampMax = "6.75", UIMax = "6.75", Units = "m/s"))
	float RunSpeed = 5.4;

	UPROPERTY(Category = "Gun | Movement", VisibleAnywhere, BlueprintGetter = "GetWalkSpeed", Meta = (Units = "m/s"))
	float WalkSpeed;
	default WalkSpeed = RunSpeed * WalkSpeedRatio;

	UPROPERTY(Category = "Gun | Movement", VisibleAnywhere, BlueprintGetter = "GetCrouchSpeed", Meta = (Units = "m/s"))
	float CrouchSpeed;
	default CrouchSpeed = RunSpeed * CrouchSpeedRatio;

	UPROPERTY(Category = "Gun | Movement", EditDefaultsOnly, Meta = (ClampMin = "0.1", UIMin = "0.1", ClampMax = "1", UIMax = "1"))
	float WalkSpeedRatio = 0.80;

	UPROPERTY(Category = "Gun | Movement", EditDefaultsOnly, Meta = (ClampMin = "0.1", UIMin = "0.1", ClampMax = "1", UIMax = "1"))
	float CrouchSpeedRatio = 0.40;

	// - movement helpers

	UFUNCTION(BlueprintPure, Category = "Gun | Movement")
	float GetMovementSpeed(EAngelMovementState State)
	{
		switch (State)
		{
			case EAngelMovementState::Still:
			case EAngelMovementState::Run:
				return RunSpeed * (IsAltMode ? AltMoveSpeedRatio : 1.0f);

			case EAngelMovementState::Walk:
				return GetWalkSpeed() * (IsAltMode ? AltMoveSpeedRatio : 1.0f);

			case EAngelMovementState::Crouch:
			case EAngelMovementState::CrouchWalk:
				return GetCrouchSpeed() * (IsAltMode ? AltMoveSpeedRatio : 1.0f);

			default:
				return RunSpeed;
		}
	}

	UFUNCTION(BlueprintPure, Category = "Gun | Movement")
	float GetWalkSpeed()
	{
		return RunSpeed * WalkSpeedRatio;
	}

	UFUNCTION(BlueprintPure, Category = "Gun | Movement")
	float GetCrouchSpeed()
	{
		return RunSpeed * CrouchSpeedRatio;
	}

	// - equip
	UPROPERTY(Category = "Gun | Equip", EditDefaultsOnly, Meta = (Units = "Seconds"))
	TMap<EEquipSpeed, float> EquipTimes;
	default EquipTimes.Add(EEquipSpeed::Normal, 0.6);
	default EquipTimes.Add(EEquipSpeed::Fast, 0.4);
	default EquipTimes.Add(EEquipSpeed::Instant, 0.2);

	// - equip helpers

	UFUNCTION(BlueprintPure, Category = "Gun | Equip")
	float GetEquipTime(EEquipSpeed Speed)
	{
		return EquipTimes[Speed];
	}

	// - damage

	UPROPERTY(Category = "Gun | Damage", EditDefaultsOnly, Instanced)
	UDamageFalloff DamageFalloff;

	// - shooting

	UPROPERTY(Category = "Gun | Shooting", EditDefaultsOnly)
	EFireMode FireMode = EFireMode::Auto;

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

	/**
	 * The cooldown time between shots, in seconds.
	 * This is calculated as the inverse of the fire rate.
	 */
	UPROPERTY(Category = "Gun | Shooting", VisibleAnywhere, BlueprintReadOnly, Meta = (Units = "Seconds"))
	float ShootCooldown = 0.1;
	default ShootCooldown = 1.0 / FireRate;

	/**
	 * The time elapsed since the last shot was fired, in seconds.
	 */
	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, Meta = (Units = "Seconds"))
	float TimeSinceLastShot = 0;

	// - shooting helpers

	// Whether the gun is ready to fire. This is set to true when the gun is ready to shoot, and false when it has no ammo or is jammed.
	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = "GetIsReady")
	protected bool IsReady;

	UFUNCTION(Category = "Gun | Shooting", BlueprintPure)
	bool GetIsReady()
	{
		return ReloadStrategy.GunState == EGunState::Ready;
	}

	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = "GetIsFiring")
	protected bool IsFiring;

	UFUNCTION(Category = "Gun | Shooting", BlueprintPure)
	bool GetIsFiring()
	{
		return TimeSinceLastShot < ShootCooldown;
	}

	/**
	 * Whether the first shot after a pause is perfectly accurate (no recoil).
	 */
	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = "GetIsFirstShotAccurate")
	protected bool IsFirstShotAccurate;

	UFUNCTION(Category = "Gun | Shooting", BlueprintPure)
	bool GetIsFirstShotAccurate()
	{
		return TimeSinceLastShot > 1.0 && RecoilIndex == 0;
	}

	// - Accuracy

	/**
	 * The number of bullets that are guaranteed to be perfectly accurate (no spread).
	 */
	UPROPERTY(Category = "Gun | Accuracy | Bullets", EditDefaultsOnly, Meta = (ClampMin = "0", UIMin = "0", ClampMax = "30", UIMax = "30"))
	int ProtectedBullets = 3;

	/**
	 * The number of bullets after which the spread reaches its maximum value.
	 */
	UPROPERTY(Category = "Gun | Accuracy | Bullets", VisibleInstanceOnly, BlueprintReadOnly, Meta = (ClampMin = "1", UIMin = "1", ClampMax = "30", UIMax = "30"))
	int MaxSpreadBullet = 9;

	UPROPERTY(Category = "Gun | Accuracy | 1st Shot Spread", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float StandingSpread = 0.25f;
	UPROPERTY(Category = "Gun | Accuracy | 1st Shot Spread", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float CrouchSpread = 0.21f;

	UPROPERTY(Category = "Gun | Accuracy | Max Spread", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float StandingMaxSpread = 1.0f;
	UPROPERTY(Category = "Gun | Accuracy | Max Spread", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float CrouchMaxSpread = 0.85f;

	UPROPERTY(Category = "Gun | Accuracy | Penalties", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float AirbornePenalty = 10;
	UPROPERTY(Category = "Gun | Accuracy | Penalties", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float RunPenalty = 6;
	UPROPERTY(Category = "Gun | Accuracy | Penalties", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float WalkPenalty = 3;
	UPROPERTY(Category = "Gun | Accuracy | Penalties", EditDefaultsOnly, Meta = (Units = "Degrees"))
	float CrouchPenalty = 1.5f;

	// - accuracy helpers

	float Increment;

	UFUNCTION(BlueprintPure, Category = "Gun | Accuracy")
	float GetSpread()
	{
		EAngelMovementState State = GetAngelCharacter(0).MovementState;
		float Spread;

		switch (State)
		{
			case EAngelMovementState::Still:
				Spread = StandingSpread;
				break;
			case EAngelMovementState::Airborne:
				Spread = AirbornePenalty;
				break;
			case EAngelMovementState::Crouch:
				Spread = CrouchSpread;
				break;
			case EAngelMovementState::Run:
				Spread = RunPenalty;
				break;
			case EAngelMovementState::Walk:
				Spread = WalkPenalty;
				break;
			case EAngelMovementState::CrouchWalk:
				Spread = CrouchPenalty;
				break;
			default:
				Spread = StandingSpread;
				break;
		}

		if (RecoilIndex > ProtectedBullets)
		{
			float Alpha = Math::Clamp(float(RecoilIndex - ProtectedBullets) / float(MaxSpreadBullet - ProtectedBullets), 0.0f, 1.0f);
			float MaxSpread = (State == EAngelMovementState::Crouch || State == EAngelMovementState::CrouchWalk) ? CrouchMaxSpread : StandingMaxSpread;
			Increment = Math::Lerp(0.0f, MaxSpread - Spread, Alpha);
		}
		else // within protected bullets
		{
			Increment = 0;
		}

		Spread += Increment;

		Print(f"Spread: {Spread} degrees", 1, FLinearColor(0.5, 0.5, 1.0));
		return Spread;
	}

	UFUNCTION(BlueprintPure, Category = "Gun | Accuracy")
	bool IsBulletProtected()
	{
		return RecoilIndex <= ProtectedBullets;
	}

	// - recoil

	UPROPERTY(Category = "Gun | Recoil", EditDefaultsOnly, Meta = (ClampMin = "1.0", UIMin = "1.0", ClampMax = "3.0", UIMax = "3.0"))
	float VerticalRecoilRunningMultiplier = 2.0f;

	/**
	 * The current index in the recoil pattern. This increments with each shot fired.
	 * It is used to determine the recoil offset applied to the gun.
	 */
	UPROPERTY(Category = "Gun | Recoil", VisibleInstanceOnly, BlueprintReadOnly)
	int RecoilIndex;

	// - alt fire

	bool IsAltMode = false;

	float Zoom = 1.25;

	/**
	 * The fire rate when using alternate fire mode, in rounds per second.
	 */
	float AltFireRate;
	default AltFireRate = FireRate * 0.9f;

	float AltMoveSpeedRatio = 0.76f;

	// - reload

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

	// - aiming


	UPROPERTY(Category = "Gun | Scope", VisibleInstanceOnly, BlueprintGetter = "GetIsScoped")
	bool IsScoped;

	UFUNCTION(BlueprintPure, Category = "Gun | Info", NotBlueprintCallable)
	bool GetIsScoped()
	{
		return UGunComponent::Get(GetAngelCharacter(0)).IsADS;
	}

	// - audio

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly)
	USoundCue ShootSound;

	UPROPERTY(Category = "Gun | Audio | Headshots", EditDefaultsOnly)
	USoundWave HeadshotSound;

	UPROPERTY(Category = "Gun | Audio | Headshots", EditDefaultsOnly)
	USoundWave HeadshotWithArmorSound;

	UPROPERTY(Category = "Gun | Audio | Headshots", EditDefaultsOnly)
	USoundWave HeadshotBrokeArmorSound;

	UPROPERTY(Category = "Gun | Audio | Body", EditDefaultsOnly)
	USoundCue BodyshotSound;

	UPROPERTY(Category = "Gun | Audio | Ground", EditDefaultsOnly)
	USoundWave GroundHitSound;

	UPROPERTY(Category = "Gun | Audio | Multikill", EditDefaultsOnly)
	TArray<USoundWave> MultikillSounds;

	UPROPERTY(Category = "Gun | Audio | Multikill", EditDefaultsOnly)
	USoundWave MultikillAceSound;

	UPROPERTY(Category = "Gun | Audio | Attenuation", EditDefaultsOnly)
	USoundAttenuation DefaultAttenuation;

	// - visual
	UPROPERTY(Category = "Gun | Visual | Decals", EditDefaultsOnly)
	UMaterialInterface BulletHitDecal;

	UPROPERTY(Category = "Gun | Visual | Decals", EditDefaultsOnly)
	UMaterialInterface BulletPenetrationDecal;

	// - end

	const int MINUTE = 60;

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

	UFUNCTION(BlueprintPure, Category = "Gun | Accuracy", Meta = (AdvancedDisplay = "ConeWidth, ConeHeight, ErrorAngle, IsAccurate"))
	FVector ApplySpread(FVector AimDirection, float SpreadDeg, FBulletSpreadData&out OutSpreadData = FBulletSpreadData())
	{
		float SpreadRad = Math::DegreesToRadians(SpreadDeg);

		// Random yaw angle around the aim direction
		float Yaw = Math::RandRange(0.0f, PI * 2.0f);

		// Random radius (sqrt for even distribution)
		float Radius = Math::Sqrt(Math::RandRange(0.0f, 1.0f)) * Math::Tan(SpreadRad);

		float OffsetX = Math::Cos(Yaw) * Radius;
		float OffsetY = Math::Sin(Yaw) * Radius;

		// Build an orthonormal basis around AimDirection
		FVector Right = FVector::UpVector.CrossProduct(AimDirection).GetSafeNormal();
		FVector Up = AimDirection.CrossProduct(Right).GetSafeNormal();

		// Apply spread offset
		FVector FinalDir = (AimDirection + Right * OffsetX + Up * OffsetY).GetSafeNormal();

		OutSpreadData.ConeWidth = Math::Atan2(Math::Abs(OffsetX), 1.0f);
		OutSpreadData.ConeHeight = Math::Atan2(Math::Abs(OffsetY), 1.0f);
		OutSpreadData.ErrorAngle = Math::RadiansToDegrees(Math::Acos(FinalDir.DotProduct(AimDirection)));
		OutSpreadData.IsAccurate = SpreadData.ErrorAngle <= 0.01f;

		return FinalDir;
	}

	FVector TraceStart;
	FVector TraceEnd;

	// for debug only.
	EDrawDebugTrace DebugTrace = EDrawDebugTrace::None;

	FVector GetTargetPoint(float MaxDistance = 10000.0f)
	{
		UCameraComponent Camera = UCameraComponent::Get(GetAngelCharacter(GetOwner()));
		FVector CameraLocation = Camera.WorldLocation;
		FVector CameraForward = Camera.GetForwardVector();

		TraceStart = CameraLocation;
		TraceEnd = CameraLocation + CameraForward * MaxDistance;

		FHitResult Hit;
		System::LineTraceSingle(TraceStart, TraceEnd, ETraceTypeQuery::TraceTypeQuery3, false, TArray<AActor>(), DebugTrace, Hit, true, FLinearColor::Red, FLinearColor::Green, 2.0f);

		FVector TargetPoint = Hit.bBlockingHit ? Hit.Location : TraceEnd;
		return TargetPoint;
	}

	FBulletSpreadData SpreadData;
	TArray<FHitResult> Hits;
	UPROPERTY()
	FBulletHit BulletHit;
	bool BlockingHit;

	TArray<FHitResult> Trace(float MaxDistance = 10000.0f)
	{
		FVector AimDirection = (GetTargetPoint(MaxDistance) - TraceStart).GetSafeNormal();

		FVector BulletDirection = ApplySpread(AimDirection, GetSpread(), SpreadData);

		FVector End = TraceStart + BulletDirection * MaxDistance;
		BlockingHit = System::LineTraceMulti(TraceStart, End, ETraceTypeQuery::TraceTypeQuery3, false, TArray<AActor>(), DebugTrace, Hits, true, FLinearColor::Yellow, FLinearColor::Green, 2.0f);

		// System::DrawDebugConeInDegrees(TraceStart, AimDirection, 10000.0f, SpreadData.ConeWidth, SpreadData.ConeHeight, 36, FLinearColor::DPink, 10, 1);

		if (!BlockingHit)
		{
			Print("Trace did not hit anything!", 2, FLinearColor(1.0, 0.5, 0.0));
			ShootSFX();
			
			BulletHit = FBulletHit();
			return TArray<FHitResult>();
		}

		FHitResult LastHit = Hits.Last();

		BulletHit = FBulletHit(
			LastHit.bBlockingHit,
			LastHit.Actor.IsA(AAngelTrainingDummy),
			GetBodyPartHit(LastHit.Component).Head,
			ToMeters(LastHit.Distance),
			LastHit.Location,
			LastHit.Actor,
			Cast<AAngelTrainingDummy>(LastHit.Actor),
			LastHit.BoneName,
			GetBodyPartHit(LastHit.Component));

		if (BulletHit.PlayerHit)
			BulletHit.HitPlayer.OnDeath.AddUFunction(this, n"OnTargetDeath");

		ShootSFX();
		HitSFX();

		bool Penetrated = false;
		CreateImpactDecal(Penetrated);

		if (BulletHit.PlayerHit)
			Gameplay::ApplyPointDamage(
				BulletHit.HitActor,
				DamageFalloff.GetDamageAtDistance(BulletHit.Distance, BulletHit.HitBodyPart.BodyPart) * (Penetrated ? 0.8f : 1.0f),
				BulletDirection,
				LastHit,
				GetAngelCharacter(0).Controller,
				this,
				TSubclassOf<UDamageType>(UDamageType));

		return Hits;
	}

	void ShootSFX()
	{
		if (CurrentAmmo > 0)
			Gameplay::PlaySoundAtLocation(ShootSound, GetActorLocation(), FRotator::ZeroRotator, 1.0f, 1.0f, 0.0f, DefaultAttenuation);
		//else 
			//Gameplay::PlaySoundAtLocation(DryFireSound, GetActorLocation(), FRotator::ZeroRotator, 0.6f, 0.8f, 0.0f, DefaultAttenuation);
	}

	void HitSFX()
	{
		if (BulletHit.PlayerHit && BulletHit.Headshot)
		{
			if (BulletHit.HitPlayer.HasArmor())
			{
				Gameplay::PlaySound2D(HeadshotWithArmorSound);
			}
			else
			{
				Gameplay::PlaySound2D(HeadshotSound);
			}
		}
		else if (BulletHit.PlayerHit && !BulletHit.Headshot)
		{
			Gameplay::PlaySound2D(BodyshotSound);
		}
		else if (!BulletHit.PlayerHit)
		{
			Gameplay::PlaySoundAtLocation(GroundHitSound, BulletHit.Location, FRotator::ZeroRotator, 1.0f, 1.0f, 0.0f, DefaultAttenuation);
		}
	}

	void CreateImpactDecal(bool&out Penetrated)
	{
		for (FHitResult Hit : Hits)
		{
			if (Hit.Actor.IsA(AAngelPlayerCharacter) || Hit.Actor.IsA(AAngelTrainingDummy))
				continue;

			int i = Hits.FindIndex(Hit);

			if (i < Hits.Num() - 1) // Not the last hit
			{
				Penetrated = true;
			}

			UMaterialInterface DecalMaterial = Penetrated ? BulletPenetrationDecal : BulletHitDecal;
			FRotator DecalRotation = Penetrated ? GetAngelCharacter(0).ControlRotation : Hit.ImpactNormal.Rotation();

			UDecalComponent Decal = Gameplay::SpawnDecalAtLocation(DecalMaterial, FVector(8.0f, 8.0f, 8.0f), Hit.Location, DecalRotation, 15.0f);
			if (IsValid(Decal))
			{
				Decal.SetFadeScreenSize(0);
				Decal.SetFadeIn(0, 0);
			}
		}
	}

	UFUNCTION()
	void OnTargetDeath()
	{
		auto PlayerState = GetAngelPlayerState(0);
		PlayerState.MultikillCount++;

		if (PlayerState.MultikillCount <= 5)
		{
			int Index = Math::Clamp(PlayerState.MultikillCount - 1, 0, MultikillSounds.Num() - 1);
			USoundBase Sound = MultikillSounds[Index];
			Gameplay::PlaySound2D(Sound);

			if (PlayerState.MultikillCount == 5)
			{
				Gameplay::PlaySound2D(MultikillAceSound);
			}

			System::SetTimer(this, n"ResetMultikill", 4, false);
		}

		BP_OnTargetDeath();
	}

	UFUNCTION(NotBlueprintCallable)
	void ResetMultikill()
	{
		GetAngelPlayerState(0).ResetMultikill();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "On Kill")
	void BP_OnTargetDeath()
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
			Trace();

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

UFUNCTION(BlueprintPure)
float ToMeters(float DistanceInCm)
{
	return DistanceInCm / 100.0f;
}

UFUNCTION(BlueprintPure)
FBodyPartHit GetBodyPartHit(UPrimitiveComponent Component)
{
	if (!IsValid(Component))
		return FBodyPartHit();

	if (Component.ComponentTags.Contains(n"Head"))
	{
		return FBodyPartHit(true, false, false, EBodyPart::Head);
	}
	else if (Component.ComponentTags.Contains(n"Body"))
	{
		return FBodyPartHit(false, true, false, EBodyPart::Body);
	}
	else if (Component.ComponentTags.Contains(n"Legs"))
	{
		return FBodyPartHit(false, false, true, EBodyPart::Legs);
	}

	return FBodyPartHit();
}