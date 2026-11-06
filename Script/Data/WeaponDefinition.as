class UWeaponDefinition : UPrimaryDataAsset
{
	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	TSoftClassPtr<AGunBase> WeaponClass;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	FName WeaponID;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	FText DisplayName;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	USkeletalMesh GunMesh;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	UTexture2D KillfeedIcon;

	UPROPERTY(Category = "Info", EditDefaultsOnly)
	FName WeaponName;

	UPROPERTY(Category = "Info", EditDefaultsOnly)
	UTexture2D Icon;

	UPROPERTY(Category = "Info", EditDefaultsOnly, BlueprintReadOnly)
	int Price = 2900;

	UPROPERTY(Category = "Info", EditDefaultsOnly)
	EGunType GunType = EGunType::Rifle;

	UPROPERTY(Category = "Info", EditDefaultsOnly)
	EGunType Type = EGunType::Rifle;

	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float RunSpeed = 5.4f;

	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float WalkSpeedRatio = 0.80f;

	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float CrouchSpeedRatio = 0.40f;

	UPROPERTY(Category = "Equip", EditDefaultsOnly)
	TMap<EEquipSpeed, float> EquipTimes;

	UPROPERTY(Category = "Damage", EditDefaultsOnly, Instanced)
	UDamageFalloff DamageFalloff;

	UPROPERTY(Category = "Shooting", EditDefaultsOnly)
	EFireMode FireMode = EFireMode::Auto;

	UPROPERTY(Category = "Shooting", EditDefaultsOnly)
	float FireRate = 9.75f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	int ProtectedBullets = 1;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	int MaxSpreadBullet = 6;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float StandingSpread = 0.25f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float CrouchSpread = 0.21f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float StandingMaxSpread = 1.0f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float CrouchMaxSpread = 0.85f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float AirbornePenalty = 10.0f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float RunPenalty = 6.0f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float WalkPenalty = 3.0f;

	UPROPERTY(Category = "Accuracy", EditDefaultsOnly)
	float CrouchPenalty = 1.5f;

	UPROPERTY(Category = "Recoil", EditDefaultsOnly)
	float VerticalRecoilRunningMultiplier = 2.0f;

	UPROPERTY(Category = "Alternate Fire", EditDefaultsOnly)
	float Zoom = 1.25f;

	UPROPERTY(Category = "Alternate Fire", EditDefaultsOnly)
	float AltFireRateRatio = 0.9f;

	UPROPERTY(Category = "Alternate Fire", EditDefaultsOnly)
	float AltMoveSpeedRatio = 0.76f;

	UPROPERTY(Category = "Magazine", EditDefaultsOnly)
	bool HasMagazine = true;

	UPROPERTY(Category = "Magazine", EditDefaultsOnly)
	int MaxAmmo = 30;

	UPROPERTY(Category = "Magazine", EditDefaultsOnly)
	int MaxReserveAmmo = 60;
};
