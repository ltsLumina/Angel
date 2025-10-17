namespace UAngelGASAttributes
{
	const FName HealthName = n"Health";
	const FName ArmorName = n"Armor";
}

event void FOnHealthChangedEvent(float32 NewHealth, float32 OldHealth);

class UAngelGASAttributes : UAngelscriptAttributeSet
{
	UPROPERTY(BlueprintReadOnly, Category = "Pawn Attributes")
	FAngelscriptGameplayAttributeData Health;

	UPROPERTY(BlueprintReadOnly, Category = "Pawn Attributes")
	FAngelscriptGameplayAttributeData Armor;

	UPROPERTY(Category = "Events")
	FOnHealthChangedEvent OnHealthChanged;

	UAngelGASAttributes()
	{
		Health.Initialize(100.0f);
		Armor.Initialize(Armor::NO_ARMOR);
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