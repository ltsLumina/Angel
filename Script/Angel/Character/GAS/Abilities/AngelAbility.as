// base class for all gameplay abilities in the Angel project
UCLASS(Abstract)
class UAngelAbility : UGameplayAbility
{
	UPROPERTY(Category = "Ability | Charges", EditDefaultsOnly, Meta = (UIMin = "1", UIMax = "3"))
	int CurrentCharges = 2;

	UPROPERTY(Category = "Ability | Charges", EditDefaultsOnly, Meta = (UIMin = "1", UIMax = "3"))
	int MaxCharges = 2;

    UPROPERTY(Category = "Ability | Duration", EditDefaultsOnly, Meta = (UIMin = "-1.0", UIMax = "10.0"))
    float Duration = 5.0f;

	UFUNCTION(BlueprintOverride)
	bool CanActivateAbility(FGameplayAbilityActorInfo InActorInfo, FGameplayAbilitySpecHandle Handle,
							FGameplayTagContainer& RelevantTags) const
	{
		return CurrentCharges > 0;
	}

	UFUNCTION()
	void ConsumeCharge()
	{
		if (CurrentCharges > 0)
			CurrentCharges--;
	}
};