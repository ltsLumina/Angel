UCLASS(Abstract)
class UCountdownWidget : UUserWidget
{
    UPROPERTY(BindWidget)
    UTextBlock Countdown;

    AAngelGameState GameState;

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        GameState = Cast<AAngelGameState>(Gameplay::GetGameState());
    }

    UFUNCTION(BlueprintPure)
    FText GetTimeRemaining()
    {
        float TimeRemaining = GameState.GetTimeRemainingInPhase();
        int Minutes = Math::FloorToInt(TimeRemaining / 60);
        int Seconds = Math::FloorToInt(TimeRemaining) % 60;

        return FText::FromString((f"{Minutes}:{Seconds:02}"));
    }
};