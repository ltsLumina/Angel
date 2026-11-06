class UADSComponent : UActorComponent
{
	UPROPERTY(Category = "ADS", VisibleAnywhere, BlueprintReadOnly)
	bool IsADS;

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void StartADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = false;
	}

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void CancelledADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = false;
	}

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void TriggeredADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = true;
	}

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void EndADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = false;
	}

	UAngelscriptAbilitySystemComponent ASC;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ASC = UAngelscriptAbilitySystemComponent::Get(Game::Player);
	}

	UFUNCTION()
	void StartAimDownSights(FInputActionValue ActionValue = FInputActionValue(), float32 InElapsedTime = -1, float32 InTriggeredTime = -1,
							const UInputAction SourceAction = nullptr)
	{
		// TODO:
		/* ASC.TryActivateAbilityByClass(WeaponDefinition.AltFireGameplayAbility);
		ASC.PressInputID(int(EGASInputID::AltFire)); */
	}

	UFUNCTION()
	void EndAimDownSights(FInputActionValue ActionValue = FInputActionValue(), float32 InElapsedTime = -1, float32 InTriggeredTime = -1,
						  const UInputAction SourceAction = nullptr)
	{
		// TODO:
		/* ASC.CancelAbility(WeaponDefinition.AltFireGameplayAbility);
		ASC.ReleaseInputID(int(EGASInputID::AltFire)); */
	}
};
