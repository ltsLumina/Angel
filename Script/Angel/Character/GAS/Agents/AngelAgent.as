event void FOnKillEvent(FDeathInfo DeathInfo);
event void FOnDeathEvent(FDeathInfo DeathInfo);

struct FDeathInfo
{
	UPROPERTY()
	AAngelAgent Killer;

	UPROPERTY()
	AAngelAgent Victim;

	UPROPERTY()
	AGunBase WeaponUsed;

	UPROPERTY()
	bool WasHeadshot;

	UPROPERTY()
	UAngelAbility AbilityUsed;

	FDeathInfo(AAngelAgent InKiller, AAngelAgent InVictim, AGunBase InWeaponUsed = nullptr, bool InWasHeadshot = false, UAngelAbility InAbilityUsed = nullptr)
	{
		Killer = InKiller;
		Victim = InVictim;
		WeaponUsed = InWeaponUsed;
		WasHeadshot = InWasHeadshot;
		AbilityUsed = InAbilityUsed;
	}
}

namespace Armor
{
	const float NO_ARMOR = 0;
	const float LIGHT_ARMOR = 25;
	const float HEAVY_ARMOR = 50;
	const float ABSORPTION_RATIO = 0.66f;

	UFUNCTION(BlueprintPure)
	float GetMaxArmor(EArmorType ArmorType)
	{
		switch (ArmorType)
		{
			case EArmorType::None:
				return NO_ARMOR;
			case EArmorType::Light:
				return LIGHT_ARMOR;
			case EArmorType::Heavy:
				return HEAVY_ARMOR;
			default:
				return 0;
		}
	}

	UFUNCTION(BlueprintPure)
	bool HasArmor(EArmorType ArmorType)
	{
		return ArmorType != EArmorType::None;
	}
}

UCLASS(Abstract)
class AAngelAgent : AAngelscriptGASCharacter
{
	UPROPERTY()
	TArray<TSubclassOf<UAngelAbility>> Abilities;

	UPROPERTY(Category = "Agent | GAS", EditConst)
	UAngelGASAttributes Attributes;

	UPROPERTY(Category = "Agent | GAS", EditConst)
	FGameplayTagContainer GameplayTags;

	UPROPERTY(Category = "Agent | Info", VisibleAnywhere)
	FText AgentName;
	default AgentName = FText::FromString("Agent");

	UPROPERTY(Category = "Agent | Info", VisibleAnywhere)
	UTexture2D Avatar;
	default check(IsValid(Avatar), "Avatar texture not assigned!");

	UPROPERTY(Category = "Agent | Health", VisibleAnywhere, BlueprintReadOnly, BlueprintGetter = GetCurrentHealth)
	float CurrentHealth;

	UPROPERTY(Category = "Agent | Armor", EditAnywhere)
	EArmorType Armor;
	default Armor = EArmorType::None;

	UPROPERTY(Category = "Agent | Armor", VisibleAnywhere, BlueprintReadOnly, BlueprintGetter = GetCurrentArmor)
	float CurrentArmor;

	// helper functions

	UFUNCTION(Category = "Agent | Health", BlueprintPure)
	float GetCurrentHealth() const property
	{
		return Attributes.Health.GetCurrentValue();
	}

	UFUNCTION(Category = "Agent | Armor", BlueprintPure)
	float GetCurrentArmor() const property
	{
		return Attributes.Armor.GetCurrentValue();
	}
	
	// Events

	/**
	 * Called when this agent kills another agent.
	 */
	UPROPERTY(Category = "Agent | Events", VisibleAnywhere)
	FOnKillEvent OnKill;

	/**
	 * Called when this agent dies.
	 */
	UPROPERTY(Category = "Agent | Events", VisibleAnywhere)
	FOnDeathEvent OnDeath;

	// heath & armor functions

/*
	UFUNCTION(Category = "Agent | Armor")
	void GrantArmor(EArmorType NewArmor, float NewArmorValue = -1)
	{
		Armor = NewArmor;
		switch (Armor)
		{
			case EArmorType::None:
				NewArmorValue = Armor::NO_ARMOR;
				break;
			case EArmorType::Light:
				if (NewArmorValue < 0)
					NewArmorValue = Armor::LIGHT_ARMOR;
				break;
			case EArmorType::Heavy:
				if (NewArmorValue < 0)
					NewArmorValue = Armor::HEAVY_ARMOR;
				break;
		}
	}
*/

	UFUNCTION(BlueprintPure, Category = "Agent | Armor")
	bool HasRemainingArmor()
	{
		if (Armor == EArmorType::None)
			return false;

		return GetCurrentArmor() > 0;
	}

	UFUNCTION(BlueprintOverride)
	protected void BeginPlay()
	{
		for (auto Ability : Abilities)
			AbilitySystem.GiveAbility(FGameplayAbilitySpec(Ability, 1, -1));

		Attributes = Cast<UAngelGASAttributes>(AbilitySystem.RegisterAttributeSet(UAngelGASAttributes));

		Attributes.OnHealthChanged.AddUFunction(this, n"OnHealthChanged");

		//Heal();
		//GrantArmor(Armor);

		Print(f"{AgentName} has spawned with {GetCurrentHealth()} health and {GetCurrentArmor()} armor.", 1.0f, FLinearColor::Green);

		BP_BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHealthChanged(float32 NewHealth, float32 OldHealth)
	{
		if (GetCurrentHealth() <= 0)
			Death();
		Print(f"Health changed from {OldHealth} to {NewHealth}", 2.0f, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintEvent, Category = "Agent | Health", DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(BlueprintOverride, Category = "Agent | Damage")
	void PointDamage(float Damage, const UDamageType DamageType, FVector HitLocation, FVector HitNormal,
					 UPrimitiveComponent HitComponent, FName BoneName, FVector ShotFromDirection,
					 AController InstigatedBy, AActor DamageCauser, FHitResult HitInfo)
	{
		float RemainingHealth;
		float RemainingArmor;
		TakeDamage(Damage, RemainingHealth, RemainingArmor);
		Print(f"Health: {RemainingHealth}\nArmor: {RemainingArmor}\nDamage Taken: {Damage}", 1.5f, FLinearColor(0.20, 1.00, 0.30));

		BP_PointDamage(Damage, DamageType, HitLocation, HitNormal, HitComponent, BoneName, ShotFromDirection, InstigatedBy, DamageCauser, HitInfo);
	}

	UFUNCTION(BlueprintEvent, Category = "Damage", DisplayName = "Point Damage")
	void BP_PointDamage(float Damage, const UDamageType DamageType, FVector HitLocation, FVector HitNormal,
						UPrimitiveComponent HitComponent, FName BoneName, FVector ShotFromDirection,
						AController InstigatedBy, AActor DamageCauser, FHitResult HitInfo)
	{}

	UFUNCTION(Category = "Agent | Damage")
	void TakeDamage(float Damage, float&out RemainingHealth, float&out RemainingArmor)
	{
		float CurrHealth = GetCurrentHealth();
		float CurrArmor = GetCurrentArmor();

		const float HealthRatio = 1 - Armor::ABSORPTION_RATIO;

		if (CurrArmor > 0)
		{
			// How much armor is needed to absorb full damage
			float ArmorNeeded = Damage * Armor::ABSORPTION_RATIO;

			if (CurrArmor >= ArmorNeeded) // armor can fully absorb, no break
			{
				CurrArmor -= ArmorNeeded;
				CurrHealth -= Damage * HealthRatio;

				RemainingHealth = CurrHealth;
				RemainingArmor = CurrArmor;
			}
			else // armor breaks mid-hit
			{
				float AbsorbedDamage = CurrArmor / Armor::ABSORPTION_RATIO;
				float RemainingDamage = Damage - AbsorbedDamage;

				CurrHealth -= AbsorbedDamage * HealthRatio; // partial absorption
				CurrHealth -= RemainingDamage;
				CurrArmor = 0;
				//GrantArmor(EArmorType::None);

				RemainingHealth = CurrHealth;
				RemainingArmor = CurrArmor;
			}
		}
		else
		{
			CurrHealth -= Damage;

			RemainingHealth = CurrHealth;
			RemainingArmor = CurrArmor;
		}

		//SetCurrentHealth(CurrHealth);
		//SetCurrentArmor(CurrArmor);

		if (GetCurrentHealth() <= 0)
			Death();
	}

	UPROPERTY(Category = "Agent | Debug | Visuals")
	UParticleSystem DeathEffect;

	bool IsDead;

	UFUNCTION(Category = "Agent | Health")
	void Death(FDeathInfo DeathInfo = FDeathInfo())
	{
		if (IsDead)
			return;

		IsDead = true;

		FGameplayEffectQuery Query;
		for (FActiveGameplayEffectHandle Handle : AbilitySystem.GetActiveEffects(Query))
		{
			AbilitySystem.RemoveActiveGameplayEffect(Handle);
		}

		Gameplay::SpawnEmitterAtLocation(DeathEffect, ActorLocation, ActorRotation, FVector(1.5f), true);
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);

		System::SetTimer(this, n"Respawn", 1.5f, false);

		OnDeath.Broadcast(DeathInfo);
		BP_Death(DeathInfo);
	}

	UFUNCTION(BlueprintEvent, Category = "Dummy | Health", DisplayName = "Death")
	void BP_Death(FDeathInfo DeathInfo)
	{}

	UFUNCTION(Category = "Agent | Health")
	void Respawn()
	{
		//Heal();
		//GrantArmor(Armor);

		SetActorHiddenInGame(false);
		System::SetTimer(this, n"EnableCollision", 0.5f, false);

		IsDead = false;
	}

	UFUNCTION()
	void EnableCollision()
	{
		SetActorEnableCollision(true);
	}
}