class UAngelCheatManager : UCheatManager
{
    AAngelGameState GameState;
    AAngelPlayerState PlayerState;    

	UFUNCTION(BlueprintOverride)
	void InitCheatManager()
	{
        GameState = GetAngelGameState();
        PlayerState = GetAngelPlayerState(0);
        if (!IsValid(GameState) || !IsValid(PlayerState))
        {
            PrintError("Failed to initialize AngelCheatManager: Invalid GameState or PlayerState.");
            return;
        }

        PrintWarning("AngelCheatManager initialized.");
	}

	UFUNCTION(Exec)
	void SkipPhase()
	{
        auto NextPhase = GameState.NextPhase();
        PrintWarning(f"Skipped to {NextPhase}.");
	}

    UFUNCTION(Exec)
    void ShortenPhase(float TimeToRemove)
    {
        GameState.ShortenPhase(TimeToRemove);
        PrintWarning(f"Shortened round by {TimeToRemove} seconds.");
    }

    UFUNCTION(Exec)
    void ExtendPhase(float ExtraTime)
    {
        GameState.ExtendPhase(ExtraTime);
        PrintWarning(f"Extended round by {ExtraTime} seconds.");
    }

    UFUNCTION(Exec)
    void FreezePhaseTimer(bool Freeze)
    {
        GameState.FreezeTimer = Freeze;
        PrintWarning(f"Set freeze timer to {Freeze}.");
    }

    UFUNCTION(Exec)
    void GrantGun(TSubclassOf<AGunBase> GunClass, bool AutoEquip = true)
    {
        GetAngelCharacter(0).HolsterComponent.GrantGun(GunClass, AutoEquip);
    }

    UFUNCTION(Exec)
    void AddCredits(int Amount, bool OverrideCap = false)
    {
        if (IsValid(PlayerState))
        {
            if (OverrideCap)
            {
                PlayerState.Credits += Amount;
                PlayerState.Credits = Math::Clamp(PlayerState.Credits, 0, PlayerState.MaxCredits);
                PrintWarning(f"Forcefully added {Amount}¤. New balance: {PlayerState.Credits}¤.");
                return;
            }

            PlayerState.GrantCredits(Amount, ECreditsGrantedReason::None);
        }
    }

    UFUNCTION(Exec)
    void DeductCredits(int Amount, bool OverrideAffordability = false)
    {
        if (IsValid(PlayerState))
        {
            if (OverrideAffordability)
            {
                PlayerState.Credits -= Amount;
                PlayerState.Credits = Math::Clamp(PlayerState.Credits, 0, PlayerState.MaxCredits);
                PrintWarning(f"Forcefully deducted {Amount}¤. New balance: {PlayerState.Credits}¤.");
                return;
            }

            if (PlayerState.SpendCredits(Amount))
            {
                PrintWarning(f"Deducted {Amount}¤. New balance: {PlayerState.Credits}¤.");
            }
            else
            {
                PrintWarning(f"Cannot deduct {Amount}¤. Current balance: {PlayerState.Credits}¤.");
            }
        }
    }
}