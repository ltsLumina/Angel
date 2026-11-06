// Copyright 'Team PONDAGON' - All rights reserved.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "WorldBlueprintLibrary.generated.h"

/**
 * 
 */
UCLASS()
class ANGEL_API UWorldBlueprintLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
	UFUNCTION(BlueprintPure, ScriptCallable)
	static FString GetMapName(const UObject* WorldContextObject);
	
	UFUNCTION(BlueprintPure, ScriptCallable)
	static FString GetNiceMapName(const UObject* WorldContextObject);
};
