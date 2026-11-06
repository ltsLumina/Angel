class UGunComponent : UActorComponent
{
	UPROPERTY(Category = "Gun", EditDefaultsOnly)
	UWeaponDefinition WeaponDefinition;

	UPROPERTY(Category = "Gun", EditDefaultsOnly)
	TMap<TSubclassOf<AGunBase>, UWeaponDefinition> WeaponDefinitions;

	UPROPERTY(Category = "Gun | Reload", EditDefaultsOnly, Instanced)
	UReloadStrategyBase ReloadStrategy;

	UPROPERTY(Category = "Gun | Runtime", VisibleInstanceOnly)
	int CurrentAmmo;

	UPROPERTY(Category = "Gun | Runtime", VisibleInstanceOnly)
	int ReserveAmmo;

	UPROPERTY(Category = "Gun | Runtime", VisibleInstanceOnly)
	bool HasMagazine;

	UPROPERTY(Category = "Gun | Runtime", VisibleInstanceOnly)
	int RecoilIndex;

	UPROPERTY(Category = "Gun | Runtime", VisibleInstanceOnly)
	float TimeSinceLastShot;

	UHolsterComponent HolsterComponent;
	float ElapsedTime;
	float TriggeredTime;
	TArray<FHitResult> Hits;
	FHitResult LastHit;
	FGameplayEffectContextHandle LastEffectContext;
	bool BulletPenetrated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Game::GameState.OnAgentDeath.AddUFunction(this, n"AgentKilled");
		InitializeWeapon();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IsValid(WeaponDefinition))
			return;
		TimeSinceLastShot += DeltaSeconds;
		if (TimeSinceLastShot > GetShootCooldown() * 2)
			RecoilIndex = 0;
		BP_Tick(DeltaSeconds);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(float DeltaSeconds)
	{}

	void InitializeWeapon()
	{
		if (!IsValid(WeaponDefinition))
			return;

		CurrentAmmo = WeaponDefinition.MaxAmmo;
		ReserveAmmo = WeaponDefinition.MaxReserveAmmo;
		HasMagazine = WeaponDefinition.HasMagazine;
		TimeSinceLastShot = GetShootCooldown();
		Ready();
	}

	UWeaponDefinition GetDefinition(AGunBase Gun)
	{
		if (IsValid(Gun) && WeaponDefinitions.Contains(Gun.GetClass()))
			return WeaponDefinitions[Gun.GetClass()];

		return WeaponDefinition;
	}

	void SetEquippedWeapon(AGunBase Gun)
	{
		WeaponDefinition = GetDefinition(Gun);
	}

	float GetShootCooldown()
	{
		return 1.0f / WeaponDefinition.FireRate;
	}

	bool IsReady()
	{
		return IsValid(ReloadStrategy) && ReloadStrategy.GunState == EGunState::Ready;
	}

	bool IsOnShootCooldown()
	{
		return TimeSinceLastShot < GetShootCooldown();
	}

	UFUNCTION()
	void Fire(FInputActionValue ActionValue, float32 InElapsedTime, float32 InTriggeredTime, const UInputAction SourceAction)
	{
		if (!IsValid(HolsterComponent))
			HolsterComponent = UHolsterComponent::Get(GetOwner());

		if (HolsterComponent.IsEquipping || !IsValid(HolsterComponent.EquippedGun))
			return;

		if (Shoot(HolsterComponent.EquippedGun, InElapsedTime, InTriggeredTime))
			BP_OnShoot(HolsterComponent.EquippedGun);
	}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Shoot"))
	void BP_OnShoot(AGunBase Gun)
	{}

	UFUNCTION(BlueprintEvent, Category = "Gun")
	bool Shoot(AGunBase Gun, float InElapsedTime, float InTriggeredTime)
	{
		if (!IsValid(WeaponDefinition))
			return false;

		ElapsedTime = InElapsedTime;
		TriggeredTime = InTriggeredTime;

		if ((WeaponDefinition.FireMode == EFireMode::Semi || WeaponDefinition.FireMode == EFireMode::Burst) && TriggeredTime > GetShootCooldown())
			return false;

		if (IsOnShootCooldown() || !HasMagazine || CurrentAmmo <= 0 || !IsReady())
			return false;

		Trace();
		LastEffectContext.EffectCauser = Gun;
		Gun.PlayShootSFX(CurrentAmmo > 0);

		if (LastHit.bBlockingHit)
		{
			Gun.PlayHitSFX(LastHit, LastEffectContext, Math::ToMeters(LastHit.Distance));
			BulletPenetrated = false;
			Gun.CreateImpactDecal(Hits, BulletPenetrated);
		}

		if (Hit::WasAgentHit(LastHit))
		{
			FBodyPartHit BodyPartHit = LastEffectContext.GetBodyPartHit();
			float DamageAmount = WeaponDefinition.DamageFalloff.GetDamageAtDistance(Math::ToMeters(LastHit.Distance), BodyPartHit.BodyPart);
			DamageAmount *= BulletPenetrated ? 0.8f : 1.0f;
			Cast<AAngelAgent>(LastHit.Actor).DealDamage(DamageAmount, LastEffectContext);
		}

		CurrentAmmo--;
		RecoilIndex++;
		Gun.BP_Shoot(ReloadStrategy.GunState);
		if (CurrentAmmo <= 0)
			ReloadStrategy.GunState = EGunState::NotReady;

		TimeSinceLastShot = 0;
		return true;
	}

	void Trace(float MaxDistance = 10000.0f)
	{
		UCameraComponent Camera = UCameraComponent::Get(Game::Player);
		FVector Start = Camera.WorldLocation;
		FVector Target = Start + Camera.GetForwardVector() * MaxDistance;
		FHitResult AimHit;
		System::LineTraceSingle(Start, Target, ETraceTypeQuery::TraceTypeQuery3, false, TArray<AActor>(), EDrawDebugTrace::None, AimHit, true);

		FVector AimDirection = ((AimHit.bBlockingHit ? AimHit.Location : Target) - Start).GetSafeNormal();
		FVector Direction = ApplySpread(AimDirection, GetSpread());
		System::LineTraceMulti(Start, Start + Direction * MaxDistance, ETraceTypeQuery::TraceTypeQuery3, false, TArray<AActor>(), EDrawDebugTrace::None, Hits, true);
		LastHit = Hits.Num() > 0 ? Hits.Last() : FHitResult();

		LastEffectContext = FGameplayEffectContextHandle();
		LastEffectContext.Instigator = Game::Player;
		LastEffectContext.EffectCauser = LastHit.Actor;
		LastEffectContext.IsPrecisionHit = LastHit.Component != nullptr && Hit::GetBodyPartHit(LastHit.Component).Head;
		LastEffectContext.BodyPartHit = LastHit.Component != nullptr ? Hit::GetBodyPartHit(LastHit.Component) : FBodyPartHit();
	}

	FVector ApplySpread(FVector AimDirection, float SpreadDeg)
	{
		float SpreadRad = Math::DegreesToRadians(SpreadDeg);
		float Yaw = Math::RandRange(0.0f, PI * 2.0f);
		float Radius = Math::Sqrt(Math::RandRange(0.0f, 1.0f)) * Math::Tan(SpreadRad);
		FVector Right = FVector::UpVector.CrossProduct(AimDirection).GetSafeNormal();
		FVector Up = AimDirection.CrossProduct(Right).GetSafeNormal();
		return (AimDirection + Right * Math::Cos(Yaw) * Radius + Up * Math::Sin(Yaw) * Radius).GetSafeNormal();
	}

	float GetSpread()
	{
		EAngelMovementState State = Game::Player.MovementState;
		switch (State)
		{
			case EAngelMovementState::Crouch:
				return WeaponDefinition.CrouchSpread;
			case EAngelMovementState::Airborne:
				return WeaponDefinition.AirbornePenalty;
			case EAngelMovementState::Run:
				return WeaponDefinition.RunPenalty;
			case EAngelMovementState::Walk:
				return WeaponDefinition.WalkPenalty;
			case EAngelMovementState::CrouchWalk:
				return WeaponDefinition.CrouchPenalty;
			default:
				return WeaponDefinition.StandingSpread;
		}
	}

	void Reload()
	{
		ReloadStrategy.Reload();
		Gameplay::PlaySound2D(HolsterComponent.EquippedGun.ReloadSound);
	}

	void Ready()
	{
		if (!IsReady() && CurrentAmmo > 0)
		{
			ReloadStrategy.GunState = EGunState::Ready;
			if (IsValid(HolsterComponent) && IsValid(HolsterComponent.EquippedGun))
				HolsterComponent.EquippedGun.BP_Ready();
		}
	}

	UFUNCTION()
	void AgentKilled(FGameplayEffectContextHandle EffectContext)
	{
		if (!IsValid(HolsterComponent) || EffectContext.GetInstigator() != Game::Player)
			return;

		AAngelPlayerState PlayerState = Game::PlayerState;
		PlayerState.MultikillCount++;
		if (PlayerState.MultikillCount <= 5)
		{
			AGunBase Gun = Cast<AGunBase>(EffectContext.GetEffectCauser());
			if (IsValid(Gun) && Gun.MultikillSounds.IsValidIndex(PlayerState.MultikillCount - 1))
				Gameplay::PlaySound2D(Gun.MultikillSounds[PlayerState.MultikillCount - 1]);
			if (PlayerState.MultikillCount == 5 && IsValid(Gun))
				Gameplay::PlaySound2D(Gun.MultikillAceSound);
			System::SetTimer(this, n"ResetMultikill", 4, false);
		}
	}

	UFUNCTION()
	void ResetMultikill()
	{
		Game::PlayerState.ResetMultikill();
	}
};
