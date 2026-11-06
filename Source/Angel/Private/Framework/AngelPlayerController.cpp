// Fill out your copyright notice in the Description page of Project Settings.


#include "Framework/AngelPlayerController.h"

void AAngelPlayerControllerBase::OnPossess(APawn* InPawn)
{
	Super::OnPossess(InPawn);
	BP_OnPossess(InPawn);
}

void AAngelPlayerControllerBase::AcknowledgePossession(class APawn* P)
{
	Super::AcknowledgePossession(P);
	BP_AcknowledgePossession(P);
}

void AAngelPlayerControllerBase::OnRep_PlayerState()
{
	Super::OnRep_PlayerState();
	BP_OnRep_PlayerState();
	OnPlayerStateReady.Broadcast(PlayerState);
}

void AAngelPlayerControllerBase::BP_AddCheats(bool bForce)
{
	Super::AddCheats(bForce);
}

void AAngelPlayerControllerBase::BP_FlushLevelStreaming()
{
	ClientFlushLevelStreaming_Implementation();
}
