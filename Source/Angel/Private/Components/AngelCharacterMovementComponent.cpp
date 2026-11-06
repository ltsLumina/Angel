// Copyright 2020 Dan Kestranek.


#include "Components/AngelCharacterMovementComponent.h"
#include "Framework/AngelCharacter.h"

float UAngelCharacterMovementComponent::GetMaxSpeed() const
{
	return BP_GetMaxSpeed();
}

bool UAngelCharacterMovementComponent::CanAttemptJump() const
{
	return BP_CanAttemptJump();
}

float UAngelCharacterMovementComponent::BP_GetMaxSpeed_Implementation() const
{
	checkf(true, TEXT("%s: should be implemented in script only!"), *FString(__FUNCTION__));
	return -1;
}

bool UAngelCharacterMovementComponent::BP_CanAttemptJump_Implementation() const
{
	checkf(true, TEXT("%s: should be implemented in script only!"), *FString(__FUNCTION__));
	return false;
}

void UAngelCharacterMovementComponent::UpdateFromCompressedFlags(uint8 Flags)
{
	Super::UpdateFromCompressedFlags(Flags);

	//The Flags parameter contains the compressed input flags that are stored in the saved move.
	//UpdateFromCompressed flags simply copies the flags from the saved move into the movement component.
	//It basically just resets the movement component to the state when the move was made so it can simulate from there.
	RequestToStartSprinting = (Flags & FSavedMove_Character::FLAG_Custom_0) != 0;

	RequestToStartADS = (Flags & FSavedMove_Character::FLAG_Custom_1) != 0;
}

FNetworkPredictionData_Client * UAngelCharacterMovementComponent::GetPredictionData_Client() const
{
	check(PawnOwner != nullptr);

	if (!ClientPredictionData)
	{
		UAngelCharacterMovementComponent* MutableThis = const_cast<UAngelCharacterMovementComponent*>(this);

		MutableThis->ClientPredictionData = new FAngelNetworkPredictionData_Client(*this);
		MutableThis->ClientPredictionData->MaxSmoothNetUpdateDist = 92.f;
		MutableThis->ClientPredictionData->NoSmoothNetUpdateDist = 140.f;
	}

	return ClientPredictionData;
}

void UAngelCharacterMovementComponent::StartSprinting()
{
	RequestToStartSprinting = true;
}

void UAngelCharacterMovementComponent::StopSprinting()
{
	RequestToStartSprinting = false;
}

void UAngelCharacterMovementComponent::StartAimDownSights()
{
	RequestToStartADS = true;
}

void UAngelCharacterMovementComponent::StopAimDownSights()
{
	RequestToStartADS = false;
}

void UAngelCharacterMovementComponent::FAngelSavedMove::Clear()
{
	Super::Clear();

	SavedRequestToStartSprinting = false;
	SavedRequestToStartADS = false;
}

uint8 UAngelCharacterMovementComponent::FAngelSavedMove::GetCompressedFlags() const
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

bool UAngelCharacterMovementComponent::FAngelSavedMove::CanCombineWith(const FSavedMovePtr & NewMove, ACharacter * Character, float MaxDelta) const
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

void UAngelCharacterMovementComponent::FAngelSavedMove::SetMoveFor(ACharacter * Character, float InDeltaTime, FVector const & NewAccel, FNetworkPredictionData_Client_Character & ClientData)
{
	Super::SetMoveFor(Character, InDeltaTime, NewAccel, ClientData);

	UAngelCharacterMovementComponent* CharacterMovement = Cast<UAngelCharacterMovementComponent>(Character->GetCharacterMovement());
	if (CharacterMovement)
	{
		SavedRequestToStartSprinting = CharacterMovement->RequestToStartSprinting;
		SavedRequestToStartADS = CharacterMovement->RequestToStartADS;
	}
}

void UAngelCharacterMovementComponent::FAngelSavedMove::PrepMoveFor(ACharacter * Character)
{
	Super::PrepMoveFor(Character);

	UAngelCharacterMovementComponent* CharacterMovement = Cast<UAngelCharacterMovementComponent>(Character->GetCharacterMovement());
	if (CharacterMovement)
	{
	}
}

UAngelCharacterMovementComponent::FAngelNetworkPredictionData_Client::FAngelNetworkPredictionData_Client(const UCharacterMovementComponent & ClientMovement)
	: Super(ClientMovement)
{
}

FSavedMovePtr UAngelCharacterMovementComponent::FAngelNetworkPredictionData_Client::AllocateNewMove()
{
	return FSavedMovePtr(new FAngelSavedMove());
}