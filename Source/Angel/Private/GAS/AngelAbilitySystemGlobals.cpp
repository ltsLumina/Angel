// Copyright 2020 Dan Kestranek.

#include "GAS/AngelAbilitySystemGlobals.h"
#include "GAS/AngelAbilityTypes.h"

UAngelAbilitySystemGlobals::UAngelAbilitySystemGlobals()
{

}

FGameplayEffectContext* UAngelAbilitySystemGlobals::AllocGameplayEffectContext() const
{
	return new FAngelGameplayEffectContext();
}

void UAngelAbilitySystemGlobals::InitGlobalTags()
{
	Super::InitGlobalTags();

	DeadTag = FGameplayTag::RequestGameplayTag("State.Dead");
}