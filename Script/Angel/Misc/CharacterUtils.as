namespace CharUtils
{
    UFUNCTION(BlueprintPure)
    bool IsDBNO(APondCharacter PondCharacter)
    {
        return PondCharacter.AbilitySystem.HasGameplayTag(GameplayTags::State_DBNO);
    }

    UFUNCTION(BlueprintPure)
    bool IsAlive(APondCharacter PondCharacter)
    {
        return !PondCharacter.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead);
    }

    UFUNCTION(BlueprintPure)
    bool IsDead(APondCharacter PondCharacter)
    {
        return PondCharacter.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead);
    }

    /**
     * @return True if the character is actively playable, i.e., not dead, DBNO, or stunned.
     */
    UFUNCTION(BlueprintPure)
    bool IsPlayable(APondCharacter PondCharacter)
    {
        bool NotDead = !PondCharacter.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead);
        bool NotDBNO = !PondCharacter.AbilitySystem.HasGameplayTag(GameplayTags::State_DBNO);
        bool NotStunned = !PondCharacter.AbilitySystem.HasGameplayTag(GameplayTags::Debuffs_Stun);

        return NotDead && NotDBNO && NotStunned;
    }
}