// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayEffectTypes.h"
#include "AngelAbilityTypes.h"

#include "Kismet/BlueprintFunctionLibrary.h"
#include "AngelAbilityLibrary.generated.h"

/**
 * 
 */
UCLASS()
class ANGEL_API UAngelAbilityLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
	// UFUNCTION(BlueprintPure, Category = "AngelAbilityLibrary | Effects")
	// static bool GetIsFatalHit(const FGameplayEffectContextHandle& Handle);

	UFUNCTION(BlueprintPure, Category = "AngelAbilityLibrary | Effects")
	static bool GetIsPrecisionHit(const FGameplayEffectContextHandle& Handle);

	UFUNCTION(BlueprintPure, Category = "AngelAbilityLibrary | Effects")
	static EInvulnerabilityType GetInvulnerabilityType(const FGameplayEffectContextHandle& Handle);
	
	UFUNCTION(BlueprintPure, Category = "AngelAbilityLibrary | Effects")
	static EDamageType GetDamageType(const FGameplayEffectContextHandle& Handle);

	UFUNCTION(BlueprintPure, Category = "AngelAbilityLibrary | Effects")
	static EBodyPart GetBodyPart(const FGameplayEffectContextHandle& EffectContext);

	// UFUNCTION(BlueprintPure, Category = "AngelAbilityLibrary | Effects")
	// static FDamageResult GetDamageResult(const FGameplayEffectContextHandle& Handle);
	
	////////////////////// SETTERS ////////////////////////

	UFUNCTION(BlueprintCallable, Category = "AngelAbilityLibrary | Effects")
	static void SetIsPrecisionHit(UPARAM(ref) FGameplayEffectContextHandle& Handle, bool IsPrecisionHit);

	//UFUNCTION(Category = "AngelAbilityLibrary | Effects")
	//static void SetIsFatalHit(UPARAM(ref) FGameplayEffectContextHandle& Handle, bool IsFatalHit);

	UFUNCTION(Category = "AngelAbilityLibrary | Effects")
	static void SetInvulnerabilityType(UPARAM(ref) FGameplayEffectContextHandle& Handle, EInvulnerabilityType InvulnerabilityType);
	
	UFUNCTION(Category = "AngelAbilityLibrary | Effects")
	static void SetDamageType(UPARAM(ref) FGameplayEffectContextHandle& Handle, EDamageType DamageType);

	UFUNCTION(BlueprintCallable, Category = "AngelAbilityLibrary | Effects")
	static void SetBodyPart(FGameplayEffectContextHandle& EffectContext, EBodyPart BodyPart);

	// UFUNCTION(Category = "AngelAbilityLibrary | Effects")
	// static void SetDamageResult(UPARAM(ref) FGameplayEffectContextHandle& Handle, const FDamageResult& DamageResult);
};
