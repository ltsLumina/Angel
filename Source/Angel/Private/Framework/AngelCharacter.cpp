// Fill out your copyright notice in the Description page of Project Settings.


#include "Framework/AngelCharacter.h"
#include "Components/AngelCharacterMovementComponent.h"
#include "Components/CapsuleComponent.h"

AAngelCharacterBase::AAngelCharacterBase(const class FObjectInitializer& ObjectInitializer) :
	Super(ObjectInitializer.SetDefaultSubobjectClass<UAngelCharacterMovementComponentBase>(CharacterMovementComponentName))
{
	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	
	GetCapsuleComponent()->SetCollisionResponseToChannel(ECC_Visibility, ECR_Overlap);

	bAlwaysRelevant = true;
}

// Called when the game starts or when spawned
void AAngelCharacterBase::BeginPlay()
{
	Super::BeginPlay();
}

// Called every frame
void AAngelCharacterBase::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
}

// Called to bind functionality to input
void AAngelCharacterBase::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
}

// Netcode Init

void AAngelCharacterBase::PossessedBy(AController* NewController)
{
	Super::PossessedBy(NewController);
	BP_PossessedBy(NewController);
}

void AAngelCharacterBase::OnRep_PlayerState()
{
	Super::OnRep_PlayerState();
	BP_OnRep_PlayerState();
}

void AAngelCharacterBase::OnRep_Controller()
{
	Super::OnRep_Controller();
	BP_OnRep_Controller();
}

