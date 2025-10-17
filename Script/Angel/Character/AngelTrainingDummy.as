event void OnDeath();

class AAngelTrainingDummy : AAngelAgent
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Refresh();
	}

	UFUNCTION(Category = "Dummy | Health")
	void Refresh()
	{
		CurrentHealth = 100;
		CurrentArmor = 50;
	}
};