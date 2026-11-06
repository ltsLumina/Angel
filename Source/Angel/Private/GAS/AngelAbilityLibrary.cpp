// Fill out your copyright notice in the Description page of Project Settings.

#include "GAS/AngelAbilityLibrary.h"
#include "GAS/AngelAbilityTypes.h"

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
	 return EDamageType::Other;
}

EBodyPart UAngelAbilityLibrary::GetBodyPart(const FGameplayEffectContextHandle& EffectContext)
{
	const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(EffectContext.Get());
	if (AngelEffectContext)
	{
		return AngelEffectContext->GetBodyPart();
	}
	return EBodyPart::Unknown;
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

void UAngelAbilityLibrary::SetBodyPart(FGameplayEffectContextHandle& EffectContext, EBodyPart BodyPart)
{
	FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(EffectContext.Get());
	if (AngelEffectContext)
	{
		AngelEffectContext->SetBodyPart(BodyPart);
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

