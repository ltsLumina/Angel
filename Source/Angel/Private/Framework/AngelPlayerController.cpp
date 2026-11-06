// Fill out your copyright notice in the Description page of Project Settings.


#include "Framework/AngelPlayerController.h"

void AAngelPlayerController::OnPossess(APawn* InPawn)
{
	Super::OnPossess(InPawn);
	BP_OnPossess(InPawn);
}

void AAngelPlayerController::AcknowledgePossession(class APawn* P)
{
	Super::AcknowledgePossession(P);
	BP_AcknowledgePossession(P);
}

void AAngelPlayerController::OnRep_PlayerState()
{
	Super::OnRep_PlayerState();
	BP_OnRep_PlayerState();
	OnPlayerStateReady.Broadcast(PlayerState);
}

void AAngelPlayerController::BP_AddCheats(bool bForce)
{
	Super::AddCheats(bForce);
}

void AAngelPlayerController::BP_FlushLevelStreaming()
{
	ClientFlushLevelStreaming_Implementation();
}
