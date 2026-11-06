// Copyright 'Team PONDAGON' - All rights reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"

#include "AngelHUDBase.generated.h"

UENUM(BlueprintType)
enum class EStatusEffectType : uint8
{
	Buff = 0,
	Debuff = 1,
	Neutral = 2,
	Cooldown = 3
};

struct FActiveGameplayEffectHandle;
class UAngelscriptGASAbility;

/**
 * 
 */
UCLASS()
class ANGEL_API AAngelHUDBase : public AHUD
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintImplementableEvent, Category = "HUD")
	void NotifyEffectApplied(const APlayerController* PlayerController, const FActiveGameplayEffectHandle Handle, TSubclassOf<UAngelscriptGASAbility> EnchantmentClass, EStatusEffectType EffectType);
};
