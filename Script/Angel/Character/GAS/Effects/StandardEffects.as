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

class UGE_Restore_Armor : UAngelGameplayEffect
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