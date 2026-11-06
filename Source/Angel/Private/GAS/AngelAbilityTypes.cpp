// Fill out your copyright notice in the Description page of Project Settings.


#include "GAS/AngelAbilityTypes.h"

bool FAngelGameplayEffectContext::NetSerialize(FArchive& Ar, UPackageMap* Map, bool& bOutSuccess)
{
 enum RepFlag
    {
        REP_Instigator,
        REP_EffectCauser,
        REP_AbilityCDO,
        REP_SourceObject,
        REP_Actors,
        REP_HitResult,
        REP_WorldOrigin,
        REP_CartridgeID,
        REP_IsCriticalHit,
        REP_SourceLevel,
        REP_InvulnerabilityType,
        REP_DamageResult,
        REP_DamageType,
        REP_BodyPart,
        REP_MAX
    };
     
    uint16 RepBits = 0;
    if (Ar.IsSaving())
    {
        if (Instigator.IsValid())
        {
            RepBits |= 1 << REP_Instigator;
        }
        if (EffectCauser.IsValid())
        {
            RepBits |= 1 << REP_EffectCauser;
        }
        if (AbilityCDO.IsValid())
        {
            RepBits |= 1 << REP_AbilityCDO;
        }
        if (bReplicateSourceObject && SourceObject.IsValid())
        {
            RepBits |= 1 << REP_SourceObject;
        }
        if (Actors.Num() > 0)
        {
            RepBits |= 1 << REP_Actors;
        }
        if (HitResult.IsValid())
        {
            RepBits |= 1 << REP_HitResult;
        }
        if (bHasWorldOrigin)
        {
            RepBits |= 1 << REP_WorldOrigin;
        }
        if (bIsPrecisionHit)
        {
            RepBits |= 1 << REP_IsCriticalHit;
        }
        if (InvulnerabilityType != EInvulnerabilityType::None)
        {
            RepBits |= 1 << REP_InvulnerabilityType;
        }
        if (!FMath::IsNearlyZero(DamageResult.HealthDamage) || !FMath::IsNearlyZero(DamageResult.ShieldDamage) || !FMath::IsNearlyZero(DamageResult.GetTotalDamage()))
        {
            RepBits |= 1 << REP_DamageResult;
        }
        if (DamageType != EDamageType::Other)
        {
            RepBits |= 1 << REP_DamageType;
        }
        if (BodyPart != EBodyPart())
        {
            RepBits |= 1 << REP_BodyPart;
        }
        // if (SourceLevel > 0)
        // {
        //     RepBits |= 1 << REP_SourceLevel;
        // }
        // if (CartridgeID > 0)
        // {
        //     RepBits |= 1 << REP_CartrideID;
        // }
    }
 
    Ar.SerializeBits(&RepBits, REP_MAX);
 
    if (RepBits & (1 << REP_Instigator))
    {
        Ar << Instigator;
    }
    if (RepBits & (1 << REP_EffectCauser))
    {
        Ar << EffectCauser;
    }
    if (RepBits & (1 << REP_AbilityCDO))
    {
        Ar << AbilityCDO;
    }
    if (RepBits & (1 << REP_SourceObject))
    {
        Ar << SourceObject;
    }
    if (RepBits & (1 << REP_Actors))
    {
        SafeNetSerializeTArray_Default<31>(Ar, Actors);
    }
    if (RepBits & (1 << REP_HitResult))
    {
        if (Ar.IsLoading())
        {
            if (!HitResult.IsValid())
            {
                HitResult = TSharedPtr<FHitResult>(new FHitResult());
            }
        }
        HitResult->NetSerialize(Ar, Map, bOutSuccess);
    }
    if (RepBits & (1 << REP_WorldOrigin))
    {
        Ar << WorldOrigin;
        bHasWorldOrigin = true;
    }
    else
    {
        bHasWorldOrigin = false;
    }
    if (RepBits & (1 << REP_IsCriticalHit))
    {
        Ar << bIsPrecisionHit;
    }
    if (RepBits & (1 << REP_InvulnerabilityType))
    {
        uint8 InvulnerabilityTypeByte = static_cast<uint8>(InvulnerabilityType);
        Ar << InvulnerabilityTypeByte;
        if (Ar.IsLoading())
        {
            if (InvulnerabilityTypeByte > static_cast<uint8>(EInvulnerabilityType::DamageImmune))
            {
                InvulnerabilityTypeByte = static_cast<uint8>(EInvulnerabilityType::None);
            }
            InvulnerabilityType = static_cast<EInvulnerabilityType>(InvulnerabilityTypeByte);
        }
    }
    else if (Ar.IsLoading())
    {
        InvulnerabilityType = EInvulnerabilityType::None;
    }
    if (RepBits & (1 << REP_DamageResult))
    {
        Ar << DamageResult.HealthDamage;
        Ar << DamageResult.ShieldDamage;
    }
    else if (Ar.IsLoading())
    {
        DamageResult = FDamageResult();
    }
    if (RepBits & (1 << REP_DamageType))
    {
        uint8 DamageTypeByte = static_cast<uint8>(DamageType);
        Ar << DamageTypeByte;
        if (Ar.IsLoading())
        {
            if (DamageTypeByte > static_cast<uint8>(EDamageType::Other))
            {
                DamageTypeByte = static_cast<uint8>(EDamageType::Other);
            }
            DamageType = static_cast<EDamageType>(DamageTypeByte);
        }
    }
    else if (Ar.IsLoading())
    {
        DamageType = EDamageType::Other;
    }
    if (RepBits & (1 << REP_BodyPart))
    {
        uint8 BodyPartByte = static_cast<uint8>(BodyPart);
        Ar << BodyPartByte;
        if (Ar.IsLoading())
        {
            BodyPart = static_cast<EBodyPart>(BodyPartByte);
        }
    }
    else if (Ar.IsLoading())
    {
        BodyPart = EBodyPart();
    }
    // if (RepBits & (1 << REP_SourceLevel))
    // {
    //     Ar << SourceLevel;
    // }
    // if (RepBits & (1 << REP_CartrideID))
    // {
    //     Ar << CartridgeID;
    // }
 
    if (Ar.IsLoading())
    {
        AddInstigator(Instigator.Get(), EffectCauser.Get()); // Just to initialize InstigatorAbilitySystemComponent
    }   
     
    bOutSuccess = true;
    return true;
}