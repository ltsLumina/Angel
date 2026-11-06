// Mixins for FGameplayEffectContextHandle to expose Angel-specific helpers to script/blueprint

#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "GameplayEffectTypes.h"
#include "AngelAbilityTypes.h"
#include "AngelGameplayEffectContextScriptMixin.generated.h"

UCLASS(Meta = (ScriptMixin = "FDamageResult"))
class UFDamageResultScriptMixinLibrary : public UObject
{
    GENERATED_BODY()
public:
    
    UFUNCTION(ScriptCallable)
    static float GetTotalDamage(const FDamageResult& DamageResult)
    {
        return DamageResult.GetTotalDamage();
    }

    UFUNCTION(ScriptCallable)
    static bool IsValid(const FDamageResult& DamageResult)
    {
        return DamageResult.IsValid();
    }
};

UCLASS(Meta = (ScriptMixin = "FGameplayEffectContextHandle"))
class UFGameplayEffectContextScriptMixinLibrary : public UObject
{
    GENERATED_BODY()
public:
    
    UFUNCTION(ScriptCallable)
    static bool GetIsPrecisionHit(const FGameplayEffectContextHandle& EffectContext)
    {
        const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(EffectContext.Get());
        return AngelEffectContext ? AngelEffectContext->GetIsPrecisionHit() : false;
    }

    UFUNCTION(ScriptCallable)
    static EInvulnerabilityType GetInvulnerabilityType(const FGameplayEffectContextHandle& EffectContext)
    {
        const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(EffectContext.Get());
        return AngelEffectContext ? AngelEffectContext->GetInvulnerabilityType() : EInvulnerabilityType::None;
    }

    UFUNCTION(ScriptCallable)
    static EDamageType GetDamageType(const FGameplayEffectContextHandle& EffectContext)
    {
        const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(EffectContext.Get());
        return AngelEffectContext ? AngelEffectContext->GetDamageType() : EDamageType::Other;
    }

    UFUNCTION(ScriptCallable)
    static FDamageResult GetDamageResult(const FGameplayEffectContextHandle& EffectContext)
    {
        const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(EffectContext.Get());
        return AngelEffectContext ? AngelEffectContext->GetDamageResult() : FDamageResult();
    }
	
	UFUNCTION(ScriptCallable)
    static EBodyPart GetBodyPart(const FGameplayEffectContextHandle& EffectContext)
    {
        const FAngelGameplayEffectContext* AngelEffectContext = static_cast<const FAngelGameplayEffectContext*>(EffectContext.Get());
        return AngelEffectContext ? AngelEffectContext->GetBodyPart() : EBodyPart::Unknown;
    }
	
    UFUNCTION(ScriptCallable)
    static void SetIsPrecisionHit(UPARAM(ref) FGameplayEffectContextHandle& EffectContext, bool bInIsPrecisionHit)
    {
        FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(EffectContext.Get());
        if (AngelEffectContext)
        {
            AngelEffectContext->SetIsPrecisionHit(bInIsPrecisionHit);
        }
    }

    UFUNCTION(ScriptCallable)
    static void SetInvulnerabilityType(UPARAM(ref) FGameplayEffectContextHandle& EffectContext, EInvulnerabilityType InInvulnerabilityType)
    {
        FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(EffectContext.Get());
        if (AngelEffectContext)
        {
            AngelEffectContext->SetInvulnerabilityType(InInvulnerabilityType);
        }
    }
    
    UFUNCTION(ScriptCallable)
    static void SetDamageType(UPARAM(ref) FGameplayEffectContextHandle& EffectContext, EDamageType InDamageType)
    {
        FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(EffectContext.Get());
        if (AngelEffectContext)
        {
            AngelEffectContext->SetDamageType(InDamageType);
        }
    }

    UFUNCTION(ScriptCallable)
    static void SetDamageResult(UPARAM(ref) FGameplayEffectContextHandle& EffectContext, const FDamageResult& InDamageResult)
    {
        FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(EffectContext.Get());
        if (AngelEffectContext)
        {
            AngelEffectContext->SetDamageResult(InDamageResult);
        }
    }
	
	UFUNCTION(ScriptCallable)
    static void SetBodyPart(UPARAM(ref) FGameplayEffectContextHandle& EffectContext, const EBodyPart& InBodyPartHit)
    {
        FAngelGameplayEffectContext* AngelEffectContext = static_cast<FAngelGameplayEffectContext*>(EffectContext.Get());
        if (AngelEffectContext)
        {
            AngelEffectContext->SetBodyPart(InBodyPartHit);
        }
    }
};

