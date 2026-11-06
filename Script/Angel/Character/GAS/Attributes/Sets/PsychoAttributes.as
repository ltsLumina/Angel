namespace UPsychoAttributes
{
	const FName DashChargesName = n"DashCharges";
	const FName MaxDashChargesName = n"MaxDashCharges";
}

class UPsychoAttributes : UAngelscriptAttributeSet
{
	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_DashCharges, Category = "Hero Attributes")
	FAngelscriptGameplayAttributeData DashCharges;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxDashCharges, Category = "Hero Attributes")
	FAngelscriptGameplayAttributeData MaxDashCharges;

	UPsychoAttributes()
	{
        DashCharges.Initialize(2.f);
        MaxDashCharges.Initialize(2.f);
	}

	// #region On_Rep
	UFUNCTION(NotBlueprintCallable)
	void OnRep_DashCharges(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_MaxDashCharges(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	// #endregion

	// ORDER OF EXECUTION AND RESPONSIBILITY
	// 1. | PRE ATTRIBUTE CHANGE: Perform clamping for ASC to use.
	// 2. | POST GAMEPLAY EFFECT EXECUTE: Update value to new clamped non-zero value, perform post-execute effects such as target death.
	// 3. | POST ATTRIBUTE CHANGE: Broadcast attribute update to listeners.

	UFUNCTION(BlueprintOverride)
	void PreAttributeChange(FGameplayAttribute Attribute, float32& NewValue)
	{

	}

	UFUNCTION(BlueprintOverride)
	void PostAttributeChange(FGameplayAttribute Attribute, float OldValue, float NewValue)
	{

	}

	/**
	 * CALLED ON THE SERVER ONLY!!
	 * ALSO ONLY CALLED ON BASE VALUE CHANGES, NOT CURRENT VALUE!
	 */
	UFUNCTION(BlueprintOverride)
	void PostGameplayEffectExecute(FGameplayEffectSpec EffectSpec,
								   FGameplayModifierEvaluatedData& EvaluatedData,
								   UAngelscriptAbilitySystemComponent AbilitySystemComponent)
{
	}

	AScriptEnemyBase GetEnemyBase() property
	{
		return Cast<AScriptEnemyBase>(GetOwningActor());
	}

}