namespace UCharacterAttributes
{
	const FName HealthName = n"Health";
	const FName MaxHealthName = n"MaxHealth";
	const FName ShieldName = n"Shield";
	const FName MaxShieldName = n"MaxShield";
	const FName MoveSpeedName = n"MoveSpeed";
	const FName MaxMoveSpeedName = n"MaxMoveSpeed";

	const float SPEED_CAP = 500 * 4;
}

class UCharacterAttributes : UHealthAttributes
{
	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MoveSpeed, Category = "Character Attributes")
	FAngelscriptGameplayAttributeData MoveSpeed;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxMoveSpeed, Category = "Character Attributes")
	FAngelscriptGameplayAttributeData MaxMoveSpeed;

	UCharacterAttributes()
	{
		MoveSpeed.Initialize(650.0f);
		MaxMoveSpeed.Initialize(650.0f);
	}

	// #region On_Rep
	UFUNCTION(NotBlueprintCallable)
	void OnRep_MoveSpeed(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_MaxMoveSpeed(FAngelscriptGameplayAttributeData& OldAttributeData)
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

		if (Attribute.AttributeName == UCharacterAttributes::MoveSpeedName)
		{
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, MaxMoveSpeed.CurrentValue);
		}
		else if (Attribute.AttributeName == UCharacterAttributes::MaxMoveSpeedName)
		{
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, UCharacterAttributes::SPEED_CAP);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PostAttributeChange(FGameplayAttribute Attribute, float OldValue, float NewValue) override
	{
		Super::PostAttributeChange(Attribute, OldValue, NewValue);

		if (Attribute.AttributeName == UCharacterAttributes::HealthName)
		{
			// Health.SetBaseValue(Math::Clamp(NewValue, 0.0f, MaxHealth.BaseValue));
		}
		else if (Attribute.AttributeName == UCharacterAttributes::ShieldName)
		{
			// Shield.SetBaseValue(Math::Clamp(NewValue, 0.0f, MaxShield.BaseValue));

			// bool WasShieldBreak = NewValue <= OldValue;
			//  if (WasShieldBreak) AbilitySystem::SendGameplayEventToActor()
		}
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
			auto Char = Cast<AAngelAgent>(AbilitySystemComponent.Avatar);

			if (AbilitySystemComponent.HasGameplayTag(GameplayTags::State_Dead))
				return;

			if (Health.CurrentValue <= 0)
			{
				Char.Death();
			}
		}
	}
}