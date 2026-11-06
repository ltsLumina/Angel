namespace CharUtils
{
    UFUNCTION(BlueprintPure)
    bool IsAlive(AAngelAgent Agent)
    {
        return !Agent.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead);
    }

    UFUNCTION(BlueprintPure)
    bool IsDead(AAngelAgent Agent)
    {
        return Agent.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead);
    }

    /**
     * @return True if the character is actively playable, i.e., not dead, DBNO, or stunned.
     */
    UFUNCTION(BlueprintPure)
    bool IsPlayable(AAngelAgent Agent)
    {
        bool NotDead = !Agent.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead);
        bool NotStunned = !Agent.AbilitySystem.HasGameplayTag(GameplayTags::Debuffs_Stun);

        return NotDead && NotStunned;
    }
}