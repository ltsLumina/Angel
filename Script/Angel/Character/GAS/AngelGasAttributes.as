namespace UAngelGASAttributes
{
	const FName HealthName = n"Health";
	const FName MaxHealthName = n"MaxHealth";
	const FName ArmorName = n"Armor";
	const FName MaxArmorName = n"MaxArmor";

	const FName Ability_C_UsesName = n"Ability_C_Uses";
	const FName Ability_Q_UsesName = n"Ability_Q_Uses";
	const FName Ability_E_UsesName = n"Ability_E_Uses";
	const FName Ability_X_UsesName = n"Ability_X_Uses";

	const FName ResourceName = n"Resource"; // Viper: Toxin Fuel
}

event void FOnHealthChangedEvent(float32 NewHealth, float32 OldHealth);

class UAngelGASAttributes : UAngelscriptAttributeSet
{
	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes")
	FAngelscriptGameplayAttributeData Health;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes")
	FAngelscriptGameplayAttributeData MaxHealth;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes")
	FAngelscriptGameplayAttributeData Armor;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes")
	FAngelscriptGameplayAttributeData MaxArmor;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_C_Uses;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_Q_Uses;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_E_Uses;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_X_Uses;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Resource")
	FAngelscriptGameplayAttributeData Resource; // Viper: Toxin Fuel

	UAngelGASAttributes()
	{
		Health.Initialize(100.0f);
		MaxHealth.Initialize(100.0f);
		Armor.Initialize(50.0f);
		MaxArmor.Initialize(50.0f);

		Ability_C_Uses.Initialize(3);
		Ability_Q_Uses.Initialize(3);
		Ability_E_Uses.Initialize(3);
		Ability_X_Uses.Initialize(1);

		Resource.Initialize(100.0f); // Viper: Toxin Fuel
	}

	UFUNCTION(BlueprintOverride)
	void PreAttributeChange(FGameplayAttribute Attribute, float32& NewValue)
	{
		if (Attribute.AttributeName == UAngelGASAttributes::HealthName)
		{
			NewValue = Math::Clamp(NewValue, 0.0f, MaxHealth.BaseValue);
		}
		else if (Attribute.AttributeName == UAngelGASAttributes::ArmorName)
		{
			NewValue = Math::Clamp(NewValue, 0.0f, MaxArmor.BaseValue);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PostAttributeChange(FGameplayAttribute Attribute, float OldValue, float NewValue)
	{
		if (Attribute.AttributeName == UAngelGASAttributes::HealthName)
		{
			Health.SetBaseValue(Math::Clamp(NewValue, 0.0f, MaxHealth.BaseValue));
		}
		else if (Attribute.AttributeName == UAngelGASAttributes::ArmorName)
		{
			Armor.SetBaseValue(Math::Clamp(NewValue, 0.0f, MaxArmor.BaseValue));
		}
	}

	UFUNCTION(BlueprintOverride)
	void PostGameplayEffectExecute(FGameplayEffectSpec EffectSpec,
	                               FGameplayModifierEvaluatedData& EvaluatedData,
	                               UAngelscriptAbilitySystemComponent AbilitySystemComponent)
	{
		if (EvaluatedData.Attribute.AttributeName == UAngelGASAttributes::HealthName)
		{
			Health.SetCurrentValue(Health.GetCurrentValue());

			Agent.BP_TookDamage(-1, -1);

			if (Agent.GetHealthAttribute() <= 0)
			{
				Agent.Death();
			}
		}
		else if (EvaluatedData.Attribute.AttributeName == UAngelGASAttributes::ArmorName)
		{
			Armor.SetCurrentValue(Armor.GetCurrentValue());
		}
	}

	AAngelAgent GetAgent() property
	{
		return Cast<AAngelAgent>(GetOwningActor());
	}

	float GetAbilityUses(EAbility Ability)
	{
		switch (Ability)
		{
			case EAbility::Basic_C:
				return Ability_C_Uses.GetBaseValue();
			case EAbility::Basic_Q:
				return Ability_Q_Uses.GetBaseValue();
			case EAbility::Signature_E:
				return Ability_E_Uses.GetBaseValue();
			case EAbility::Ultimate_X:
				return Ability_X_Uses.GetBaseValue();
		}
	}
}