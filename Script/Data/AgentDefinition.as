UCLASS(Meta = (PrioritizeCategories = "Entity | Details"))
class UAgentDefinition : UDataAsset
{
	UPROPERTY(Category = "Agent | Info")
	FText AgentName = FText::FromString("Agent");

	UPROPERTY(Category = "Agent | Info")
	UTexture2D Avatar;

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