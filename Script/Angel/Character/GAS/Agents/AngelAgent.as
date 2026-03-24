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
	TSubclassOf<UAngelAbility> AbilityUsed;

	FDeathInfo(AAngelAgent InKiller, AAngelAgent InVictim, AGunBase InWeaponUsed = nullptr, bool InWasHeadshot = false, TSubclassOf<UAngelAbility> InAbilityUsed = nullptr)
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
	UPROPERTY(Category = "Agent | GAS", EditDefaultsOnly)
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

	UPROPERTY(Category = "Agent | Health", VisibleAnywhere, BlueprintReadOnly, BlueprintGetter = GetHealthAttribute, ToolTip = "Only used for display purposes.")
	float CurrentHealth;

	UPROPERTY(Category = "Agent | Armor", EditAnywhere)
	EArmorType Armor;
	default Armor = EArmorType::None;

	UPROPERTY(Category = "Agent | Armor", VisibleAnywhere, BlueprintReadOnly, BlueprintGetter = GetArmorAttribute, ToolTip = "Only used for display purposes.")
	float CurrentArmor;

	UPROPERTY(Category = "Agent | Health", VisibleAnywhere)
	FDeathInfo DeathInfo;

	// helper functions

	UFUNCTION(Category = "Agent | Health", BlueprintPure)
	float GetHealthAttribute() const property
	{
		return Attributes.Health.GetCurrentValue();
	}

	UFUNCTION(Category = "Agent | Armor", BlueprintPure)
	float GetArmorAttribute() const property
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

	UFUNCTION(BlueprintOverride)
	protected void BeginPlay()
	{
		for (auto Ability : Abilities)
			AbilitySystem.GiveAbility(FGameplayAbilitySpec(Ability, 1, -1));

		Attributes = Cast<UAngelGASAttributes>(AbilitySystem.RegisterAttributeSet(UAngelGASAttributes));

		if (Abilities.Num() >= 3)
		{
			Attributes.Ability_C_Uses.SetBaseValue(0);
			Attributes.Ability_C_Uses.SetCurrentValue(0);
			Attributes.Ability_Q_Uses.SetBaseValue(0);
			Attributes.Ability_Q_Uses.SetCurrentValue(0);
			Attributes.Ability_E_Uses.SetBaseValue(1);
			Attributes.Ability_E_Uses.SetCurrentValue(1);
			// Attributes.Ability_X_Uses.SetBaseValue(Abilities[3].DefaultObject.Uses);
		}

		// These are just for display purposes
		CurrentHealth = GetHealthAttribute();
		CurrentArmor = GetArmorAttribute();

		check(Avatar != nullptr, "Avatar texture not assigned!");

		Print(f"{AgentName} has spawned with {GetHealthAttribute()} health and {GetArmorAttribute()} armor.", 1.5f, FLinearColor::Green);

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, Category = "Agent | Health", DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(BlueprintOverride, Category = "Agent | Damage")
	void PointDamage(float Damage, const UDamageType DamageType, FVector HitLocation, FVector HitNormal,
					 UPrimitiveComponent HitComponent, FName BoneName, FVector ShotFromDirection,
					 AController InstigatedBy, AActor DamageCauser, FHitResult HitInfo)
	{
		DeathInfo.Killer = Cast<AAngelAgent>(InstigatedBy.ControlledPawn);
		DeathInfo.Victim = this;
		DeathInfo.WeaponUsed = Cast<AGunBase>(DamageCauser);
		DeathInfo.WasHeadshot = GetBodyPartHit(HitComponent).Head;

		ApplyDamage(Damage);

		BP_PointDamage(Damage, DamageType, HitLocation, HitNormal, HitComponent, BoneName, ShotFromDirection, InstigatedBy, DamageCauser, HitInfo);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Took Damage", Category = "Damage")
	void BP_TookDamage(float HealthDamage, float ArmorDamage)
	{}

	UFUNCTION(BlueprintEvent, Category = "Damage", DisplayName = "Point Damage")
	void BP_PointDamage(float Damage, const UDamageType DamageType, FVector HitLocation, FVector HitNormal,
						UPrimitiveComponent HitComponent, FName BoneName, FVector ShotFromDirection,
						AController InstigatedBy, AActor DamageCauser, FHitResult HitInfo)
	{}

	/**
	 * Calculates how incoming damage is split between health and armor.
	 * @param Damage The total incoming damage.
	 * @param DamageToHealth Output parameter for damage applied to health.
	 * @param DamageToArmor Output parameter for damage applied to armor.
	 */
	UFUNCTION(Category = "Agent | Damage")
	void CalculateDamageTaken(float Damage, float&out DamageToHealth, float&out DamageToArmor)
	{
		float CurrHealth = GetHealthAttribute();
		float CurrArmor = GetArmorAttribute();

		// initialize returned damage values
		DamageToHealth = 0;
		DamageToArmor = 0;

		const float HealthRatio = 1 - Armor::ABSORPTION_RATIO;

		if (CurrArmor > 0)
		{
			// How much armor (in incoming-damage units) is needed to absorb full damage
			float ArmorNeeded = Damage * Armor::ABSORPTION_RATIO;

			if (CurrArmor >= ArmorNeeded) // armor can fully absorb, no break
			{
				// armor absorbed ArmorNeeded (portion of incoming damage)
				DamageToArmor = ArmorNeeded;
				// health takes the remaining portion
				DamageToHealth = Damage * HealthRatio;

				CurrArmor -= ArmorNeeded;
				CurrHealth -= DamageToHealth;
			}
			else // armor breaks mid-hit
			{
				// amount of incoming damage that was absorbed by armor
				float AbsorbedDamage = CurrArmor / Armor::ABSORPTION_RATIO;
				// remaining incoming damage that goes straight to health
				float RemainingDamage = Damage - AbsorbedDamage;

				// health takes a portion from the absorbed damage plus the remaining damage
				float HealthFromAbsorbed = AbsorbedDamage * HealthRatio;
				DamageToHealth = HealthFromAbsorbed + RemainingDamage;
				// damage portion attributed to armor (incoming-damage units)
				DamageToArmor = AbsorbedDamage;

				// clamp to max value
				DamageToArmor = Math::Min(DamageToArmor, Armor::GetMaxArmor(Armor));

				CurrHealth -= DamageToHealth;
				CurrArmor = 0;
			}
		}
		else
		{
			// no armor: all damage goes to health
			DamageToArmor = 0;
			DamageToHealth = Damage;

			CurrHealth -= Damage;
		}
	}

	UPROPERTY(Category = "Agent | Debug | Visuals")
	UParticleSystem DeathEffect;

	UFUNCTION(Category = "Agent | Health")
	void Death()
	{
		if (GameplayTags.HasTag(GameplayTags::Agent_State_Dead))
			return;
		else
			GameplayTags.AddTag(GameplayTags::Agent_State_Dead);

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
		GetAngelGameState().OnAgentDeath.Broadcast(DeathInfo);

		BP_Death(DeathInfo);
	}

	UFUNCTION(BlueprintEvent, Category = "Dummy | Health", DisplayName = "Death")
	void BP_Death(FDeathInfo InDeathInfo)
	{}

	UFUNCTION(Category = "Agent | Health")
	void Respawn()
	{
		ResetAgent();

		SetActorHiddenInGame(false);
		System::SetTimer(this, n"EnableCollision", 0.5f, false);

		GameplayTags.RemoveTag(GameplayTags::Agent_State_Dead);
	}

	UFUNCTION()
	void EnableCollision()
	{
		SetActorEnableCollision(true);
	}

	UFUNCTION(Category = "Agent | Damage")
	void ApplyDamage(float Damage)
	{
		float HealthDamage;
		float ArmorDamage;
		CalculateDamageTaken(Damage, HealthDamage, ArmorDamage);

		FGameplayEffectSpecHandle HealthHandle = AbilitySystem.MakeOutgoingSpec(UGE_Damage_Health, 1, FGameplayEffectContextHandle());
		if (HealthHandle.IsValid() && GetHealthAttribute() > 0)
		{
			HealthHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Health, -HealthDamage);
			AbilitySystem.ApplyGameplayEffectSpecToSelf(HealthHandle);

			CurrentHealth = Math::Clamp(GetHealthAttribute(), 0.0f, Attributes.MaxHealth.BaseValue);

			Print(f"Applied {Math::RoundToInt(HealthDamage)} HEALTH damage to {AgentName}", 1, FLinearColor::DPink);
		}

		FGameplayEffectSpecHandle ArmorHandle = AbilitySystem.MakeOutgoingSpec(UGE_Damage_Armor, 1, FGameplayEffectContextHandle());
		if (ArmorHandle.IsValid() && GetArmorAttribute() > 0)
		{
			ArmorHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Armor, -ArmorDamage);
			AbilitySystem.ApplyGameplayEffectSpecToSelf(ArmorHandle);

			CurrentArmor = Math::Clamp(GetArmorAttribute(), 0.0f, Attributes.MaxArmor.BaseValue);

			Print(f"Applied {Math::RoundToInt(ArmorDamage)} ARMOR damage to {AgentName}", 1, FLinearColor::Teal);
		}

		BP_TookDamage(-HealthDamage, -ArmorDamage);
	}

	UFUNCTION(Category = "Agent | Health")
	void ApplyHealing(float HealAmount)
	{
		if (GetHealthAttribute() >= Attributes.MaxHealth.BaseValue)
			return;

		FGameplayEffectSpecHandle HealHandle = AbilitySystem.MakeOutgoingSpec(UGE_Restore_Health, 1, FGameplayEffectContextHandle());
		if (HealHandle.IsValid())
		{
			HealHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Health, HealAmount);
			AbilitySystem.ApplyGameplayEffectSpecToSelf(HealHandle);

			CurrentHealth = Math::Clamp(GetHealthAttribute(), 0.0f, Attributes.MaxHealth.BaseValue);

			// Print(f"Applied {HealAmount} health healing to {AgentName}", 5.0f, FLinearColor::Green);
		}
	}

	UFUNCTION(Category = "Agent | Armor")
	void ApplyArmor(EArmorType NewArmor)
	{
		Armor = NewArmor;
		float ArmorAmount = Armor::GetMaxArmor(NewArmor);

		FGameplayEffectSpecHandle ArmorHandle = AbilitySystem.MakeOutgoingSpec(UGE_Override_Armor, 1, FGameplayEffectContextHandle());
		if (ArmorHandle.IsValid())
		{
			ArmorHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Armor, ArmorAmount);
			AbilitySystem.ApplyGameplayEffectSpecToSelf(ArmorHandle);

			CurrentArmor = Math::Clamp(GetArmorAttribute(), 0.0f, Attributes.MaxArmor.BaseValue);

			Print(f"Applied {ArmorAmount} armor to {AgentName}", 1.0f, FLinearColor::LucBlue);
		}
	}

	UFUNCTION(BlueprintPure, Category = "Agent | Armor")
	bool HasRemainingArmor()
	{
		if (Armor == EArmorType::None)
			return false;

		return GetArmorAttribute() > 0;
	}

	UFUNCTION(Category = "Agent | Health")
	void ResetAgent()
	{
		ApplyHealing(Attributes.MaxHealth.BaseValue);
		ApplyArmor(Armor);
	}
}

// Global Helper Functions

UFUNCTION(Category = "Agent | Damage")
void ApplyDamage(AAngelAgent Agent, float Damage)
{
	Agent.ApplyDamage(Damage);
}

UFUNCTION(Category = "Agent | Health")
void ApplyHealing(AAngelAgent Agent, float HealAmount)
{
	Agent.ApplyHealing(HealAmount);
}

UFUNCTION(Category = "Agent | Armor")
void ApplyArmor(AAngelAgent Agent, EArmorType Armor)
{
	Agent.ApplyArmor(Armor);
}

UFUNCTION(BlueprintPure, Category = "Agent | Armor")
bool HasRemainingArmor(AAngelAgent Agent)
{
	return Agent.HasRemainingArmor();
}

UFUNCTION(Category = "Agent | Health")
void ResetAgent(AAngelAgent Agent)
{
	Agent.ResetAgent();
}
