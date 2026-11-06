namespace HealthUtils
{
	/**
	 * Calculates how incoming damage is split between health and shield.
	 * @param Damage The total incoming damage.
	 * @param DamageToHealth Output parameter for damage applied to health.
	 * @param DamageToShield Output parameter for damage applied to shield.
	 * @param AbsorptionRatio The ratio of damage the shield absorbs.
	 * @return True if DamageToHealth is greater than InCurrentHealth. (not a safe indicator of whether it will kill.)
	 * @note Although the function returns if the result *should kill*, it doesn't necessarilly mean it **will**. Use return value with caution.
	 */
	UFUNCTION(Category = "Agent | Damage")
	bool CalculateShieldSplit(float Damage, float InCurrentHealth, float InCurrentShield, float&out DamageToHealth, float&out DamageToShield, float AbsorptionRatio = 0.66f)
	{
		float CurrHealth = InCurrentHealth;
		float CurrShield = InCurrentShield;

		// initialize returned damage values
		DamageToHealth = 0;
		DamageToShield = 0;

		const float HealthRatio = 1 - AbsorptionRatio;

		if (CurrShield > 0)
		{
			// How much armor (in incoming-damage units) is needed to absorb full damage
			float ArmorNeeded = Damage * AbsorptionRatio;

			if (CurrShield >= ArmorNeeded) // armor can fully absorb, no break
			{
				// armor absorbed ArmorNeeded (portion of incoming damage)
				DamageToShield = ArmorNeeded;
				// health takes the remaining portion
				DamageToHealth = Damage * HealthRatio;

				CurrShield -= ArmorNeeded;
				CurrHealth -= DamageToHealth;
			}
			else // armor breaks mid-hit
			{
				// amount of incoming damage that was absorbed by armor
				float AbsorbedDamage = CurrShield / AbsorptionRatio;
				// remaining incoming damage that goes straight to health
				float RemainingDamage = Damage - AbsorbedDamage;

				// health takes a portion from the absorbed damage plus the remaining damage
				float HealthFromAbsorbed = AbsorbedDamage * HealthRatio;
				DamageToHealth = HealthFromAbsorbed + RemainingDamage;
				// damage portion attributed to armor (incoming-damage units)
				DamageToShield = AbsorbedDamage;

				// clamp to max value
				DamageToShield = Math::Min(DamageToShield, 999);

				CurrHealth -= DamageToHealth;
				CurrShield = 0;
			}
		}
		else
		{
			// no armor: all damage goes to health
			DamageToShield = 0;
			DamageToHealth = Damage;

			CurrHealth -= Damage;
		}

		return DamageToHealth >= InCurrentHealth;
	}
}