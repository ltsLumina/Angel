// Copyright 'Team PONDAGON' - All rights reserved.


#include "GEStatusEffectComponent.h"

#include "AbilitySystemComponent.h"
#include "ActiveGameplayEffectHandle.h"
#include "GameplayEffect.h"
#include "AngelHUDBase.h"

#include "Kismet/GameplayStatics.h"

bool UGEStatusEffectComponent::OnActiveGameplayEffectAdded(FActiveGameplayEffectsContainer& ActiveGEContainer, FActiveGameplayEffect& ActiveGE) const
{
	const FActiveGameplayEffectHandle Handle = ActiveGE.Handle;

	APlayerController* PC = nullptr;
	if (ActiveGEContainer.Owner && ActiveGEContainer.Owner->AbilityActorInfo.IsValid())
	{
		PC = ActiveGEContainer.Owner->AbilityActorInfo->PlayerController.Get();
	}

	// Only the client that actually controls this pawn has a HUD instance.
	if (!PC || !PC->IsLocalController())
	{
		return Super::OnActiveGameplayEffectAdded(ActiveGEContainer, ActiveGE);
	}

	if (AAngelHUDBase* HUD = Cast<AAngelHUDBase>(PC->GetHUD()))
	{
		HUD->NotifyEffectApplied(PC, Handle, EnchantmentClass, EffectType);
	}

	return Super::OnActiveGameplayEffectAdded(ActiveGEContainer, ActiveGE);
}

bool UGEStatusEffectComponent::CanGameplayEffectApply(const FActiveGameplayEffectsContainer& ActiveGEContainer, const FGameplayEffectSpec& GESpec) const
{
	if (GESpec.Def->DurationPolicy == EGameplayEffectDurationType::Instant)
	{
		FMessageDialog::Open
		(
			EAppMsgType::Ok,
			FText::FromString(TEXT("The Gameplay Effect this component is on must have a duration."))
		);
		return false;
	}
	
	return Super::CanGameplayEffectApply(ActiveGEContainer, GESpec);
}
