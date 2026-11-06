namespace UPlayerAttributes
{
	const FName ReviveTokenName = n"ReviveTokens";
	const FName ShotsFiredName = n"ShotsFired";
}

class UPlayerAttributes : UCharacterAttributes
{
	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_ReviveTokens, Category = "Hero Attributes")
	FAngelscriptGameplayAttributeData ReviveTokens;

	UPlayerAttributes()
	{
		ReviveTokens.Initialize(99.0f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_ReviveTokens(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
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