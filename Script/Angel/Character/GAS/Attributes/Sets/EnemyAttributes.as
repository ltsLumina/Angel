namespace UEnemyAttributes
{
	const FName AmmoName = n"Ammo";
	const FName MaxAmmoName = n"MaxAmmo";
	const FName DamageName = n"Damage";
}


class UEnemyAttributes : UCharacterAttributes
{
	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Ammo, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData Ammo;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxAmmo, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData MaxAmmo;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Damage, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData Damage;

	UEnemyAttributes()
	{
		Health.Initialize(100.0f);
		MaxHealth.Initialize(100.0f);
		Shield.Initialize(0.f);
		MaxShield.Initialize(0.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_Ammo(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_MaxAmmo(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_Damage(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

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

	/**
	 * CALLED ON THE SERVER ONLY!!
	 * ALSO ONLY CALLED ON BASE VALUE CHANGES, NOT CURRENT VALUE!
	 */
	UFUNCTION(BlueprintOverride)
	void PostGameplayEffectExecute(FGameplayEffectSpec EffectSpec,
								   FGameplayModifierEvaluatedData& EvaluatedData,
								   UAngelscriptAbilitySystemComponent AbilitySystemComponent) override
	{
		Super::PostGameplayEffectExecute(EffectSpec, EvaluatedData, AbilitySystemComponent);

		if (EvaluatedData.Attribute.AttributeName == UCharacterAttributes::HealthName)
		{
			auto Causer = Cast<AScriptPondHero>(EffectSpec.Context.EffectCauser);
			EnemyBase.ThreatTable.Add(Causer, Math::Abs(EvaluatedData.Magnitude));

			// EffectSpec = the effect that dealt damage
			// EvaluatedData = magnitude of the damage
			// AbilitySystemComponent = the ASC of the enemy that was hurt (this enemy)
		}
	}

	AScriptEnemyBase GetEnemyBase() property
	{
		return Cast<AScriptEnemyBase>(GetOwningActor());
	}
}