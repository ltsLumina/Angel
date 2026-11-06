UCLASS(Abstract, HideDropdown)
class UAngelscriptGameplayAbility : UAngelscriptGASAbility
{
    UPROPERTY(NotVisible, BlueprintReadOnly, DisplayName = "ASC (Ability System Component)", BlueprintGetter = "GetAngelscriptAbilitySystemComponent", Meta = (AllowPrivateAccess="true"))
	private UAngelscriptAbilitySystemComponent AbilitySystem;

	UFUNCTION(BlueprintPure)
	protected UAngelscriptAbilitySystemComponent GetAngelscriptAbilitySystemComponent() const
	{		
		ThrowIf(!IsValid(AbilitySystemComponentFromActorInfo), "AbilitySystemComponent in ActorInfo is nullptr!");
		return Cast<UAngelscriptAbilitySystemComponent>(AbilitySystemComponentFromActorInfo);
	}

	protected UAngelscriptAbilitySystemComponent GetASC() const property
	{
		return GetAngelscriptAbilitySystemComponent();
	}

	// ~

	UPROPERTY(NotVisible, BlueprintReadOnly, DisplayName = "Avatar", BlueprintGetter = "GetAvatarActor", Meta = (AllowPrivateAccess="true"))
	private AActor _AvatarActor;

	UFUNCTION(BlueprintPure, NotBlueprintCallable)
	AActor GetAvatarActor() property
	{
		return AvatarActorFromActorInfo;
	}

	UFUNCTION(Category = "Avatar Actor", BlueprintPure)
	FVector GetAvatarLocation() property
	{
		return AvatarActorFromActorInfo.ActorLocation;
	}

	// - Helpers

	/**
	 * Shorthand for `GetFloatAttribute(fromAbilitySystemComponent)`.
	 * @param Found - If the attribute was found.
	 */
	UFUNCTION(BlueprintPure, Category = "Ability|Attribute", Keywords = "Get Float Attribute", Meta = (ReturnDisplayName = "Found"))
	bool GetAttributeValue(FGameplayAttribute Attribute, float&out BaseValue, float&out CurrentValue)
	{
		check(AbilitySystemComponentFromActorInfo != nullptr);

		bool SuccessfullyFoundAttribute = false;

		float Base = AbilitySystem::GetFloatAttributeBaseFromAbilitySystemComponent(
			AbilitySystemComponentFromActorInfo,
			UAngelscriptAttributeSet::GetGameplayAttribute(Attribute.AttributeSetClass, FName(Attribute.AttributeName)),
			SuccessfullyFoundAttribute);

		float Current = AbilitySystem::GetFloatAttributeFromAbilitySystemComponent(
			AbilitySystemComponentFromActorInfo,
			UAngelscriptAttributeSet::GetGameplayAttribute(Attribute.AttributeSetClass, FName(Attribute.AttributeName)),
			SuccessfullyFoundAttribute);

		ThrowIf(AbilitySystemComponentFromActorInfo == nullptr, f"No AbilitySystemComponent is registered to {GetName()}'s ActorInfo!");
		ThrowIf(!SuccessfullyFoundAttribute, f"No attribute of type '{Attribute.AttributeName}' was found on {AbilitySystemComponentFromActorInfo}");

		BaseValue = Base;
		CurrentValue = Current;

		return SuccessfullyFoundAttribute;
	}

	/** Helper that doesn't require a `Params` ref. */
	UFUNCTION(Category = "Gameplay Cue")
	void ExecuteGameplayCue(TSubclassOf<UGameplayCueNotify_Static> GameplayCue, FGameplayCueParameters Params = FGameplayCueParameters())
	{
		ExecuteGameplayCueWithParams_Static(GameplayCue, Params);
	}
};