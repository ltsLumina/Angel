class UGE_Damage_Health : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::HealthName);
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default Modifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Health;

	default Modifiers.Add(Modifier);
};

class UGE_Damage_Armor : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::ArmorName);
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default Modifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Armor;

	default Modifiers.Add(Modifier);
};

class UGE_Restore_Health : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::HealthName);
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default Modifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Health;

	default Modifiers.Add(Modifier);
};

class UGE_Override_Armor : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::ArmorName);
	default Modifier.ModifierOp = EGameplayModOp::Override;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default Modifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Armor;

	default Modifiers.Add(Modifier);
};

class UGE_Use_Ability_C : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Basic_C));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = -1.0f;

	default Modifiers.Add(Modifier);
};

class UGE_Use_Ability_Q : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Basic_Q));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = -1.0f;

	default Modifiers.Add(Modifier);
};

class UGE_Use_Ability_E : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Signature_E));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = -1.0f;

	default Modifiers.Add(Modifier);
};

class UGE_Use_Ability_X : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Ultimate_X));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = -1.0f;

	default Modifiers.Add(Modifier);
};

class UGE_Grant_Ability_C : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Basic_C));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = 1.0f;

	default Modifiers.Add(Modifier);
};

class UGE_Grant_Ability_Q : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Basic_Q));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = 1.0f;

	default Modifiers.Add(Modifier);
};

class UGE_Grant_Ability_E : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Signature_E));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = 1.0f;

	default Modifiers.Add(Modifier);
};

class UGE_Grant_Ability_X : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo Modifier;
	default Modifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, GetAbilityName(EAbility::Ultimate_X));
	default Modifier.ModifierOp = EGameplayModOp::Additive;
	default Modifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::ScalableFloat;
	default Modifier.ModifierMagnitude.ScalableFloatMagnitude.Value = 1.0f;

	default Modifiers.Add(Modifier);
};

/**
 * Helper function to get the ability attribute name from the ability type enum.
 * Not really necessary, but it looks nicer in the gameplay effect classes.
 * @param AbilityType The ability type enum.
 * @return The corresponding ability attribute name.
 */
FName GetAbilityName(EAbility AbilityType)
{
	switch (AbilityType)
	{
		case EAbility::Basic_C:
			return UAngelGASAttributes::Ability_C_UsesName;
		case EAbility::Basic_Q:
			return UAngelGASAttributes::Ability_Q_UsesName;
		case EAbility::Signature_E:
			return UAngelGASAttributes::Ability_E_UsesName;
		case EAbility::Ultimate_X:
			return UAngelGASAttributes::Ability_X_UsesName;
		default:
			return n"";
	}
}