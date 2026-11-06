// Copyright 'Team PONDAGON' - All rights reserved.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "EditorGraphFunctionLibrary.generated.h"

class UBlueprint;
class UEdGraphNode;

UCLASS()
class ANGEL_API UEditorGraphFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/** Returns true if any graph in the Blueprint calls the specified Function Name */
	UFUNCTION(BlueprintCallable, Category = "Editor|GraphUtils", meta = (DevelopmentOnly))
	static bool HasFunctionCall(UBlueprint* Blueprint, FName FunctionName);

	/** Returns true if any graph in the Blueprint contains the specified Event Name */
	UFUNCTION(BlueprintCallable, Category = "Editor|GraphUtils", meta = (DevelopmentOnly))
	static bool HasEventNode(UBlueprint* Blueprint, FName EventName);

	/** Finds all nodes of a specific class (e.g., K2Node_Event) */
	UFUNCTION(BlueprintCallable, Category = "Editor|GraphUtils", meta = (DevelopmentOnly))
	static void GetNodesOfClass(UBlueprint* Blueprint, TSubclassOf<UEdGraphNode> NodeClass, TArray<UEdGraphNode*>& OutNodes);

	/** Checks if a specific node has any active connections on its pins */
	UFUNCTION(BlueprintCallable, Category = "Editor|GraphUtils", meta = (DevelopmentOnly))
	static bool IsNodeConnected(UEdGraphNode* Node);
};
