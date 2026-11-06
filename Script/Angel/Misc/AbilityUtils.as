
/**
 * @return The CURRENT value of the `UGenericGunComponent`'s Damage attribute.
 */
UFUNCTION(Category = "Ability|Attribute", BlueprintPure, Meta = (WorldContext = "Ability"))
mixin float GetWeaponDamage(UAngelscriptGameplayAbility Ability, bool&out SuccessfullyFoundAttribute)
{
	check(Ability.AbilitySystemComponentFromActorInfo != nullptr);

	float Result = AbilitySystem::GetFloatAttributeFromAbilitySystemComponent(
		Ability.AbilitySystemComponentFromActorInfo,
		UAngelscriptAttributeSet::GetGameplayAttribute(UGenericGunAttributes, UGenericGunAttributes::DamageName),
		SuccessfullyFoundAttribute);

	ThrowIf(Ability.AbilitySystemComponentFromActorInfo == nullptr, f"No AbilitySystemComponent is registered to {Ability.GetName()}'s ActorInfo!");
	ThrowIf(!SuccessfullyFoundAttribute, f"No attribute of type 'UGenericGunAttributes::DamageName' was found on {Ability.AbilitySystemComponentFromActorInfo}");
	return Result;
}