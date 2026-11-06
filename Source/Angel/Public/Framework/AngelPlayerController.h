// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "AngelPlayerController.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, BlueprintType)
class ANGEL_API AAngelPlayerControllerBase : public APlayerController
{
	GENERATED_BODY()

public:
	virtual void OnPossess(APawn* InPawn) override;
	/**
	 * <summary>
	 * Server-side possession. Use for server init that requires a pawn.
	 * </summary>
	 * <param name="InPawn"></param>
	 */
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_OnPossess(APawn* InPawn);

	virtual void AcknowledgePossession(class APawn* P) override;
	/**
	 * <summary>
	 * Most reliable client hook for input setup. LocalPlayer and EnhancedInput subsystems are valid here.
	 * </summary>
	 * <param name="P"></param>
	 */
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_AcknowledgePossession(class APawn* P);

	virtual void OnRep_PlayerState() override;
	/**
	 * <summary>
	 * PlayerState arrives late — use as fallback alongside AcknowledgePossession.
	 * </summary>
	 */
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_OnRep_PlayerState();
	
	/**
	 * Calling this enables you to add cheats on a client when `bForce == true`.
	 * @param bForce 
	 */
	UFUNCTION(ScriptCallable)
	void BP_AddCheats(bool bForce = false);

	UFUNCTION(ScriptCallable)
	virtual void BP_FlushLevelStreaming();
	
	DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnPlayerStateReady, APlayerState*, PlayerState);
	
	UPROPERTY(BlueprintAssignable)
	FOnPlayerStateReady OnPlayerStateReady;
};
