UCLASS(Abstract)
class UKillfeedWidget : UUserWidget
{
	UPROPERTY()
	TMap<UTexture2D, UTexture2D> IconToKillfedIconMap;

	UFUNCTION(BlueprintPure)
	UTexture2D GetKillfeedIcon(UTexture2D Icon)
	{
		if (IconToKillfedIconMap.Contains(Icon))
		{
			return IconToKillfedIconMap[Icon];
		}
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		GetAngelGameState().OnAgentDeath.AddUFunction(this, n"OnAgentDeath");

		BP_Construct();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "On Agent Death")
	void OnAgentDeath(AAngelAgent Killer, AGunBase WeaponUsed, AAngelAgent Victim,
					  bool WasHeadshot)
	{}
};