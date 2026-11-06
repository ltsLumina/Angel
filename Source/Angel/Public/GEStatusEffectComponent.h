// Copyright 'Team PONDAGON' - All rights reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameplayEffectComponent.h"
#include "AngelHUDBase.h"
#include "GEStatusEffectComponent.generated.h"

class UAngelscriptGASAbility;
/**
 * 
 */
UCLASS(DisplayName="Add Status Effect to HUD")
class ANGEL_API UGEStatusEffectComponent : public UGameplayEffectComponent
{
	GENERATED_BODY()
	
	UPROPERTY(EditDefaultsOnly, Category = "Enchantment", meta=(AllowedClasses="/Script/Angelscript.WeaponEnchantment"))
	TSubclassOf<UAngelscriptGASAbility> EnchantmentClass;
	
	UPROPERTY(EditDefaultsOnly, Category = "Enchantment")
	EStatusEffectType EffectType = EStatusEffectType::Buff;
	
public:
	virtual bool OnActiveGameplayEffectAdded(FActiveGameplayEffectsContainer& ActiveGEContainer, FActiveGameplayEffect& ActiveGE) const override;
	
	virtual bool CanGameplayEffectApply(const FActiveGameplayEffectsContainer& ActiveGEContainer, const FGameplayEffectSpec& GESpec) const override;
};
