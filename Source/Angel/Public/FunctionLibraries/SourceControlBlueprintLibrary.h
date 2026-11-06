// Copyright 'Team PONDAGON' - All rights reserved.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "SourceControlBlueprintLibrary.generated.h"

/**
 * 
 */
UCLASS()
class ANGEL_API USourceControlBlueprintLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
	UFUNCTION(ScriptCallable, meta=(DevelopmentOnly))
	static void OpenCommitWindow();
};
