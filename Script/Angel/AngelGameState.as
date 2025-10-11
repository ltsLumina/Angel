event void BuyPhaseStartEvent();
event void BuyPhaseEndEvent();
event void RoundStartEvent();
event void RoundEndEvent();

enum EGamePhase
{
	BuyPhase,
	GamePhase,
	RoundEnd,
}

UCLASS(Abstract)
class AAngelGameState : AGameStateBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(Category = "Game State", VisibleInstanceOnly)
	EGamePhase CurrentPhase = EGamePhase::BuyPhase;

	UPROPERTY(Category = "Game Phase", VisibleInstanceOnly, BlueprintReadOnly)
	EGamePhase PreviousPhase = EGamePhase::RoundEnd;

    UPROPERTY(Category = "Game State", EditDefaultsOnly, BlueprintReadOnly)
    bool FreezeTimer = false;

	UPROPERTY(Category = "Buy Phase", EditDefaultsOnly, BlueprintReadOnly)
	float BuyPhaseDuration = 30.0f;

	UPROPERTY(Category = "Buy Phase", VisibleAnywhere, BlueprintReadOnly)
	float BuyPhaseTimeRemaining;
	default BuyPhaseTimeRemaining = BuyPhaseDuration;

	UPROPERTY(Category = "Game Phase", EditDefaultsOnly, BlueprintReadOnly)
	float RoundDuration = 100.0f;

	UPROPERTY(Category = "Game Phase", VisibleAnywhere, BlueprintReadOnly)
	float RoundTimeRemaining;
	default RoundTimeRemaining = RoundDuration;

	UPROPERTY(Category = "Game Phase", EditDefaultsOnly, BlueprintReadOnly)
	float SpikePlantedExtension = 45.0f;

	UPROPERTY(Category = "Round End", EditDefaultsOnly, BlueprintReadOnly)
	float RoundEndDuration = 7.0f;

	UPROPERTY(Category = "Round End", VisibleAnywhere, BlueprintReadOnly)
	float RoundEndTimeRemaining;
	default RoundEndTimeRemaining = RoundEndDuration;

	UPROPERTY(Category = "Events")
	BuyPhaseStartEvent OnBuyPhaseStart;
	UPROPERTY(Category = "Events")
	BuyPhaseEndEvent OnBuyPhaseEnd;
	UPROPERTY(Category = "Events")
	RoundStartEvent OnRoundStart;
	UPROPERTY(Category = "Events")
	RoundEndEvent OnRoundEnd;

	UFUNCTION(BlueprintEvent, DisplayName = "On Phase Changed")
	void BP_OnPhaseChanged(EGamePhase NewPhase)
	{
		Print(f"Phase changed to {NewPhase}", 3, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Buy Phase Started")
	void BP_BuyPhaseStarted()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Buy Phase Ended")
	void BP_BuyPhaseEnded()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Round Started")
	void BP_RoundStarted()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Round Ended")
	void BP_RoundEnded()
	{}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnBuyPhaseStart.AddUFunction(this, n"BP_BuyPhaseStarted");
		OnBuyPhaseEnd.AddUFunction(this, n"BP_BuyPhaseEnded");
		OnRoundStart.AddUFunction(this, n"BP_RoundStarted");
		OnRoundEnd.AddUFunction(this, n"BP_RoundEnded");

		StartBuyPhase();
	}

    UFUNCTION()
	float GetTimeRemainingInPhase()
	{
        float Timer; 
        GetCurrentTimer(Timer);
        return Timer;
	}

    void GetCurrentTimer(float&out Timer)
    {
        switch (CurrentPhase)
        {
            case EGamePhase::BuyPhase:
                Timer = BuyPhaseTimeRemaining;
                break;

            case EGamePhase::GamePhase:
                Timer = RoundTimeRemaining;
                break;

            case EGamePhase::RoundEnd:
                Timer = RoundEndTimeRemaining;
                break;

            default:
                PrintError("Unknown game phase!");
                Timer = 0.0f;
                return;
        }
    }

	UFUNCTION()
	EGamePhase NextPhase()
	{
		switch (CurrentPhase)
		{
			case EGamePhase::BuyPhase:
				return StartRound();

			case EGamePhase::GamePhase:
				return EndRound();

			case EGamePhase::RoundEnd:
				return StartBuyPhase();

			default:
				PrintError("Unknown game phase!");
				return CurrentPhase;
		}
	}

	UFUNCTION()
	EGamePhase StartBuyPhase()
	{
		CurrentPhase = EGamePhase::BuyPhase;
		BuyPhaseTimeRemaining = BuyPhaseDuration;
		OnBuyPhaseStart.Broadcast();

		return CurrentPhase;
	}

	UFUNCTION()
	EGamePhase StartRound()
	{
		CurrentPhase = EGamePhase::GamePhase;
		RoundTimeRemaining = RoundDuration;
		OnRoundStart.Broadcast();

		return CurrentPhase;
	}

	UFUNCTION()
	EGamePhase EndRound()
	{
		CurrentPhase = EGamePhase::RoundEnd;
		RoundEndTimeRemaining = RoundEndDuration;
		OnRoundEnd.Broadcast();

		return CurrentPhase;
	}

    UFUNCTION()
    void ShortenPhase(float TimeToRemove)
    {
        float Timer; 
        GetCurrentTimer(Timer);

        Timer = Math::Max(Timer - TimeToRemove, 0.0f);
        Print(f"Shortened phase by {TimeToRemove} seconds. New time remaining: {Timer} seconds.", 3, FLinearColor::Yellow);
    }

	UFUNCTION()
	void ExtendPhase(float ExtraTime)
	{
        float Timer; 
        GetCurrentTimer(Timer);

        Timer += ExtraTime;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (PreviousPhase != CurrentPhase)
		{
			PreviousPhase = CurrentPhase;
			BP_OnPhaseChanged(CurrentPhase);
		}

        if (FreezeTimer) return;

		switch (CurrentPhase)
		{
			case EGamePhase::BuyPhase:
				BuyPhaseTimeRemaining -= DeltaSeconds;
				if (BuyPhaseTimeRemaining <= 0.0f)
				{
					BuyPhaseTimeRemaining = 0.0f;
					StartRound();
				}
				break;

			case EGamePhase::GamePhase:
				RoundTimeRemaining -= DeltaSeconds;
				if (RoundTimeRemaining <= 0.0f)
				{
					RoundTimeRemaining = 0.0f;
					EndRound();
				}
				break;

			case EGamePhase::RoundEnd:
				RoundEndTimeRemaining -= DeltaSeconds;
				if (RoundEndTimeRemaining <= 0.0f)
				{
					RoundEndTimeRemaining = 0.0f;
					StartBuyPhase();
				}
				break;

			default:
				PrintError("Unknown game phase!");
				return;
		}
	}
};