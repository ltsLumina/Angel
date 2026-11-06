// Copyright 'Team PONDAGON' - All rights reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "AngelGameModeBase.generated.h"

/**
 * 
 */
UCLASS()
class ANGEL_API AAngelGameModeBase : public AGameModeBase
{
	GENERATED_BODY()
	
protected:
	
	virtual void PostSeamlessTravel() override;
	/**
	 * Called after a seamless level transition has been completed on the *new* GameMode.
	 * Used to reinitialize players already in the game as they won't have *Login() called on them
	 */
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_PostSeamlessTravel();
	
	virtual void HandleSeamlessTravelPlayer(AController*& C) override;
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_HandleSeamlessTravelPlayer(AController* NewController);

	virtual UClass* GetDefaultPawnClassForController_Implementation(AController* InController) override;
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	UClass* BP_GetDefaultPawnClassForController(AController* InController);
};
