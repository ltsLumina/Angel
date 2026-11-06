namespace UEnvironmentAttributes
{

}

class UEnvironmentAttributes : UHealthAttributes
{
	UEnvironmentAttributes()
	{
		Health.Initialize(50.0f);
		MaxHealth.Initialize(50.0f);
		Shield.Initialize(0.f);
		MaxShield.Initialize(0.f);
	}

	// ORDER OF EXECUTION AND RESPONSIBILITY
	// 1. | PRE ATTRIBUTE CHANGE: Perform clamping for ASC to use.
	// 2. | POST GAMEPLAY EFFECT EXECUTE: Update value to new clamped non-zero value, perform post-execute effects such as target death.
	// 3. | POST ATTRIBUTE CHANGE: Broadcast attribute update to listeners.

	UFUNCTION(BlueprintOverride)
	void PostGameplayEffectExecute(FGameplayEffectSpec EffectSpec,
								   FGameplayModifierEvaluatedData& EvaluatedData,
								   UAngelscriptAbilitySystemComponent AbilitySystemComponent) override
	{
		Super::PostGameplayEffectExecute(EffectSpec, EvaluatedData, AbilitySystemComponent);

		if (AbilitySystemComponent.HasGameplayTag(GameplayTags::State_Dead))
			return;

		if (Health.CurrentValue <= 0)
		{
			auto EnvironmentActor = Cast<AEnvironmentActor>(GetOwningActor());
			EnvironmentActor.Death();
		}
	}
}