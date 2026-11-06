/**
 * Izanagi calculation: Deals weapon damage with an exponential bonus based on charge.
 * Formula: BaseDamage * (1 + BaseDamage * Charge * IZANAGI_FACTOR)
 * Higher charge = exponentially higher damage.
 */
class UGEXC_IzanagiCalculation : UGEXC_DamageCalculationBase
{
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UGenericGunAttributes, UGenericGunAttributes::DamageName, EGameplayEffectAttributeCaptureSource::Source, true));
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UIzanagiAttributes, UIzanagiAttributes::ChargeName, EGameplayEffectAttributeCaptureSource::Source, true));
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UHealthAttributes, UHealthAttributes::HealthName, EGameplayEffectAttributeCaptureSource::Target, true));
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UHealthAttributes, UHealthAttributes::ShieldName, EGameplayEffectAttributeCaptureSource::Target, true));

	UFUNCTION(BlueprintOverride)
	void Execute(FGameplayEffectCustomExecutionParameters ExecutionParams,
				 FGameplayEffectCustomExecutionOutput& OutExecutionOutput) const
	{
		Super::Execute(ExecutionParams, OutExecutionOutput);
	}

	/**
	 * Computes the final damage value combining base damage with Izanagi charge-based bonus.
	 * @return The final damage value to be applied to health and shield.
	 */
	float32 GetDamageMagnitude(FGameplayEffectCustomExecutionParameters ExecutionParams) const override
	{
		// Get base damage with precision multiplier already applied
		float32 BaseDamage = GetWeaponDamageWithPrecision(ExecutionParams);

		// Capture charge value for bonus multiplier
		float32 ChargeValue = GetCapturedAttributeValue(ExecutionParams, UIzanagiAttributes, UIzanagiAttributes::ChargeName, EGameplayEffectAttributeCaptureSource::Source);

		// Izanagi bonus: Charge-based exponential scaling
		float32 IZANAGI_FACTOR = 1; 

		bool HasAltTag = ExecutionParams.OwningSpec.CapturedSourceTags.AggregatedTags.HasTagExact(GameplayTags::State_Weapon_AltFiring);
		bool HasAltBlockedTag = ExecutionParams.OwningSpec.CapturedSourceTags.AggregatedTags.HasTagExact(GameplayTags::State_Weapon_AltFireBlocked);
		bool HasAmmo = !ExecutionParams.OwningSpec.CapturedSourceTags.AggregatedTags.HasTagExact(GameplayTags::State_Ammo_Empty);
		
		if ((HasAltTag || HasAltBlockedTag) || !HasAmmo)
			IZANAGI_FACTOR = ExecutionParams.OwningSpec.Context.IsPrecisionHit ? 3.5f : 1.f;
		else
			IZANAGI_FACTOR = ExecutionParams.OwningSpec.Context.IsPrecisionHit ? 1.5f : 1.f;

		// Charge bonus is a flat additive value, independent of BaseDamage.
		// Bypasses ApplyDamageBonus so flat damage buffs don't compound into the charge scaling.
		float32 ChargeBonus = ChargeValue * IZANAGI_FACTOR;
		float32 FinalDamage = BaseDamage + ChargeBonus;

		return FinalDamage;
	}
}