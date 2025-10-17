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
	UPROPERTY(Category = "Agent | Info", EditDefaultsOnly)
	FText AgentName;
	default AgentName = FText::FromString("Agent");

	UPROPERTY(Category = "Agent | Info", EditDefaultsOnly)
	UTexture2D Avatar;
	default check(IsValid(Avatar), "Avatar texture not assigned!");

	UPROPERTY(Category = "Agent | Health", EditDefaultsOnly)
	float CurrentHealth;
	default CurrentHealth = 100.0f;

	UPROPERTY(Category = "Agent | Health", EditDefaultsOnly)
	float MaxHealth;
	default MaxHealth = 100.0f;

	UPROPERTY(Category = "Agent | Health | Armor", EditDefaultsOnly)
	EArmorType Armor;
	default Armor = EArmorType::None;

	UPROPERTY(Category = "Agent | Health | Armor", EditDefaultsOnly)
	float CurrentArmor;
	default CurrentArmor = 0.0f;

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

    UFUNCTION(Category = "Agent | Health")
	void Heal(float Amount)
	{
		CurrentHealth = Math::Min(CurrentHealth + Amount, MaxHealth);
	}

	UFUNCTION(Category = "Agent | Health | Armor")
	void GrantArmor(EArmorType NewArmor, float NewArmorValue = -1)
	{
		Armor = NewArmor;
		switch (Armor)
		{
			case EArmorType::None:
				CurrentArmor = NewArmorValue == -1 ? Armor::NO_ARMOR : NewArmorValue;
				break;
			case EArmorType::Light:
				CurrentArmor = NewArmorValue == -1 ? Armor::LIGHT_ARMOR : NewArmorValue;
				break;
			case EArmorType::Heavy:
				CurrentArmor = NewArmorValue == -1 ? Armor::HEAVY_ARMOR : NewArmorValue;
				break;
		}
	}

    UFUNCTION(BlueprintPure, Category = "Agent | Health | Armor")
    bool HasRemainingArmor()
    {
        if (Armor == EArmorType::None)
            return false;
        
        if (CurrentArmor <= 0)
            return false;
        return CurrentArmor > 0;
    }

    UFUNCTION(BlueprintOverride)
    protected void BeginPlay()
    {
        Heal(MaxHealth);
        GrantArmor(Armor, CurrentArmor);

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
		const float HealthRatio = 1 - Armor::ABSORPTION_RATIO;

		if (CurrentArmor > 0)
		{
			// How much armor is needed to absorb full damage
			float ArmorNeeded = Damage * Armor::ABSORPTION_RATIO;

			if (CurrentArmor >= ArmorNeeded) // armor can fully absorb, no break
			{
				CurrentArmor -= ArmorNeeded;
				CurrentHealth -= Damage * HealthRatio;

				RemainingHealth = CurrentHealth;
				RemainingArmor = CurrentArmor;
			}
			else // armor breaks mid-hit
			{
				float AbsorbedDamage = CurrentArmor / Armor::ABSORPTION_RATIO;
				float RemainingDamage = Damage - AbsorbedDamage;

				CurrentHealth -= AbsorbedDamage * HealthRatio; // partial absorption
				CurrentHealth -= RemainingDamage;
                GrantArmor(EArmorType::None);

				RemainingHealth = CurrentHealth;
				RemainingArmor = CurrentArmor;
			}
		}
		else
		{
			CurrentHealth -= Damage;

			RemainingHealth = CurrentHealth;
			RemainingArmor = CurrentArmor;
		}

		CurrentHealth = Math::Max(CurrentHealth, 0);

		if (CurrentHealth <= 0)
		{
			Death();
		}
	}

	void Death(FDeathInfo DeathInfo = FDeathInfo())
    {
        OnDeath.Broadcast(DeathInfo);
        BP_Death(DeathInfo);
    }

    UFUNCTION(BlueprintEvent, Category = "Dummy | Health", DisplayName = "Death")
    void BP_Death(FDeathInfo DeathInfo)
    {}
}