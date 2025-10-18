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
	 * Tracks how much the player has spent during the current round per category.
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

		GetAngelGameState().OnRoundStart.AddUFunction(this, n"ResetSpendTracker");
	}

	UFUNCTION()
	void ResetMultikill()
	{
		MultikillCount = 0;
	}

	// - economy

	/**
	 * Grants the specified amount of credits to the player.
	 * @param Amount The amount of credits to grant.
	 * @param Reason The reason for granting the credits, used for logging and UI purposes.
	 */
	UFUNCTION(Category = "State | Economy")
	void GrantCredits(int Amount, ECreditsGrantedReason Reason)
	{
		Credits += Amount;
		Credits = Math::Clamp(Credits, 0, MaxCredits);

		Print(f"Granted {Amount} credits for reason {Reason}. \nNew total: {Credits}", 2.5f, FLinearColor::LucBlue);
	}

	/**
	 * Attempts to spend the specified amount of credits.
	 * @return True if the player could afford it and the amount was deducted, false otherwise.
	 * @param Amount The amount of credits to spend.
	 * @param OverrideAffordability If true, the amount will be deducted regardless of current credits.
	 */
	UFUNCTION(Category = "State | Economy")
	bool SpendCredits(int Amount, bool OverrideAffordability = false)
	{
		if (CanAfford(Amount) || OverrideAffordability)
		{
			Credits -= Amount;
			Credits = Math::Clamp(Credits, 0, MaxCredits);

			Print(f"Spent {Amount} credits. \nNew total: {Credits}");
			return true;
		}
		return false;
	}

	/**
     * Records a purchase for the current round.
     * Handles upgrades by only charging the difference in price.
	 * @return True if the purchase was successful, false if the player could not afford it.
     * @param Amount The total cost of the item being purchased.
     * @param Category The category of the purchase.
     */
    bool RecordSpend(int Amount, EShopCategory Category)
    {
        if (SpentPerType.Contains(Category))
        {
			if (Category == EShopCategory::Ability)
			{
				// For abilities, always spend the full amount, not just the difference
				if (Amount > Credits) return false;

				Credits -= Amount;
				Credits = Math::Clamp(Credits, 0, MaxCredits);

				SpentPerType[Category] = Amount;

				Print(f"Purchased ability in {Category} for {Amount}. New total: {Credits}");
				return true;
			}

            // Calculate the difference between new item cost and what was already spent
            int PreviousSpend = SpentPerType[Category];
            int DifferenceToSpend = Amount - PreviousSpend;
            
            // Only proceed if we can afford the difference
            if (DifferenceToSpend > Credits) return false;
            
            // Deduct only the difference
            Credits -= DifferenceToSpend;
            Credits = Math::Clamp(Credits, 0, MaxCredits);
            
            // Update the category spend to the new amount
            SpentPerType[Category] = Amount;
            
            Print(f"Upgraded item in {Category}. Paid difference: {DifferenceToSpend}. New total: {Credits}");
        }
        else
        {
            // New category purchase
            if (Amount > Credits) return false;
            
            // Deduct full amount
            Credits -= Amount;
            Credits = Math::Clamp(Credits, 0, MaxCredits);
            
            SpentPerType.Add(Category, Amount);
            
            Print(f"Purchased item in {Category} for {Amount}. New total: {Credits}");
        }
        
        return true;
    }

	/**
	 * Refunds a previously purchased item.
	 * This is used when a player sells an item they purchased during the current round.
	 * @param Category The category of the item to refund.
	 */
	bool RefundSpend(EShopCategory Category)
	{
		if (SpentPerType.Contains(Category))
		{
			int RefundAmount = SpentPerType[Category];
			Credits += RefundAmount;
			Credits = Math::Clamp(Credits, 0, MaxCredits);
			
			SpentPerType.Remove(Category);
			
			Print(f"Refunded {RefundAmount} credits for {Category}. New total: {Credits}");
			return true;
		}
		else
		{
			PrintWarning(f"Attempted to refund category {Category}, but no purchase was recorded.", 5);
			return false;
		}
	}

	/**
	 * Clears the spending tracker at the start of a new round.
	 * Credits have already been deducted when items were purchased.
	 */
	UFUNCTION(NotBlueprintCallable)
	private void ResetSpendTracker()
	{
		// Just clear the spending tracker for the new round
		SpentPerType.Empty();
	}

	UFUNCTION(Category = "State | Economy")
    bool CanAfford(int Cost, EShopCategory Category = EShopCategory::Sidearm)
    {
        if (!SpentPerType.Contains(Category)) 
        {
            // New purchase in this category
            return Cost <= Credits;
        }
        else
        {
            // Upgrade in existing category - only check if we can afford the difference
            int PreviousSpend = SpentPerType[Category];
            int Difference = Cost - PreviousSpend;
            return Difference <= Credits;
        }
    }
}
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