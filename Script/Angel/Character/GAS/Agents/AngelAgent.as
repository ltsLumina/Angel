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
		
		ResetAgent(this);

		Print(f"{AgentName} has spawned with {GetCurrentHealth()} health and {GetCurrentArmor()} armor.", 1.5f, FLinearColor::Green);

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
		float HealthDamge;
		float ArmorDamage;
		// Calculate damage split for event
		CalculateDamageTaken(Damage, HealthDamge, ArmorDamage);

		// Actually apply the damage
		ApplyDamage(this, Damage);

		// Call the event
		BP_TookDamage(-HealthDamge, -ArmorDamage);

		// Call the Point Damage event for whatever reason
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
		float CurrHealth = GetCurrentHealth();
		float CurrArmor = GetCurrentArmor();

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
	void Death(FDeathInfo DeathInfo = FDeathInfo())
	{
		if (GameplayTags.HasTag(GameplayTags::Agent_State_Dead))
			return;

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
		BP_Death(DeathInfo);
	}

	UFUNCTION(BlueprintEvent, Category = "Dummy | Health", DisplayName = "Death")
	void BP_Death(FDeathInfo DeathInfo)
	{}

	UFUNCTION(Category = "Agent | Health")
	void Respawn()
	{
		ResetAgent(this);

		SetActorHiddenInGame(false);
		System::SetTimer(this, n"EnableCollision", 0.5f, false);

		GameplayTags.RemoveTag(GameplayTags::Character_State_Dead);
	}

	UFUNCTION()
	void EnableCollision()
	{
		SetActorEnableCollision(true);
	}
}

UFUNCTION(Category = "Agent | Damage")
void ApplyDamage(AAngelAgent Agent, float Damage)
{
	if (!IsValid(Agent))
	{
		PrintError("ApplyDamage: Invalid Agent");
		return;
	}

	float HealthDamage;
	float ArmorDamage;
	Agent.CalculateDamageTaken(Damage, HealthDamage, ArmorDamage);

	FGameplayEffectSpecHandle HealthHandle = Agent.AbilitySystem.MakeOutgoingSpec(UGE_Damage_Health, 1, FGameplayEffectContextHandle());
	if (HealthHandle.IsValid() && Agent.GetCurrentHealth() > 0)
	{
		HealthHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Health, -HealthDamage);
		Agent.AbilitySystem.ApplyGameplayEffectSpecToSelf(HealthHandle);

		Print(f"Applied {Math::RoundToInt(HealthDamage)} HEALTH damage to {Agent.AgentName}", 1, FLinearColor::DPink);
	}

	FGameplayEffectSpecHandle ArmorHandle = Agent.AbilitySystem.MakeOutgoingSpec(UGE_Damage_Armor, 1, FGameplayEffectContextHandle());
	if (ArmorHandle.IsValid() && Agent.GetCurrentArmor() > 0)
	{
		ArmorHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Armor, -ArmorDamage);
		Agent.AbilitySystem.ApplyGameplayEffectSpecToSelf(ArmorHandle);

		Print(f"Applied {Math::RoundToInt(ArmorDamage)} ARMOR damage to {Agent.AgentName}", 1, FLinearColor::Teal);
	}
}

UFUNCTION(Category = "Agent | Health")
void ApplyHealing(AAngelAgent Agent, float HealAmount)
{
	if (!IsValid(Agent))
	{
		PrintError("ApplyHealing: Invalid Agent");
		return;
	}

	if (Agent.GetCurrentHealth() >= Agent.Attributes.Health.BaseValue)
		return;

	FGameplayEffectSpecHandle HealHandle = Agent.AbilitySystem.MakeOutgoingSpec(UGE_Restore_Health, 1, FGameplayEffectContextHandle());
	if (HealHandle.IsValid())
	{
		HealHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Health, HealAmount);
		Agent.AbilitySystem.ApplyGameplayEffectSpecToSelf(HealHandle);

		// Print(f"Applied {HealAmount} health healing to {Agent.AgentName}", 5.0f, FLinearColor::Green);
	}
}

UFUNCTION(Category = "Agent | Health | Armor")
void ApplyArmor(AAngelAgent Agent, EArmorType Armor)
{
	if (!IsValid(Agent))
	{
		PrintError("ApplyArmor: Invalid Agent");
		return;
	}

	if (Agent.GetCurrentArmor() >= Armor::GetMaxArmor(Armor))
		return;

	float ArmorAmount = Armor::GetMaxArmor(Armor);

	FGameplayEffectSpecHandle ArmorHandle = Agent.AbilitySystem.MakeOutgoingSpec(UGE_Restore_Armor, 1, FGameplayEffectContextHandle());
	if (ArmorHandle.IsValid())
	{
		ArmorHandle.Spec.SetByCallerMagnitude(GameplayTags::Data_Damage_Armor, ArmorAmount);
		Agent.AbilitySystem.ApplyGameplayEffectSpecToSelf(ArmorHandle);

		// Print(f"Applied {ArmorAmount} armor to {Agent.AgentName}", 5.0f, FLinearColor::Blue);
	}
}

UFUNCTION(Category = "Agent | Health")
void ResetAgent(AAngelAgent Agent)
{
	ApplyHealing(Agent, Agent.Attributes.Health.BaseValue);
	ApplyArmor(Agent, Agent.Armor);
}
