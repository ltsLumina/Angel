class AAngelPlayerState : APlayerState
{
	UPROPERTY(Category = "State | Team", VisibleAnywhere)
	ETeam Team = ETeam::Defenders;

	UPROPERTY(Category = "State | Stats", VisibleAnywhere)
	int Kills;

	UPROPERTY(Category = "State | Stats", VisibleAnywhere)
	int Deaths;

	UPROPERTY(Category = "State | Stats", VisibleAnywhere)
	int MultikillCount;

	UPROPERTY(Category = "State | Economy", VisibleAnywhere, Meta = (UIMin = "0", UIMax = "9000"))
	int Credits;

	UPROPERTY(Category = "State | Economy", EditDefaultsOnly, Meta = (UIMin = "0", UIMax = "9000"))
	int MaxCredits = 9000;

	UPROPERTY(Category = "State | Economy", EditDefaultsOnly, BlueprintGetter = "GetMinNextRound")
	int MinNextRound;

	/**
	 * Tracks how much the player has spent during the current round.
	 * This amount will be deducted from their credits at the start of the next round.
	 */
	UPROPERTY(Category = "State | Economy", VisibleAnywhere)
	TMap<EShopCategory, int> SpentPerType;

	UFUNCTION(BlueprintPure)
	int GetMinNextRound()
	{
		int Value = Credits + GetAngelGameState().GetCreditsForReason(ECreditsGrantedReason::RoundLoss);
		return Math::Clamp(Value, 0, MaxCredits);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Kills = 0;
		Deaths = 0;
		MultikillCount = 0;

		GetAngelGameState().OnRoundStart.AddUFunction(this, n"Spend");
	}

	UFUNCTION()
	void ResetMultikill()
	{
		MultikillCount = 0;
	}

	// - economy

	UFUNCTION(Category = "State | Economy")
	void GrantCredits(int Amount, ECreditsGrantedReason Reason)
	{
		Credits += Amount;
		Credits = Math::Clamp(Credits, 0, MaxCredits);

		Print(f"Granted {Amount} credits for reason {Reason}. \nNew total: {Credits}");
	}

	/**
	 * Attempts to spend the specified amount of credits.
	 * @return True if the player could afford it and the amount was deducted, false otherwise.
	 * @param Amount The amount of credits to spend.
	 * @param OverrideAffordability If true, the amount will be deducted regardless of current credits.
	 */
	UFUNCTION(Category = "State | Economy")
	bool SpendCredits(int Amount, EShopCategory Category)
	{
		if (CanAfford(Amount))
		{
			if (Category == EShopCategory::Ability)
			{
				SpentPerType.FindOrAdd(Category) += Amount;
				AccumulatedPreSpend += Amount;
				return true;
			}
			SpentPerType.FindOrAdd(Category) = Amount;
			AccumulatedPreSpend += Amount;

			Print(f"Spent {Amount} credits. \nNew total: {Credits}");
			return true;
		}
		return false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void Spend()
	{
		int AccumulatedRoundSpend = 0;
		TArray<EShopCategory> Keys;
		
		SpentPerType.GetKeys(Keys);
		for (EShopCategory Key : Keys)
		{
			AccumulatedRoundSpend += SpentPerType[Key];
		}

		Credits -= AccumulatedRoundSpend;
		Credits = Math::Clamp(Credits, 0, MaxCredits);

		// print for all categories
		for (EShopCategory Key : Keys)
		{
			PrintWarning(f"Spent {SpentPerType[Key]} credits on {Key} this round.", 10);
		}
		
		SpentPerType.Empty();
		AccumulatedPreSpend = 0;
	}

	int AccumulatedPreSpend;

	UFUNCTION(Category = "State | Economy")
	bool CanAfford(int Cost)
	{
		return AccumulatedPreSpend + Cost <= Credits;
	}
};

UFUNCTION(BlueprintPure, Category = "Framework")
AAngelPlayerState GetAngelPlayerState(int PlayerIndex = 0)
{
	return Cast<AAngelPlayerState>(Gameplay::GetPlayerState(PlayerIndex));
}

UFUNCTION(BlueprintPure, Category = "UI | Economy")
FText GetCreditsFormatted()
{
	AAngelPlayerState PlayerState = GetAngelPlayerState(0);
    return FormatCredits(PlayerState.Credits);
}

UFUNCTION(BlueprintPure, Category = "UI | Economy")
FText FormatCredits(int Credits)
{
    FString Pretty;

    FNumberFormattingOptions FormatOptions;
    FormatOptions.SetUseGrouping(false);
    FormatOptions.SetMaximumIntegralDigits(4);
    FormatOptions.SetMaximumFractionalDigits(0);
    Pretty = FText::AsNumber(Credits, FormatOptions).ToString();
    if (Credits >= 1000)
    {
        Insert(Pretty, ",", 1);
    }

    return FText::FromString(f"¤{Pretty}");
}