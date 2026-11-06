// Fill out your copyright notice in the Description page of Project Settings.

#include "GAS/AngelAbilityLibrary.h"
#include "GAS/AngelAbilityTypes.h"

// bool UAngelAbilityLibrary::GetIsFatalHit(const FGameplayEffectContextHandle& Handle)
// {
// 	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(Handle.Get());
// 	if (AngelEffectContext)
// 	{
// 		return AngelEffectContext->IsFatalHit();
// 	}
// 	return false;
// }

bool UAngelAbilityLibrary::GetIsPrecisionHit(const FGameplayEffectContextHandle& Handle)
{
	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		return AngelEffectContext->GetIsPrecisionHit();
	}
	return false;
}

EInvulnerabilityType UAngelAbilityLibrary::GetInvulnerabilityType(const FGameplayEffectContextHandle& Handle)
{
	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		return AngelEffectContext->GetInvulnerabilityType();
	}
	return EInvulnerabilityType::None;
}

EDamageType UAngelAbilityLibrary::GetDamageType(const FGameplayEffectContextHandle& Handle)
{
	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(Handle.Get());
	 if (AngelEffectContext)
	 {
		 return AngelEffectContext->GetDamageType();
	 }
	 return EDamageType::Unknown;
}

float UAngelAbilityLibrary::GetPrecisionMultiplier(const FGameplayEffectContextHandle& Handle)
{
	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		return AngelEffectContext->GetPrecisionMultiplier();
	}
	return 0.0f;
}

FGameplayTagContainer UAngelAbilityLibrary::GetAdditionalEnchantTriggers(const FGameplayEffectContextHandle& Handle)
{
	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		return AngelEffectContext->GetAdditionalEnchantTriggers();
	}
	return FGameplayTagContainer();
}

// FDamageResult UAngelAbilityLibrary::GetDamageResult(const FGameplayEffectContextHandle& Handle)
// {
// 	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(Handle.Get());
// 	if (AngelEffectContext)
// 	{
// 		return AngelEffectContext->GetDamageResult();
// 	}
// 	return FDamageResult();
// }

void UAngelAbilityLibrary::SetIsPrecisionHit(FGameplayEffectContextHandle& Handle, bool IsPrecisionHit)
{
	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		AngelEffectContext->SetIsPrecisionHit(IsPrecisionHit);
	}
}

// void UAngelAbilityLibrary::SetIsFatalHit(FGameplayEffectContextHandle& Handle, bool IsFatalHit)
// {
// 	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(Handle.Get());
// 	if (AngelEffectContext)
// 	{
// 		AngelEffectContext->SetIsFatalHit(IsFatalHit);
// 	}
// }

void UAngelAbilityLibrary::SetInvulnerabilityType(FGameplayEffectContextHandle& Handle, EInvulnerabilityType InvulnerabilityType)
{
	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		AngelEffectContext->SetInvulnerabilityType(InvulnerabilityType);
	}
}

void UAngelAbilityLibrary::SetDamageType(FGameplayEffectContextHandle& Handle, EDamageType DamageType)
{
	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		AngelEffectContext->SetDamageType(DamageType);
	}
}

void UAngelAbilityLibrary::SetPrecisionMultiplier(FGameplayEffectContextHandle& Handle, float PrecisionMultiplier)
{
	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		AngelEffectContext->SetPrecisionMultiplier(PrecisionMultiplier);
	}
}

void UAngelAbilityLibrary::SetAdditionalEnchantTriggers(FGameplayEffectContextHandle& Handle, const FGameplayTagContainer& EnchantTriggers)
{
	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(Handle.Get());
	if (AngelEffectContext)
	{
		AngelEffectContext->SetAdditionalEnchantTriggers(EnchantTriggers);
	}
}

// void UAngelAbilityLibrary::SetDamageResult(FGameplayEffectContextHandle& Handle, const FDamageResult& DamageResult)
// {
// 	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(Handle.Get());
// 	if (AngelEffectContext)
// 	{
// 		AngelEffectContext->SetDamageResult(DamageResult);
// 	}
// }

