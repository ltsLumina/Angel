// Copyright 2020 Dan Kestranek.


#include "Components/AngelCharacterMovementComponent.h"
#include "Framework/AngelCharacter.h"

float UAngelCharacterMovementComponentBase::GetMaxSpeed() const
{
	return BP_GetMaxSpeed();
}

bool UAngelCharacterMovementComponentBase::CanAttemptJump() const
{
	return BP_CanAttemptJump();
}

float UAngelCharacterMovementComponentBase::BP_GetMaxSpeed_Implementation() const
{
	checkf(true, TEXT("%s: should be implemented in script only!"), *FString(__FUNCTION__));
	return -1;
}

bool UAngelCharacterMovementComponentBase::BP_CanAttemptJump_Implementation() const
{
	checkf(true, TEXT("%s: should be implemented in script only!"), *FString(__FUNCTION__));
	return false;
}

void UAngelCharacterMovementComponentBase::UpdateFromCompressedFlags(uint8 Flags)
{
	Super::UpdateFromCompressedFlags(Flags);

	//The Flags parameter contains the compressed input flags that are stored in the saved move.
	//UpdateFromCompressed flags simply copies the flags from the saved move into the movement component.
	//It basically just resets the movement component to the state when the move was made so it can simulate from there.
	RequestToStartSprinting = (Flags & FSavedMove_Character::FLAG_Custom_0) != 0;

	RequestToStartADS = (Flags & FSavedMove_Character::FLAG_Custom_1) != 0;
}

FNetworkPredictionData_Client * UAngelCharacterMovementComponentBase::GetPredictionData_Client() const
{
	check(PawnOwner != nullptr);

	if (!ClientPredictionData)
	{
		UAngelCharacterMovementComponentBase* MutableThis = const_cast<UAngelCharacterMovementComponentBase*>(this);

		MutableThis->ClientPredictionData = new FAngelNetworkPredictionData_Client(*this);
		MutableThis->ClientPredictionData->MaxSmoothNetUpdateDist = 92.f;
		MutableThis->ClientPredictionData->NoSmoothNetUpdateDist = 140.f;
	}

	return ClientPredictionData;
}

void UAngelCharacterMovementComponentBase::StartSprinting()
{
	RequestToStartSprinting = true;
}

void UAngelCharacterMovementComponentBase::StopSprinting()
{
	RequestToStartSprinting = false;
}

void UAngelCharacterMovementComponentBase::StartAimDownSights()
{
	RequestToStartADS = true;
}

void UAngelCharacterMovementComponentBase::StopAimDownSights()
{
	RequestToStartADS = false;
}

void UAngelCharacterMovementComponentBase::FAngelSavedMove::Clear()
{
	Super::Clear();

	SavedRequestToStartSprinting = false;
	SavedRequestToStartADS = false;
}

uint8 UAngelCharacterMovementComponentBase::FAngelSavedMove::GetCompressedFlags() const
{
	uint8 Result = Super::GetCompressedFlags();

	if (SavedRequestToStartSprinting)
	{
		Result |= FLAG_Custom_0;
	}

	if (SavedRequestToStartADS)
	{
		Result |= FLAG_Custom_1;
	}

	return Result;
}

bool UAngelCharacterMovementComponentBase::FAngelSavedMove::CanCombineWith(const FSavedMovePtr & NewMove, ACharacter * Character, float MaxDelta) const
{
	//Set which moves can be combined together. This will depend on the bit flags that are used.
	if (SavedRequestToStartSprinting != ((FAngelSavedMove*)&NewMove)->SavedRequestToStartSprinting)
	{
		return false;
	}

	if (SavedRequestToStartADS != ((FAngelSavedMove*)&NewMove)->SavedRequestToStartADS)
	{
		return false;
	}

	return Super::CanCombineWith(NewMove, Character, MaxDelta);
}

void UAngelCharacterMovementComponentBase::FAngelSavedMove::SetMoveFor(ACharacter * Character, float InDeltaTime, FVector const & NewAccel, FNetworkPredictionData_Client_Character & ClientData)
{
	Super::SetMoveFor(Character, InDeltaTime, NewAccel, ClientData);

	UAngelCharacterMovementComponentBase* CharacterMovement = Cast<UAngelCharacterMovementComponentBase>(Character->GetCharacterMovement());
	if (CharacterMovement)
	{
		SavedRequestToStartSprinting = CharacterMovement->RequestToStartSprinting;
		SavedRequestToStartADS = CharacterMovement->RequestToStartADS;
	}
}

void UAngelCharacterMovementComponentBase::FAngelSavedMove::PrepMoveFor(ACharacter * Character)
{
	Super::PrepMoveFor(Character);

	UAngelCharacterMovementComponentBase* CharacterMovement = Cast<UAngelCharacterMovementComponentBase>(Character->GetCharacterMovement());
	if (CharacterMovement)
	{
	}
}

UAngelCharacterMovementComponentBase::FAngelNetworkPredictionData_Client::FAngelNetworkPredictionData_Client(const UCharacterMovementComponent & ClientMovement)
	: Super(ClientMovement)
{
}

FSavedMovePtr UAngelCharacterMovementComponentBase::FAngelNetworkPredictionData_Client::AllocateNewMove()
{
	return FSavedMovePtr(new FAngelSavedMove());
}