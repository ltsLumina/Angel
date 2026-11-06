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
	bool IsSprinting(AScriptPondHero Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Sprinting);
	}

	UFUNCTION(BlueprintPure)
	bool IsInteracting(AScriptPondHero Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Interacting);
	}

	UFUNCTION(BlueprintPure)
	bool IsAltMode(AScriptPondHero Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Weapon_AltFiring);
	}

	UFUNCTION(BlueprintPure)
	bool IsReloading(AScriptPondHero Hero)
	{
		if (!IsValid(Hero))
			return false;

		return Hero.AbilitySystem.HasGameplayTag(GameplayTags::State_Weapon_Reloading);
	}
}

/**
 * Returns the casted result of APawn -> AScriptPondHero.
 */
mixin AScriptPondHero AsHero(APawn Pawn)
{
	auto Result = Cast<AScriptPondHero>(Pawn);
	ThrowIf(Result == nullptr, f"Cast from {Pawn.GetName()} to Hero failed!");
	return Result;
}