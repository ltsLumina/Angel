// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AngelscriptGASCharacter.h"
#include "AngelCharacter.generated.h"

UCLASS()
class ANGEL_API AAngelCharacterBase : public AAngelscriptGASCharacter
{
	GENERATED_BODY()

public:
	explicit AAngelCharacterBase(const class FObjectInitializer& ObjectInitializer);
	
protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	/**
	 * <summary>
	 * Primary hook for server-side init. PlayerState may not be set yet in edge cases — check for null.
	 * </summary>
	 * <param name="NewController"></param>
	 */
	virtual void PossessedBy(AController* NewController) override;
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_PossessedBy(AController* NewController);

	/**
	 * <summary>
	 * Fires when PlayerState replicates to this character. Controller may still be null.
	 * </summary>
	 */
	virtual void OnRep_PlayerState() override;
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_OnRep_PlayerState();

	/**
	 * <summary>
	 * Fires when controller replicates. PlayerState may still be null.
	 * </summary>
	 */
	virtual void OnRep_Controller() override;
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void BP_OnRep_Controller();
};
