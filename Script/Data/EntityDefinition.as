UCLASS(Abstract, Meta = (PrioritizeCategories = "Entity | Details"))
class UEntityDefinition : UDataAsset
{
	UPROPERTY(Category = "Entity | Details", EditDefaultsOnly, BlueprintReadOnly)
	FText EntityName;
	default EntityName = FText::FromString("Entity");

	UPROPERTY(Category = "Entity | Details")
	bool bRagdollsOnDeath = true;

	UPROPERTY(Category = "Entity | GAS", Meta = (EditFixedOrder, RequiredAssetDataTags = "RowStructure=/Script/GameplayAbilities.AttributeMetaData"))
	TMap<TSubclassOf<UAngelscriptAttributeSet>, UDataTable> StartingData;

	UPROPERTY(Category = "Entity | GAS", Meta = (EditFixedOrder))
	TArray<TSubclassOf<UAngelscriptGameplayAbility>> StartingAbilities;

	UPROPERTY(Category = "Entity | GAS", Meta = (EditFixedOrder))
	TArray<TSubclassOf<UAngelscriptGameplayEffect>> StartingEffects;

	// audio
	
	UPROPERTY(Category = "Entity | Audio")
	USoundCue HurtSound;

	UPROPERTY(Category = "Entity | Audio")
	USoundCue DeathSound;
	
	//~
}