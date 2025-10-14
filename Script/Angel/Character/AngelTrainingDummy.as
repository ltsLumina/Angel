event void OnDeath();

class AAngelTrainingDummy : ACharacter
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(Category = "Dummy | Health", VisibleAnywhere, BlueprintReadOnly, Meta = (UIMin = "0.0", , UIMax = "100.0"))
	float TotalHealth = 150;

	UPROPERTY(Category = "Dummy | Health", Meta = (UIMin = "0.0", , UIMax = "100.0"))
	float Health = 100;

	UPROPERTY(Category = "Dummy | Armor", Meta = (UIMin = "0.0", UIMax = "50.0"))
	float Armor = 50;

	UFUNCTION(BlueprintPure, Category = "Dummy | Armor")
	bool HasArmor() const
	{
		return Armor > 0;
	}

	/**
	 * The ratio of damage absorbed by the armor versus health.
	 * For example, an absorptionRatio of 0.66 means that 66% of incoming damage is absorbed by the armor,
	 * while the remaining 34% is applied to health.
	 */
	UPROPERTY(Category = "Dummy | Armor", EditDefaultsOnly, Meta = (UIMin = "0.0", ClampMax = "1.0", UIMax = "1.0"))
	float AbsorptionRatio = 0.66f;

	UPROPERTY(Category = "Dummy", VisibleAnywhere)
	OnDeath OnDeath;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Refresh();
	}

	UFUNCTION(BlueprintOverride)
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
			OnDeath.Broadcast();
		}
	}

	UFUNCTION(BlueprintEvent, Category = "Dummy | Health")
	void Death()
	{}

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