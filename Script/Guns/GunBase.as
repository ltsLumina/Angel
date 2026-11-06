UCLASS(Abstract)
class AGunBase : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Root;

	UPROPERTY(DefaultComponent, Category = "Gun | Visual")
	USkeletalMeshComponent GunMesh;

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly)
	USoundCue ShootSound;

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly)
	USoundWave DryFireSound;

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly)
	TMap<USoundWave, EEquipSpeed> EquipSounds;

	UPROPERTY(Category = "Gun | Audio | Weapon Sounds", EditDefaultsOnly)
	USoundBase ReloadSound;

	UPROPERTY(Category = "Gun | Audio | Headshots", EditDefaultsOnly)
	USoundWave HeadshotSound;

	UPROPERTY(Category = "Gun | Audio | Headshots", EditDefaultsOnly)
	USoundWave HeadshotWithArmorSound;

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

	UPROPERTY(Category = "Gun | Visual | Decals", EditDefaultsOnly)
	UMaterialInterface BulletHitDecal;

	UPROPERTY(Category = "Gun | Visual | Decals", EditDefaultsOnly)
	UMaterialInterface BulletPenetrationDecal;

	UFUNCTION(BlueprintPure)
	USoundWave GetEquipSound(EEquipSpeed Speed)
	{
		for (auto& Elem : EquipSounds)
		{
			if (Elem.Value == Speed)
				return Elem.Key;
		}

		if (Speed == EEquipSpeed::Instant)
		{
			for (auto& Elem : EquipSounds)
			{
				if (Elem.Value == EEquipSpeed::Fast)
					return Elem.Key;
			}
		}

		for (auto& Elem : EquipSounds)
		{
			if (Elem.Value == EEquipSpeed::Normal)
				return Elem.Key;
		}

		return nullptr;
	}

	void PlayShootSFX(bool HasAmmo)
	{
		if (HasAmmo)
			Gameplay::PlaySoundAtLocation(ShootSound, GetActorLocation(), FRotator::ZeroRotator, 1.0f, 1.0f, 0.0f, DefaultAttenuation);
	}

	void PlayHitSFX(FHitResult Hit, FGameplayEffectContextHandle EffectContext, float Distance)
	{
		if (Hit.Actor.IsA(AAngelAgent))
		{
			AAngelAgent Agent = Cast<AAngelAgent>(Hit.Actor);
			if (EffectContext.IsPrecisionHit)
				Gameplay::PlaySound2D(Agent.HasRemainingArmor() ? HeadshotWithArmorSound : HeadshotSound);
			else
				Gameplay::PlaySound2D(BodyshotSound);
			return;
		}

		float PitchMultiplier = Math::Clamp(1.0f - (Distance / 10000.0f), 0.75f, 1.0f);
		Gameplay::PlaySoundAtLocation(GroundHitSound, Hit.Location, FRotator::ZeroRotator, 1.0f, PitchMultiplier, 0.0f, DefaultAttenuation);
	}

	void CreateImpactDecal(TArray<FHitResult> Hits, bool&out Penetrated)
	{
		for (FHitResult Hit : Hits)
		{
			if (Hit.Actor.IsA(AAngelPlayerCharacter) || Hit.Actor.IsA(AAngelAgent))
				continue;

			int Index = Hits.FindIndex(Hit);
			Penetrated = Index < Hits.Num() - 1;
			UMaterialInterface DecalMaterial = Penetrated ? BulletPenetrationDecal : BulletHitDecal;
			FRotator DecalRotation = Penetrated ? Game::Player.ControlRotation : Hit.ImpactNormal.Rotation();
			UDecalComponent Decal = Gameplay::SpawnDecalAtLocation(DecalMaterial, FVector(8.0f, 8.0f, 8.0f), Hit.Location, DecalRotation, 15.0f);
			if (IsValid(Decal))
			{
				Decal.SetFadeScreenSize(0);
				Decal.SetFadeIn(0, 0);
			}
		}
	}

	UFUNCTION(BlueprintEvent, Category = "Gun | Visual", DisplayName = "Shoot")
	void BP_Shoot(EGunState GunState)
	{}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Visual", DisplayName = "Reload")
	void BP_OnReload()
	{}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Category = "Gun | Visual", DisplayName = "Ready")
	void BP_Ready()
	{}
};
