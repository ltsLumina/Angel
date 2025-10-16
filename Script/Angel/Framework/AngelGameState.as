event void FBuyPhaseStartEvent();
event void FRoundStartEvent();
event void FRoundEndEvent();

event void AgentDeathEvent(AAngelAgent Killer, AGunBase WeaponUsed, AAngelAgent Victim, bool WasHeadshot);

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

	UPROPERTY(Category = "Game State", VisibleInstanceOnly, BlueprintReadOnly)
	EWinCondition LastWinCondition = EWinCondition::TimeExpired;

	UPROPERTY(Category = "Game State", VisibleInstanceOnly, BlueprintReadOnly)
	int Round;

	UPROPERTY(Category = "Game State", VisibleInstanceOnly, BlueprintReadOnly)
	const int RoundsToWin = 13;

	UPROPERTY(Category = "Game State", EditInstanceOnly, BlueprintReadOnly)
	bool FreezeTimer = false;

	UPROPERTY(Category = "Teams", VisibleInstanceOnly, BlueprintReadOnly)
	int AllyScore;
	default AllyScore = 0;

	UPROPERTY(Category = "Teams", VisibleInstanceOnly, BlueprintReadOnly)
	int EnemyScore;
	default EnemyScore = 0;

	UPROPERTY(Category = "Buy Phase", EditDefaultsOnly, BlueprintReadOnly)
	float BuyPhaseDuration = 30.0f;

	UPROPERTY(Category = "Buy Phase", VisibleInstanceOnly, BlueprintReadOnly)
	float BuyPhaseTimeRemaining;
	default BuyPhaseTimeRemaining = BuyPhaseDuration;

	UPROPERTY(Category = "Game Phase", EditDefaultsOnly, BlueprintReadOnly)
	float RoundDuration = 100.0f;

	UPROPERTY(Category = "Game Phase", VisibleInstanceOnly, BlueprintReadOnly)
	float RoundTimeRemaining;
	default RoundTimeRemaining = RoundDuration;

	UPROPERTY(Category = "Game Phase", EditDefaultsOnly, BlueprintReadOnly)
	float SpikePlantedExtension = 45.0f;

	UPROPERTY(Category = "Round End", EditDefaultsOnly, BlueprintReadOnly)
	float RoundEndDuration = 7.0f;

	UPROPERTY(Category = "Round End", VisibleInstanceOnly, BlueprintReadOnly)
	float RoundEndTimeRemaining;
	default RoundEndTimeRemaining = RoundEndDuration;

	// - events

	UPROPERTY(Category = "Events")
	FBuyPhaseStartEvent OnBuyPhaseStart;
	UPROPERTY(Category = "Events")
	FRoundStartEvent OnRoundStart;
	UPROPERTY(Category = "Events")
	FRoundEndEvent OnRoundEnd;

	// Global death event that any enemy can broadcast to
	UPROPERTY(Category = "Events", VisibleAnywhere, BlueprintReadOnly)
	AgentDeathEvent OnAgentDeath;

	UFUNCTION(BlueprintEvent, DisplayName = "On Phase Changed")
	void BP_OnPhaseChanged(EGamePhase NewPhase)
	{
		Print(f"Phase changed to {NewPhase}", 3, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Buy Phase Started")
	void BP_BuyPhaseStarted()
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

	UFUNCTION(Category = "Game Phase", CallInEditor)
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

	bool HasGameBegun()
	{
		return Round > 0;
	}

	UFUNCTION(Category = "Game Phase", CallInEditor)
	EGamePhase StartBuyPhase()
	{
		CurrentPhase = EGamePhase::BuyPhase;
		BuyPhaseTimeRemaining = BuyPhaseDuration;

		AAngelPlayerState PlayerState = GetAngelPlayerState(0);

		if (HasGameBegun())
		{
			ETeam Team = PlayerState.Team;
			ECreditsGrantedReason Reason = GetReason(Team, LastWinCondition);
			PlayerState.GrantCredits(GetCreditsForReason(Reason), Reason);
		}
		else
		{
			PlayerState.GrantCredits(GetCreditsForReason(ECreditsGrantedReason::StartingCredits), ECreditsGrantedReason::StartingCredits);
		}

		OnBuyPhaseStart.Broadcast();
		return CurrentPhase;
	}

	UFUNCTION(Category = "Game Phase", CallInEditor)
	EGamePhase StartRound()
	{
		CurrentPhase = EGamePhase::GamePhase;
		RoundTimeRemaining = RoundDuration;

		GetAngelController(0).ToggleShop(ForceClose = true);

		Round++;

		OnRoundStart.Broadcast();
		return CurrentPhase;
	}

	ECreditsGrantedReason GetReason(ETeam Team, EWinCondition Condition)
	{
		if (Team == ETeam::Attackers)
		{
			switch (Condition)
			{
				case EWinCondition::DefendersEliminated:
					return ECreditsGrantedReason::RoundWin;
				case EWinCondition::SpikeDetonated:
					return ECreditsGrantedReason::RoundWin;
				case EWinCondition::TimeExpired:
					return ECreditsGrantedReason::RoundLoss;
				case EWinCondition::SpikeDefused:
					return ECreditsGrantedReason::RoundLoss;
				case EWinCondition::AttackersEliminated:
					return ECreditsGrantedReason::RoundLoss;
				default:
					return ECreditsGrantedReason::RoundLoss;
			}
		}
		else if (Team == ETeam::Defenders)
		{
			switch (Condition)
			{
				case EWinCondition::DefendersEliminated:
					return ECreditsGrantedReason::RoundLoss;
				case EWinCondition::SpikeDetonated:
					return ECreditsGrantedReason::RoundLoss;
				case EWinCondition::TimeExpired:
					return ECreditsGrantedReason::RoundWin;
				case EWinCondition::SpikeDefused:
					return ECreditsGrantedReason::RoundWin;
				case EWinCondition::AttackersEliminated:
					return ECreditsGrantedReason::RoundWin;
				default:
					return ECreditsGrantedReason::RoundLoss;
			}
		}
		else if (Team == ETeam::None)
		{
			return ECreditsGrantedReason::None;
		}

		return ECreditsGrantedReason::None;
	}

	int GetCreditsForReason(ECreditsGrantedReason Reason)
	{
		switch (Reason)
		{
			case ECreditsGrantedReason::StartingCredits:
				return 800;
			case ECreditsGrantedReason::Kill:
				return 200;
			case ECreditsGrantedReason::PlantSpike:
				return 300;
			case ECreditsGrantedReason::RoundWin:
				return 3000;
			case ECreditsGrantedReason::RoundLoss:
				return 1900;
			case ECreditsGrantedReason::RoundLoss_2x:
				return 2400;
			case ECreditsGrantedReason::RoundLoss_3x_Onwards:
				return 2900;

			case ECreditsGrantedReason::None:
			default:
				return 0;
		}
	}

	UFUNCTION(Category = "Game Phase", CallInEditor)
	EGamePhase EndRound()
	{
		CurrentPhase = EGamePhase::RoundEnd;
		RoundEndTimeRemaining = RoundEndDuration;

		AllyScore++; // Temporary scoring logic for testing
		EnemyScore = Math::Max(AllyScore - 1, 0);
		Print(f"Score Update - Allies: {AllyScore} | Enemies: {EnemyScore}", 5, FLinearColor::Green);

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

		if (FreezeTimer)
			return;

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

UFUNCTION(BlueprintPure)
AAngelGameState GetAngelGameState()
{
	return Cast<AAngelGameState>(Gameplay::GetGameState());
}