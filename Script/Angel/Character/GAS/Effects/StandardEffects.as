class UGE_Damage_Health : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo HealthModifier;
	default HealthModifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::HealthName);
	default HealthModifier.ModifierOp = EGameplayModOp::Additive;
	default HealthModifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default HealthModifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Health;

	default Modifiers.Add(HealthModifier);
};

class UGE_Damage_Armor : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo HealthModifier;
	default HealthModifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::ArmorName);
	default HealthModifier.ModifierOp = EGameplayModOp::Additive;
	default HealthModifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default HealthModifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Armor;

	default Modifiers.Add(HealthModifier);
};

class UGE_Restore_Health : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo HealthModifier;
	default HealthModifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::HealthName);
	default HealthModifier.ModifierOp = EGameplayModOp::Additive;
	default HealthModifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default HealthModifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Health;

	default Modifiers.Add(HealthModifier);
};

class UGE_Restore_Armor : UAngelGameplayEffect
{
	default DurationPolicy = EGameplayEffectDurationType::Instant;
	default StackingType = EGameplayEffectStackingType::None;

	FGameplayModifierInfo HealthModifier;
	default HealthModifier.Attribute = UAngelscriptAttributeSet::GetGameplayAttribute(UAngelGASAttributes, UAngelGASAttributes::ArmorName);
	default HealthModifier.ModifierOp = EGameplayModOp::Additive;
	default HealthModifier.ModifierMagnitude.MagnitudeCalculationType = EGameplayEffectMagnitudeCalculation::SetByCaller;
	default HealthModifier.ModifierMagnitude.SetByCallerMagnitude.DataTag = GameplayTags::Data_Damage_Armor;

	default Modifiers.Add(HealthModifier);
};