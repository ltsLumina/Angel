class AAngelPlayerState : APlayerState
{
    UPROPERTY(Category = "Player State", VisibleAnywhere)
    int Kills;

    UPROPERTY(Category = "Player State", VisibleAnywhere)
    int Deaths;

    UPROPERTY(Category = "Player State", VisibleAnywhere)
    int MultikillCount;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Kills = 0;
        Deaths = 0;
    }

    UFUNCTION()
    void ResetMultikill()
    {
        MultikillCount = 0;
    }
};

AAngelPlayerState GetAngelPlayerState(int PlayerIndex)
{
    return Cast<AAngelPlayerState>(GetAngelCharacter(PlayerIndex).PlayerState);
}