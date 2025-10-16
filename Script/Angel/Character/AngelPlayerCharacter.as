class AAngelPlayerCharacter : AAngelAgent
{
	UPROPERTY(Category = "Player", NotVisible, BlueprintReadOnly)
	AAngelPlayerController AngelController;

	UPROPERTY(Category = "Player", EditDefaultsOnly)
	FGameplayTagContainer GameplayTags;

	UPROPERTY(Category = "Player", EditDefaultsOnly)
	UAngelGASAttributes Attributes;

	// - flags

	UPROPERTY(Category = "Player", VisibleAnywhere)
	EAngelMovementState MovementState;
	default MovementState = EAngelMovementState::Still;

	UPROPERTY(Category = "Player", VisibleAnywhere)
	EAngelMovementState PreviousMovementState;
	default PreviousMovementState = EAngelMovementState::Run;

	// - end

	UReloadComponent ReloadComponent;
	UHolsterComponent HolsterComponent;
	UInventoryComponent InventoryComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Attributes = Cast<UAngelGASAttributes>(AbilitySystem.RegisterAttributeSet(UAngelGASAttributes));

		ReloadComponent = UReloadComponent::Get(this);
		HolsterComponent = UHolsterComponent::Get(this);
		InventoryComponent = UInventoryComponent::Get(this);

		AngelController = GetAngelController(this); // Equivalent to Cast<AAngelPlayerController>(this);

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

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
		
	}
};

AAngelPlayerCharacter GetAngelCharacter(AActor Actor)
{
	return Cast<AAngelPlayerCharacter>(Actor);
}

AAngelPlayerCharacter GetAngelCharacter(int PlayerIndex)
{
	return Cast<AAngelPlayerCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}