// Copyright 2020 Dan Kestranek.

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystemGlobals.h"
#include "AngelAbilitySystemGlobals.generated.h"

/**
 * Child class of UAbilitySystemGlobals.
 * Do not try to get a reference to this or call into it during constructors of other UObjects. It will crash in packaged games.
 */
UCLASS()
class ANGEL_API UAngelAbilitySystemGlobals : public UAbilitySystemGlobals
{
	GENERATED_BODY()
	
public:
	UAngelAbilitySystemGlobals();

	/**
	* Cache commonly used tags here. This has the benefit of one place to set the tag FName in case tag names change and
	* the function call into UAngelAbilitySystemGlobals::AngelGet() is cheaper than calling FGameplayTag::RequestGameplayTag().
	* Classes can access them by UAngelAbilitySystemGlobals::AngelGet().DeadTag
	* We're not using this in this sample project (classes are manually caching in their constructors), but it's here as a reference.
	*/

	UPROPERTY()
	FGameplayTag DeadTag;

	UPROPERTY()
	FGameplayTag DBNO_Tag;

	// UPROPERTY()
	// FGameplayTag InteractingTag;
	//
	// UPROPERTY()
	// FGameplayTag InteractingRemovalTag;

	static UAngelAbilitySystemGlobals& AngelGet()
	{
		return dynamic_cast<UAngelAbilitySystemGlobals&>(Get());
	}

	/** Should allocate a project specific GameplayEffectContext struct. Caller is responsible for deallocation */
	virtual FGameplayEffectContext* AllocGameplayEffectContext() const override;

	virtual void InitGlobalTags() override;
};