// Copyright 2020 Dan Kestranek.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "AngelCharacterMovementComponent.generated.h"

/**
 * 
 */
UCLASS()
class ANGEL_API UAngelCharacterMovementComponent : public UCharacterMovementComponent
{
	GENERATED_BODY()
	
	class FAngelSavedMove : public FSavedMove_Character
	{
	public:

		typedef FSavedMove_Character Super;

		///@brief Resets all saved variables.
		virtual void Clear() override;

		///@brief Store input commands in the compressed flags.
		virtual uint8 GetCompressedFlags() const override;

		///@brief This is used to check whether or not two moves can be combined into one.
		///Basically you just check to make sure that the saved variables are the same.
		virtual bool CanCombineWith(const FSavedMovePtr& NewMove, ACharacter* Character, float MaxDelta) const override;

		///@brief Sets up the move before sending it to the server. 
		virtual void SetMoveFor(ACharacter* Character, float InDeltaTime, FVector const& NewAccel, class FNetworkPredictionData_Client_Character & ClientData) override;
		///@brief Sets variables on character movement component before making a predictive correction.
		virtual void PrepMoveFor(class ACharacter* Character) override;

		// Sprint
		uint8 SavedRequestToStartSprinting : 1;

		// Aim Down Sights
		uint8 SavedRequestToStartADS : 1;
	};

	class FAngelNetworkPredictionData_Client : public FNetworkPredictionData_Client_Character
	{
	public:
		FAngelNetworkPredictionData_Client(const UCharacterMovementComponent& ClientMovement);

		typedef FNetworkPredictionData_Client_Character Super;

		///@brief Allocates a new copy of our custom saved move
		virtual FSavedMovePtr AllocateNewMove() override;
	};

public:
	/**
	 * Native property.
	 */
	UPROPERTY(ScriptReadOnly)
	uint8 RequestToStartSprinting : 1;
	/**
	* Native property.
	*/
	UPROPERTY(ScriptReadOnly)
	uint8 RequestToStartADS : 1;

	virtual float GetMaxSpeed() const override;
	
	virtual bool CanAttemptJump() const override;

protected:
	/**
	 * @remarks Overriden in AS.
	 * @remarks Do not override in C++.
	 */
	UFUNCTION(BlueprintNativeEvent)
	float BP_GetMaxSpeed() const;
	
	
	/**
	 * @remarks Overriden in AS.
	 * @remarks Do not override in C++.
	 */
	UFUNCTION(BlueprintNativeEvent)
	bool BP_CanAttemptJump() const;
	
	virtual void UpdateFromCompressedFlags(uint8 Flags) override;
	virtual class FNetworkPredictionData_Client* GetPredictionData_Client() const override;

/**
	 * Native function.
	 */
	UFUNCTION(ScriptCallable, Category = "Sprint")
	void StartSprinting();
	
	/**
	 * Native function.
	 */
	UFUNCTION(ScriptCallable, Category = "Sprint")
	void StopSprinting();

	/**
	 * Native function.
	 */
	UFUNCTION(ScriptCallable, Category = "Aim Down Sights")
	void StartAimDownSights();
	
	/**
	 * Native function.
	 */
	UFUNCTION(ScriptCallable, Category = "Aim Down Sights")
	void StopAimDownSights();
};