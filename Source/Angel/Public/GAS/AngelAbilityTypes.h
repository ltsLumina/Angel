// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayEffectTypes.h"
#include "GameplayTagContainer.h"

#include "UObject/Object.h"
#include "AngelAbilityTypes.generated.h"

USTRUCT(BlueprintType)
struct FDamageResult
{
	GENERATED_BODY()
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float HealthDamage = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float ShieldDamage = 0.0f;
	
	float GetTotalDamage() const { return HealthDamage + ShieldDamage; }
	bool IsValid() const { return GetTotalDamage() > 0.0f; }
};

UENUM(BlueprintType)
enum class EInvulnerabilityType : uint8
{
	/** Normal damage behaviour; no invulnerability is active. */
	None = 0,

	/**
	 * <para> Target does not take damage and does not trigger any enchantment triggers. </para>
	 * The target is effectively a wall, with no hit information passed to it.
	 * <para> DamageCalculation will run up to a point, but no health logic will be applied and no triggers will be fired. </para>
	 */
	Invulnerable = 1,

	/**
	 * <summary>
	 * <para> Target is immune to damage and to enchantment triggers. </para>
	 * Damage and Health calculations run all the way through, even displaying a damage number (formatted as "Immune!").
	 * <para> This is the most common form of invulnerability. </para>
	 * </summary>
	 */
	DamageImmune = 2,
};

UENUM(BlueprintType)
enum class EDamageType : uint8
{
	Weapon = 0,
	Ability = 1,
	Melee = 2,
	Environment = 3,
	Other = 4,
};

UENUM(BlueprintType)
enum class EBodyPart : uint8
{
	Unknown = 0,
	Head = 1,
	Body = 2,
	Legs = 3,
};

USTRUCT(BlueprintType)
struct FAngelGameplayEffectContext : public FGameplayEffectContext
{
	GENERATED_BODY()
	
public:
	bool GetIsPrecisionHit() const { return bIsPrecisionHit; }
	const FDamageResult& GetDamageResult() const { return DamageResult; }
	EInvulnerabilityType GetInvulnerabilityType() const { return InvulnerabilityType; }
	EDamageType GetDamageType() const { return DamageType; }
	EBodyPart GetBodyPart() const { return BodyPart; }
	
public:
	void SetIsPrecisionHit(const bool bInIsCriticalHit) { bIsPrecisionHit = bInIsCriticalHit; }
	void SetDamageResult(const FDamageResult& InDamageResult) { DamageResult = InDamageResult; }
	void SetInvulnerabilityType(const EInvulnerabilityType InInvulnerabilityType) { InvulnerabilityType = InInvulnerabilityType; }
	void SetDamageType(const EDamageType InDamageType) { DamageType = InDamageType; }
	void SetBodyPart(const EBodyPart InBodyPartHit) { BodyPart = InBodyPartHit; }

protected:
	UPROPERTY()
	bool bIsPrecisionHit = false;
	
	UPROPERTY()
	FDamageResult DamageResult;
	
	UPROPERTY()
	EInvulnerabilityType InvulnerabilityType = EInvulnerabilityType::None;
	
	UPROPERTY()
	EDamageType DamageType = EDamageType::Other;
	
	UPROPERTY()
	EBodyPart BodyPart{};
 
public:
	// Serialization and duplication
	/** Returns the actual struct used for serialization, subclasses must override this! */
	virtual UScriptStruct* GetScriptStruct() const override
	{
		return StaticStruct();
	}
	
	/** Creates a copy of this context, used to duplicate for later modifications */
	virtual FAngelGameplayEffectContext* Duplicate() const override
	{
		FAngelGameplayEffectContext* NewContext = new FAngelGameplayEffectContext();
		*NewContext = *this;
		NewContext->AddActors(Actors);
		if (GetHitResult())
		{
			// Does a deep copy of the hit result
			NewContext->AddHitResult(*GetHitResult(), true);
		}
		return NewContext;
	}
	
	virtual bool NetSerialize(FArchive& Ar, UPackageMap* Map, bool& bOutSuccess) override;
};
 
template <>
struct TStructOpsTypeTraits<FAngelGameplayEffectContext> : public TStructOpsTypeTraitsBase2<FAngelGameplayEffectContext>
{
	enum
	{
		WithNetSerializer = true,
		WithCopy = true // Necessary so that TSharedPtr<FHitResult> Data is copied around
	};
};