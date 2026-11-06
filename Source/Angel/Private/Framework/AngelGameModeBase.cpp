// Copyright 'Team PONDAGON' - All rights reserved.


#include "Framework/AngelGameModeBase.h"

void AAngelGameModeBase::PostSeamlessTravel()
{
	Super::PostSeamlessTravel();
	BP_PostSeamlessTravel();
}

void AAngelGameModeBase::HandleSeamlessTravelPlayer(AController*& C)
{
	Super::HandleSeamlessTravelPlayer(C);
	BP_HandleSeamlessTravelPlayer(C);
}


UClass* AAngelGameModeBase::GetDefaultPawnClassForController_Implementation(AController* InController)
{
	if (const auto PawnClass = BP_GetDefaultPawnClassForController(InController))
	{
		return PawnClass;
	}
	
	// fallback
	return Super::GetDefaultPawnClassForController_Implementation(InController);
}
