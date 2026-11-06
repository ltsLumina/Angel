class UGEXC_HawkmoonCalculation : UGEXC_DamageCalculationBase
{
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UHawkmoonAttributes, UHawkmoonAttributes::PrecisionHitsName, EGameplayEffectAttributeCaptureSource::Source, false));
	
	UFUNCTION(BlueprintOverride)
	void Execute(FGameplayEffectCustomExecutionParameters ExecutionParams,
				 FGameplayEffectCustomExecutionOutput& OutExecutionOutput) const
	{
		Super::Execute(ExecutionParams, OutExecutionOutput);
	}

	/**
	 * Computes the final damage value combining base damage with Hawkmoon precision hit bonus.
	 * Only applies bonus if this is the last bullet in the magazine.
	 * @return The final damage value to be applied to health and shield.
	 */
	float32 GetDamageMagnitude(FGameplayEffectCustomExecutionParameters ExecutionParams) const override
	{
		float32 BaseDamage = GetWeaponDamageWithPrecision(ExecutionParams);

		bool bIsLastBullet = ExecutionParams.OwningSpec.CapturedSourceTags.AggregatedTags.HasTagExact(GameplayTags::State_Ammo_Empty);

		// precision hits ignored, except if its the last bullet
		if (ExecutionParams.GetOwningSpec().Context.IsPrecisionHit && !bIsLastBullet)
			return BaseDamage;

		// TODO: SHOULD BE REFACTORED INTO 'Magnificent Howl' WEAPON ENCHANT!!

		float32 PrecisionHitStack = GetCapturedAttributeValue(ExecutionParams, UHawkmoonAttributes, UHawkmoonAttributes::PrecisionHitsName, EGameplayEffectAttributeCaptureSource::Source);
		float32 ClampedPrecisionHits = float32(Math::Max(PrecisionHitStack, 1));

		// NEW HAWKMOON: Deals more non-precision damage with each precision hit.

		const float32 HAWKMOON_FACTOR = 0.05f; // 5% more body damage per crit
		float32 BonusMultiplier = (1.0f + (ClampedPrecisionHits * HAWKMOON_FACTOR));
		float32 FinalDamage = ApplyDamageMultiplier(BaseDamage, BonusMultiplier);

		Log(n"Hawkmoon", f"{BaseDamage=}\n{PrecisionHitStack=}\n{BonusMultiplier=}\n{FinalDamage=}");
		return FinalDamage;
	}
}