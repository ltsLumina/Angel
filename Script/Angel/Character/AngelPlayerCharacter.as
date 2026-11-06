class AAngelPlayerCharacter : AAngelAgent
{
	default bReplicates = true;
	default bReplicateMovement = true;

	UPROPERTY(Category = "Entity", EditDefaultsOnly)
	UEntityDefinition EntityDefinition;

	UPROPERTY(Category = "Player", VisibleAnywhere)
	EAngelMovementState MovementState;
	default MovementState = EAngelMovementState::Still;

	UPROPERTY(Category = "Player", VisibleAnywhere)
	EAngelMovementState PreviousMovementState;
	default PreviousMovementState = EAngelMovementState::Run;

	// - end

	UReloadComponent ReloadComponent;
	UHolsterComponent HolsterComponent;
	UPROPERTY(DefaultComponent, Category = "Components")
	UADSComponent ADSComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ThrowIf(Mesh.bPauseAnims, f"Animations are paused on {Mesh.Name} of {Name}!");

		ReloadComponent = UReloadComponent::Get(this);
		HolsterComponent = UHolsterComponent::Get(this);
	}

	UFUNCTION(BlueprintOverride)
	void Possessed(AController NewController)
	{
		ThrowIf(AbilitySystem == nullptr, "AbilitySystem is nullptr!\nMake sure to call this AFTER the ability system has been initialized.");
		ThrowIf(EntityDefinition == nullptr, "EntityDefinition is not set!");

		for (auto& StartingAbility : EntityDefinition.StartingAbilities)
		{
			AbilitySystem.GiveAbility(StartingAbility, 1, -1, nullptr);
		}

		for (auto& StartingEffect : EntityDefinition.StartingEffects)
		{
			AbilitySystem.ApplyGameplayEffectToSelf(StartingEffect, 1, FGameplayEffectContextHandle());
		}

		AbilitySystem.OnOwnedTagUpdated.AddUFunction(this, n"OwnedTagsUpdated");

		AbilitySystem.RegisterAttributeChangedCallback(UCharacterAttributes, UCharacterAttributes::HealthName, this, n"HealthChanged");
	}

	UFUNCTION(BlueprintOverride)
	void OnRep_PlayerState()
	{
		AbilitySystem.OnOwnedTagUpdated.AddUFunction(this, n"OwnedTagsUpdated");
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OwnedTagsUpdated(const FGameplayTag&in Tag, bool TagExists)
	{
		if (Tag == GameplayTags::State_Dead && TagExists)
		{
			AbilitySystem.RemoveLooseGameplayTag(GameplayTags::State_Health_Healthy, 1, EGameplayTagReplicationState::TagOnly);
			AbilitySystem.RemoveLooseGameplayTag(GameplayTags::State_Health_Critical, 1, EGameplayTagReplicationState::TagOnly);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void HealthChanged(FAngelscriptAttributeChangedData Data)
	{
		if (Data.NewValue == Data.OldValue)
			return; // value didnt change

		float Delta = Math::Abs(Data.NewValue - Data.OldValue);

		// Took damage
		if (Data.NewValue < Data.OldValue)
		{
		}
		else // Was Healed
		{
		}
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
