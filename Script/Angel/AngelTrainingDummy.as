class AAngelTrainingDummy : ACharacter
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(Category = "Dummy | Health", VisibleAnywhere, BlueprintReadOnly, Meta = (ClampMin = "0.0", UIMin = "0.0", ClampMax = "100.0", UIMax = "100.0"))
	float TotalHealth = 150;

	UPROPERTY(Category = "Dummy | Health", Meta = (ClampMin = "0.0", UIMin = "0.0", ClampMax = "100.0", UIMax = "100.0"))
	float Health = 100;

	UPROPERTY(Category = "Dummy | Armor", Meta = (ClampMin = "0.0", UIMin = "0.0", ClampMax = "100.0", UIMax = "100.0"))
	float Armor = 50;

    UFUNCTION(BlueprintPure, Category = "Dummy | Armor")
    bool HasArmor() const { return Armor > 0; }

	/**
	 * The ratio of damage absorbed by the armor versus health.
	 * For example, an absorptionRatio of 0.66 means that 66% of incoming damage is absorbed by the armor,
	 * while the remaining 34% is applied to health.
	 */
	UPROPERTY(Category = "Dummy | Armor", EditDefaultsOnly, Meta = (ClampMin = "0.0", UIMin = "0.0", ClampMax = "1.0", UIMax = "1.0"))
	float AbsorptionRatio = 0.66f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        Refresh();
	}

	UFUNCTION(Category = "Damage")
	void TakeDamage(float Damage, float&out RemainingHealth, float&out RemainingArmor)
	{
		const float HealthRatio = 1 - AbsorptionRatio;

		if (Armor > 0)
		{
			// How much armor is needed to absorb full damage
			float ArmorNeeded = Damage * AbsorptionRatio;

			if (Armor >= ArmorNeeded)
			{
				Armor -= ArmorNeeded;
				Health -= Damage * HealthRatio;

				RemainingHealth = Health;
				RemainingArmor = Armor;
			}
			else // armor breaks mid-hit
			{
				float AbsorbedDamage = Armor / AbsorptionRatio;
				float RemainingDamage = Damage - AbsorbedDamage;

				Health -= AbsorbedDamage * HealthRatio; // partial absorption
				Health -= RemainingDamage;
				Armor = 0;

				RemainingHealth = Health;
				RemainingArmor = Armor;
			}
		}
		else
		{
			Health -= Damage;

			RemainingHealth = Health;
			RemainingArmor = Armor;
		}

		Health = Math::Max(Health, 0);

        if (Health <= 0)
        {
            Death();
        }
	}

    UFUNCTION(BlueprintEvent, Category = "Dummy | Health")
    void Death() { }

    UFUNCTION(Category = "Dummy | Health")
    void Heal(float Amount)
    {
        Health = Math::Min(Health + Amount, TotalHealth);
    }

    UFUNCTION(Category = "Dummy | Armor")
    void RestoreArmor(float Amount)
    {
        Armor = Math::Min(Armor + Amount, 100);
    }

    UFUNCTION(Category = "Dummy | Health")
    void Refresh()
    {
        Health = 100;
        Armor = 50;
        TotalHealth = Health + Armor;
    }
};