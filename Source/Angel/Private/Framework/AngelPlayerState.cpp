// Fill out your copyright notice in the Description page of Project Settings.


#include "Framework/AngelPlayerState.h"
#include "AngelscriptAbilitySystemComponent.h"

AAngelPlayerStateBase::AAngelPlayerStateBase(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
	AbilitySystem = CreateDefaultSubobject<UAngelscriptAbilitySystemComponent>(TEXT("AbilitySystem"));
	AbilitySystem->SetIsReplicated(true);
	
	// Mixed mode means we only are replicated the GEs to ourself, not the GEs to simulated proxies. If another AngelPlayerState (Hero) receives a GE,
	// we won't be told about it by the Server. Attributes, GameplayTags, and GameplayCues will still replicate to us.
	AbilitySystem->SetReplicationMode(EGameplayEffectReplicationMode::Mixed);
	
	// Set PlayerState's NetUpdateFrequency to the same as the Character.
	// Default is very low for PlayerStates and introduces perceived lag in the ability system.
	// 100 is probably way too high for a shipping game, you can adjust to fit your needs.
	SetNetUpdateFrequency(75.f);
}

void AAngelPlayerStateBase::BeginPlay()
{
	Super::BeginPlay();
}

void AAngelPlayerStateBase::PostNetInit()
{
	Super::PostNetInit();
	BP_PostNetInit();
}

UAbilitySystemComponent* AAngelPlayerStateBase::GetAbilitySystemComponent() const
{
	return AbilitySystem;
}

void AAngelPlayerStateBase::GetOwnedGameplayTags(FGameplayTagContainer& TagContainer) const
{
	if(AbilitySystem)
	{
		AbilitySystem->GetOwnedGameplayTags(TagContainer);
	}
}