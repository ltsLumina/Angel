class UAngelCheatManager : UCheatManager
{
	UFUNCTION(Exec)
	void SkipPhase()
	{
		auto GameState = Cast<AAngelGameState>(Gameplay::GetGameState());
        auto NextPhase = GameState.NextPhase();
        PrintWarning(f"Skipped to {NextPhase}.");
	}

    UFUNCTION(Exec)
    void ShortenPhase(float TimeToRemove)
    {
        auto GameState = Cast<AAngelGameState>(Gameplay::GetGameState());
        GameState.ShortenPhase(TimeToRemove);
        PrintWarning(f"Shortened round by {TimeToRemove} seconds.");
    }

    UFUNCTION(Exec)
    void ExtendPhase(float ExtraTime)
    {
        auto GameState = Cast<AAngelGameState>(Gameplay::GetGameState());
        GameState.ExtendPhase(ExtraTime);
        PrintWarning(f"Extended round by {ExtraTime} seconds.");
    }

    UFUNCTION(Exec)
    void FreezePhaseTimer(bool Freeze)
    {
        auto GameState = Cast<AAngelGameState>(Gameplay::GetGameState());
        GameState.FreezeTimer = Freeze;
        PrintWarning(f"Set freeze timer to {Freeze}.");
    }
}