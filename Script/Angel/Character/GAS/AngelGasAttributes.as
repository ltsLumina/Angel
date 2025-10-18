namespace UAngelGASAttributes
{
	const FName HealthName = n"Health";
	const FName ArmorName = n"Armor";

	const FName Ability_C_ChargesName = n"Ability_C_Charges";
	const FName Ability_Q_ChargesName = n"Ability_Q_Charges";
	const FName Ability_E_ChargesName = n"Ability_E_Charges";
	const FName Ability_X_ChargesName = n"Ability_X_Charges";

	const FName ResourceName = n"Resource"; // Viper: Toxin Fuel

	FAngelscriptGameplayAttributeData GetHealthAttribute()
	{
		return UAngelGASAttributes().Health;
	}
}

event void FOnHealthChangedEvent(float32 NewHealth, float32 OldHealth);

class UAngelGASAttributes : UAngelscriptAttributeSet
{
	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes")
	FAngelscriptGameplayAttributeData Health;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes")
	FAngelscriptGameplayAttributeData Armor;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_C_Charges;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_Q_Charges;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_E_Charges;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Ability")
	FAngelscriptGameplayAttributeData Ability_X_Charges;

	UPROPERTY(BlueprintReadOnly, Category = "Agent Attributes | Resource")
	FAngelscriptGameplayAttributeData Resource; // Viper: Toxin Fuel

	UPROPERTY(Category = "Events")
	FOnHealthChangedEvent OnHealthChanged;

	UAngelGASAttributes()
	{
		Health.Initialize(100.0f);
		Armor.Initialize(Armor::HEAVY_ARMOR);

		Ability_C_Charges.Initialize(2);
		Ability_Q_Charges.Initialize(1);
		Ability_E_Charges.Initialize(1);
		Ability_X_Charges.Initialize(1);

		Resource.Initialize(100.0f); // Viper: Toxin Fuel
	}

	UFUNCTION(BlueprintOverride)
	void PreAttributeChange(FGameplayAttribute Attribute, float32& NewValue)
	{
		if (Attribute.AttributeName == UAngelGASAttributes::HealthName)
		{
			if (Agent.AbilitySystem.HasGameplayTag(GameplayTags::Character_Status_Vulnerable))
			{
				NewValue *= 1.5f; // take 50% more damage when vulnerable
			}

			NewValue = Math::Clamp(NewValue, 0.0f, Health.BaseValue);
				OnHealthChanged.Broadcast(NewValue, Health.GetCurrentValue());
		}
		else if (Attribute.AttributeName == UAngelGASAttributes::ArmorName)
		{
			if (Agent.AbilitySystem.HasGameplayTag(GameplayTags::Character_Status_Vulnerable))
			{
				NewValue *= 1.5f; // take 50% more damage when vulnerable
			}

			NewValue = Math::Clamp(NewValue, 0.0f, Armor.BaseValue);
		}
	}

	AAngelAgent GetAgent() property
	{
		return Cast<AAngelAgent>(GetOwningActor());
	}
}