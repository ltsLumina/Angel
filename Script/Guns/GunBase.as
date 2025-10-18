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

	UPROPERTY(Category = "Gun | Info", EditDefaultsOnly)
	UTexture2D Icon;

	UPROPERTY(Category = "Gun | Info", EditDefaultsOnly, BlueprintReadOnly, Meta = (UIMin = "0", UIMax = "5000"))
	int Price = 2900;

	UPROPERTY(Category = "Gun | Info", EditDefaultsOnly)
	EGunType GunType = EGunType::Rifle;

	// - movement
	UPROPERTY(Category = "Gun | Movement", EditDefaultsOnly, Meta = (ClampMin = "0.1", UIMin = "0.1", UIMax = "6.75", Units = "m/s"))
	float RunSpeed = 5.4;

	UPROPERTY(Category = "Gun | Movement", VisibleAnywhere, BlueprintGetter = "GetWalkSpeed", Meta = (Units = "m/s"))
	float WalkSpeed;
	default WalkSpeed = RunSpeed * WalkSpeedRatio;

	UPROPERTY(Category = "Gun | Movement", VisibleAnywhere, BlueprintGetter = "GetCrouchSpeed", Meta = (Units = "m/s"))
	float CrouchSpeed;
	default CrouchSpeed = RunSpeed * CrouchSpeedRatio;

	UPROPERTY(Category = "Gun | Movement", EditDefaultsOnly, Meta = (ClampMin = "0.1", UIMin = "0.1", UIMax = "1"))
	float WalkSpeedRatio = 0.80;

	UPROPERTY(Category = "Gun | Movement", EditDefaultsOnly, Meta = (ClampMin = "0.1", UIMin = "0.1", UIMax = "1"))
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
	default EquipTimes.Add(EEquipSpeed::Normal, 1.0);
	default EquipTimes.Add(EEquipSpeed::Fast, 0.6);
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
	UPROPERTY(Category = "Gun | Shooting", EditDefaultsOnly, BlueprintReadOnly, Meta = (UIMin = "0.1", UIMax = "30.0"))
	float FireRate = 9.75;

	/**
	 * The rounds per minute (RPM) of the gun, calculated from the fire rate.
	 * This is a derived property and is read-only.
	 */
	UPROPERTY(Category = "Gun | Shooting", VisibleAnywhere, BlueprintReadOnly)
	float RPM;
	default RPM = FireRate * 60;

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
		return TriggeredTime > ShootCooldown;
	}

	UPROPERTY(Category = "Gun | Shooting", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = "GetIsOnShootCooldown")
	bool IsOnShootCooldown;

	UFUNCTION(Category = "Gun | Shooting", BlueprintPure)
	bool GetIsOnShootCooldown()
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
	UPROPERTY(Category = "Gun | Accuracy | Bullets", EditDefaultsOnly, Meta = (UIMin = "0", ClampMax = "30", UIMax = "30"))
	int ProtectedBullets = 1;

	/**
	 * The number of bullets after which the spread reaches its maximum value.
	 */
	UPROPERTY(Category = "Gun | Accuracy | Bullets", VisibleInstanceOnly, BlueprintReadOnly, Meta = (ClampMin = "1", UIMin = "1", ClampMax = "30", UIMax = "30"))
	int MaxSpreadBullet = 6;

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

	UPROPERTY(Category = "Gun | Accuracy", VisibleInstanceOnly)
	FBulletSpreadData SpreadData;

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

/* TODO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< LOOK AT THIS I NEED TO FIX THIS FUTURE SELF AFTER SLEEPING ITS 7:44AM <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		if (RecoilIndex > ProtectedBullets && RecoilIndex <= MaxSpreadBullet)
		{
			Increment += 0.05f; // degrees per shot
		}
	*/
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

	UPROPERTY(Category = "Gun | Reload | Magazine", Instanced)
	UReloadStrategyBase ReloadStrategy;

	UPROPERTY(Category = "Gun | Reload | Magazine", VisibleInstanceOnly)
	bool HasMagazine = true;

	UPROPERTY(Category = "Gun | Reload | Magazine", VisibleInstanceOnly, BlueprintReadWrite)
	int CurrentAmmo = 30;
	default CurrentAmmo = MaxAmmo;

	UPROPERTY(Category = "Gun | Reload | Magazine", EditDefaultsOnly)
	int MaxAmmo = 30;

	UPROPERTY(Category = "Gun | Reload | Magazine", VisibleInstanceOnly)
	int ReserveAmmo = 60;
	default ReserveAmmo = MaxReserveAmmo;

	UPROPERTY(Category = "Gun | Reload | Magazine", EditDefaultsOnly)
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

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly)
	USoundWave DryFireSound;

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly, ToolTip = "Map of equip sounds. Key is the sound, value is the equip speed (Normal, Fast, Instant).")
	TMap<USoundWave, EEquipSpeed> EquipSounds;

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly, ToolTip = "Map of reload sounds. Key is the sound, value is whether it is for an empty magazine (true) or not (false).")
	USoundBase ReloadSound;

	/**
	 * Returns the appropriate equip sound based on the equip speed.
	 */
	UFUNCTION(BlueprintPure)
	USoundWave GetEquipSound(EEquipSpeed Speed)
	{
		// Try to find exact match first
		for (auto& Elem : EquipSounds)
		{
			if (Elem.Value == Speed)
				return Elem.Key;
		}

		// Fallback order: Fast, then Normal
		if (Speed == EEquipSpeed::Instant)
		{
			for (auto& Elem : EquipSounds)
			{
				if (Elem.Value == EEquipSpeed::Fast)
					return Elem.Key;
			}
		}
		// Always fallback to Normal if nothing else
		for (auto& Elem : EquipSounds)
		{
			if (Elem.Value == EEquipSpeed::Normal)
				return Elem.Key;
		}

		return nullptr;
	}

	// - hit sounds

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

	UPROPERTY(Category = "Gun | Shooting", NotVisible)
	FBulletHit BulletHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentAmmo = MaxAmmo;

		ShootCooldown = 1.0 / FireRate;
		RPM = FireRate * 60;

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

	TArray<FHitResult> Hits;
	bool BlockingHit;

	TArray<FHitResult> Trace(float MaxDistance = 10000.0f)
	{
		FVector AimDirection = (GetTargetPoint(MaxDistance) - TraceStart).GetSafeNormal();

		FVector BulletDirection = ApplySpread(AimDirection, GetSpread(), SpreadData);

		FVector End = TraceStart + BulletDirection * MaxDistance;
		BlockingHit = System::LineTraceMulti(TraceStart,
											 End,
											 ETraceTypeQuery::TraceTypeQuery3,
											 false,
											 TArray<AActor>(),
											 DebugTrace,
											 Hits,
											 true,
											 FLinearColor::Yellow,
											 FLinearColor::Green,
											 2.0f);

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
			LastHit.Actor.IsA(AAngelAgent),
			GetBodyPartHit(LastHit.Component).Head,
			ToMeters(LastHit.Distance),
			LastHit.Location,
			LastHit.Actor,
			Cast<AAngelAgent>(LastHit.Actor),
			LastHit.BoneName,
			GetBodyPartHit(LastHit.Component));

		if (BulletHit.PlayerHit)
		{
			// Instead of subscribing to each enemy's death, we'll check if they died
			// and broadcast to the global death event in the damage application
		}

		ShootSFX();
		HitSFX();

		bool Penetrated = false;
		CreateImpactDecal(Penetrated);

		if (BulletHit.PlayerHit)
		{
			float DamageAmount = DamageFalloff.GetDamageAtDistance(BulletHit.Distance, BulletHit.HitBodyPart.BodyPart) * (Penetrated ? 0.8f : 1.0f);

			Gameplay::ApplyPointDamage(
				BulletHit.HitActor,
				DamageAmount,
				BulletDirection,
				LastHit,
				GetAngelCharacter(0).Controller,
				this,
				TSubclassOf<UDamageType>(UDamageType));

			if (BulletHit.HitAgent.GameplayTags.HasTag(GameplayTags::Character_State_Dead))
			{
				AgentKilled(BulletHit.HitAgent);
			}
		}

		return Hits;
	}

	void ShootSFX()
	{
		if (CurrentAmmo > 0)
			Gameplay::PlaySoundAtLocation(ShootSound, GetActorLocation(), FRotator::ZeroRotator, 1.0f, 1.0f, 0.0f, DefaultAttenuation);
		// else
		// Gameplay::PlaySoundAtLocation(DryFireSound, GetActorLocation(), FRotator::ZeroRotator, 0.6f, 0.8f, 0.0f, DefaultAttenuation);
	}

	void HitSFX()
	{
		if (BulletHit.PlayerHit && BulletHit.Headshot)
		{
			if (BulletHit.HitAgent.HasRemainingArmor())
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
			float PitchMultiplier = Math::Clamp(1.0f - (BulletHit.Distance / 10000.0f), 0.75f, 1.0f); // Closer impacts sound higher pitched
			Gameplay::PlaySoundAtLocation(GroundHitSound, BulletHit.Location, FRotator::ZeroRotator, 1.0f, PitchMultiplier, 0.0f, DefaultAttenuation);
		}
	}

	void CreateImpactDecal(bool&out Penetrated)
	{
		for (FHitResult Hit : Hits)
		{
			if (Hit.Actor.IsA(AAngelPlayerCharacter) || Hit.Actor.IsA(AAngelAgent))
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

	UFUNCTION(Category = "Gun | Kill", DisplayName = "Agent Killed")
	void AgentKilled(AAngelAgent DeadAgent)
	{
		// Broadcast to global death event
		AAngelGameState GameState = GetAngelGameState();
		FDeathInfo DeathInfo = FDeathInfo(GetAngelCharacter(), DeadAgent, this, BulletHit.Headshot);
		GameState.OnAgentDeath.Broadcast(DeathInfo);

		// Handle multikill logic
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

		BP_OnTargetDeath(DeathInfo);
	}

	UFUNCTION(NotBlueprintCallable)
	void ResetMultikill()
	{
		GetAngelPlayerState(0).ResetMultikill();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "On Kill")
	void BP_OnTargetDeath(FDeathInfo DeathInfo)
	{}

	float ElapsedTime;
	float TriggeredTime;

	UFUNCTION(BlueprintEvent, Category = "Gun")
	bool Shoot(float InElapsedTime, float InTriggeredTime)
	{
		this.ElapsedTime = InElapsedTime;
		this.TriggeredTime = InTriggeredTime;

		switch (FireMode)
		{
			case EFireMode::Semi:
			case EFireMode::Burst:
				// Only allow firing on initial press in semi and burst modes
				if (GetIsFiring())
					return false;
				break;

			case EFireMode::Auto:
				// Allow holding down the trigger in auto mode
				break;
		}

		if (GetIsOnShootCooldown())
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

		Gameplay::PlaySound2D(ReloadSound);
	}

	void Ready()
	{
		if (!GetIsReady() && CurrentAmmo > 0)
		{
			ReloadStrategy.GunState = EGunState::Ready;
			BP_Ready();
			// Print(f"{GunName} readied! Magazine: {CurrentAmmo}/{MaxAmmo}", 2, FLinearColor(0.58, 0.95, 0.49));
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