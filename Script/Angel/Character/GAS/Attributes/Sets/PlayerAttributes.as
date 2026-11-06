namespace UPlayerAttributes
{
	
}

class UPlayerAttributes : UCharacterAttributes
{
	

	UPlayerAttributes()
	{
		
	}

	// #endregion

	// ORDER OF EXECUTION AND RESPONSIBILITY
	// 1. | PRE ATTRIBUTE CHANGE: Perform clamping for ASC to use.
	// 2. | POST GAMEPLAY EFFECT EXECUTE: Update value to new clamped non-zero value, perform post-execute effects such as target death.
	// 3. | POST ATTRIBUTE CHANGE: Broadcast attribute update to listeners.

	UFUNCTION(BlueprintOverride)
	void PreAttributeChange(FGameplayAttribute Attribute, float32& NewValue) override
	{
		Super::PreAttributeChange(Attribute, NewValue);
	}

	UFUNCTION(BlueprintOverride)
	void PostAttributeChange(FGameplayAttribute Attribute, float OldValue, float NewValue) override
	{
		Super::PostAttributeChange(Attribute, OldValue, NewValue);
	}

	UFUNCTION(BlueprintOverride)
	void PostGameplayEffectExecute(FGameplayEffectSpec EffectSpec,
								   FGameplayModifierEvaluatedData& EvaluatedData,
								   UAngelscriptAbilitySystemComponent AbilitySystemComponent) override
	{
		Super::PostGameplayEffectExecute(EffectSpec, EvaluatedData, AbilitySystemComponent);
	}
}