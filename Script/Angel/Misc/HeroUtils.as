namespace HeroUtils
{
	UFUNCTION()
	void SetLooseGameplayTag(UAngelscriptAbilitySystemComponent ASC, FGameplayTag Tag, bool bEnabled)
	{
		if (!IsValid(ASC))
			return;

		if (bEnabled)
		{
			if (!ASC.HasGameplayTag(Tag))
				ASC.AddLooseGameplayTag(Tag);
		}
		else if (ASC.HasGameplayTag(Tag))
		{
			ASC.RemoveLooseGameplayTag(Tag);
		}
	}

	UFUNCTION()
	void SetLooseGameplayTagToAll(UAngelscriptAbilitySystemComponent ASC, FGameplayTag Tag, bool bEnabled)
	{
		if (!IsValid(ASC))
			return;

		if (bEnabled)
		{
			if (!ASC.HasGameplayTag(Tag))
				ASC.AddLooseGameplayTag(Tag, 1, EGameplayTagReplicationState::TagAndCountToAll);
		}
		else if (ASC.HasGameplayTag(Tag))
		{
			ASC.RemoveLooseGameplayTag(Tag, 1, EGameplayTagReplicationState::TagAndCountToAll);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsSprinting(AAngelAgent Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Sprinting);
	}

	UFUNCTION(BlueprintPure)
	bool IsInteracting(AAngelAgent Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Interacting);
	}

	UFUNCTION(BlueprintPure)
	bool IsAltMode(AAngelAgent Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Weapon_AltFiring);
	}

	UFUNCTION(BlueprintPure)
	bool IsReloading(AAngelAgent Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Weapon_Reloading);
	}
}

/**
 * Returns the casted result of APawn -> AAngelAgent.
 */
mixin AAngelAgent AsHero(APawn Pawn)
{
	auto Result = Cast<AAngelAgent>(Pawn);
	ThrowIf(Result == nullptr, f"Cast from {Pawn.GetName()} to Hero failed!");
	return Result;
}