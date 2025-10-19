class AAngelPlayerCharacter : AAngelAgent
{
	UPROPERTY(Category = "Player", VisibleAnywhere)
	EAngelMovementState MovementState;
	default MovementState = EAngelMovementState::Still;

	UPROPERTY(Category = "Player", VisibleAnywhere)
	EAngelMovementState PreviousMovementState;
	default PreviousMovementState = EAngelMovementState::Run;

	// - end

	UReloadComponent ReloadComponent;
	UHolsterComponent HolsterComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ReloadComponent = UReloadComponent::Get(this);
		HolsterComponent = UHolsterComponent::Get(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BP_Tick(DeltaSeconds);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(float DeltaSeconds)
	{}

	UFUNCTION()
	void UseAbility(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		FVector2D InputVector = ActionValue.GetAxis2D();

		if (InputVector.Y == 1)
		{
			Ability_C();
		}
		else if (InputVector.Y == -1)
		{
			Ability_Q();
		}
		else if (InputVector.X == -1)
		{
			Ability_E();
		}
		else if (InputVector.X == 1)
		{
			Ability_X();
		}
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Ability C")
	void Ability_C()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Ability Q")
	void Ability_Q()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Ability E")
	void Ability_E()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Ability X")
	void Ability_X()
	{}
};

AAngelPlayerCharacter GetAngelCharacter(AActor Actor)
{
	return Cast<AAngelPlayerCharacter>(Actor);
}

AAngelPlayerCharacter GetAngelCharacter(int PlayerIndex = 0)
{
	return Cast<AAngelPlayerCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}