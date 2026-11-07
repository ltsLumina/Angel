namespace Game
{
	UFUNCTION(BlueprintPure)
	AAngelPlayerCharacter GetPlayer() property
	{
		return Cast<AAngelPlayerCharacter>(Gameplay::GetPlayerCharacter(0));
	}

	AAngelPlayerCharacter GetAngelCharacter(AActor Actor)
	{
		return Cast<AAngelPlayerCharacter>(Actor);
	}

	AAngelPlayerCharacter GetAngelCharacter(int PlayerIndex = 0)
	{
		return Cast<AAngelPlayerCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
	}

	// - Controller

	UFUNCTION(BlueprintPure)
	AAngelPlayerController GetController() property
	{
		return Cast<AAngelPlayerController>(Gameplay::GetPlayerController(0));
	}

	AAngelPlayerController GetAngelController(APawn Pawn)
	{
		return Cast<AAngelPlayerController>(Pawn.GetController());
	}

	AAngelPlayerController GetAngelController(int PlayerIndex)
	{
		return Cast<AAngelPlayerController>(Gameplay::GetPlayerController(PlayerIndex));
	}

	// - GameState

	UFUNCTION(BlueprintPure)
	AAngelGameState GetGameState() property
	{
		return Cast<AAngelGameState>(Gameplay::GetGameState());
	}

	// - PlayerState

    UFUNCTION(BlueprintPure)
	AAngelPlayerState GetPlayerState() property
	{
		return Cast<AAngelPlayerState>(Gameplay::GetPlayerState(0));
	}

	UFUNCTION(BlueprintPure, Category = "Framework")
	AAngelPlayerState GetAngelPlayerState(int PlayerIndex = 0)
	{
		return Cast<AAngelPlayerState>(Gameplay::GetPlayerState(PlayerIndex));
	}
}