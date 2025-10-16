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

    UPROPERTY(Category = "State | Economy", EditDefaultsOnly, Meta = (UIMin = "0", UIMax = "9000"))
    int StartingCredits = 800;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Kills = 0;
        Deaths = 0;
        MultikillCount = 0;
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
    bool SpendCredits(int Amount)
    {
        if (CanAfford(Amount))
        {
            Credits -= Amount;
            Credits = Math::Clamp(Credits, 0, MaxCredits);

            Print(f"Spent {Amount} credits. \nNew total: {Credits}");
            return true;
        }
        return false;
    }

    UFUNCTION(Category = "State | Economy")
    bool CanAfford(int Cost)
    {
        return Credits >= Cost;
    }
};

UFUNCTION(BlueprintPure)
AAngelPlayerState GetAngelPlayerState(int PlayerIndex)
{
    return Cast<AAngelPlayerState>(Gameplay::GetPlayerState(PlayerIndex));
}