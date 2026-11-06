class AAngelTrainingDummy : AAngelAgent
{	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Refresh();
	}

	UFUNCTION(Category = "Dummy | Health")
	void Refresh()
	{
		//Heal();
		//GrantArmor(EArmorType::Heavy);
	}
};