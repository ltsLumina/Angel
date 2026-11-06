class UGEXC_BastionCalculation : UGEXC_DamageCalculationBase
{
	//default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UBastionAttributes, UBastionAttributes::PrecisionHitsName, EGameplayEffectAttributeCaptureSource::Source, false));
	
	UFUNCTION(BlueprintOverride)
	void Execute(FGameplayEffectCustomExecutionParameters ExecutionParams,
				 FGameplayEffectCustomExecutionOutput& OutExecutionOutput) const
	{
		Super::Execute(ExecutionParams, OutExecutionOutput);
	}

	float32 GetDamageMagnitude(FGameplayEffectCustomExecutionParameters ExecutionParams) const override
	{
		float32 BaseDamage = GetWeaponDamageWithPrecision(ExecutionParams);

		Log(n"Bastion", f"{BaseDamage=}");
		return BaseDamage;
	}
}