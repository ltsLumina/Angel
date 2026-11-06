// Copyright 'Team PONDAGON' - All rights reserved.


#include "EditorGraphFunctionLibrary.h"
#if WITH_EDITOR
#include "K2Node_CallFunction.h"
#include "K2Node_Event.h"
#include "EdGraph/EdGraph.h"
#endif

bool UEditorGraphFunctionLibrary::HasFunctionCall(UBlueprint* Blueprint, FName FunctionName)
{
#if WITH_EDITOR
	if (!Blueprint) return false;

	TArray<UEdGraph*> AllGraphs;
	Blueprint->GetAllGraphs(AllGraphs);

	for (UEdGraph* Graph : AllGraphs)
	{
		for (UEdGraphNode* Node : Graph->Nodes)
		{
			if (UK2Node_CallFunction* CallNode = Cast<UK2Node_CallFunction>(Node))
			{
				if (CallNode->GetFunctionName() == FunctionName) return true;
			}
		}
	}
#endif
	return false;
}

bool UEditorGraphFunctionLibrary::HasEventNode(UBlueprint* Blueprint, FName EventName)
{
#if WITH_EDITOR
	if (!Blueprint) return false;

	TArray<UEdGraph*> AllGraphs;
	Blueprint->GetAllGraphs(AllGraphs);

	for (UEdGraph* Graph : AllGraphs)
	{
		for (UEdGraphNode* Node : Graph->Nodes)
		{
			if (const UK2Node_Event* EventNode = Cast<UK2Node_Event>(Node))
			{
				if (EventNode->EventReference.GetMemberName() == EventName) return true;
			}
		}
	}
#endif
	return false;
}

void UEditorGraphFunctionLibrary::GetNodesOfClass(UBlueprint* Blueprint, TSubclassOf<UEdGraphNode> NodeClass, TArray<UEdGraphNode*>& OutNodes)
{
#if WITH_EDITOR
	OutNodes.Empty();
	if (!Blueprint || !NodeClass) return;

	TArray<UEdGraph*> AllGraphs;
	Blueprint->GetAllGraphs(AllGraphs);

	for (UEdGraph* Graph : AllGraphs)
	{
		for (UEdGraphNode* Node : Graph->Nodes)
		{
			if (Node && Node->IsA(NodeClass))
			{
				OutNodes.Add(Node);
			}
		}
	}
#endif
}

bool UEditorGraphFunctionLibrary::IsNodeConnected(UEdGraphNode* Node)
{
#if WITH_EDITOR
	if (!Node) return false;

	for (UEdGraphPin* Pin : Node->Pins)
	{
		if (Pin->LinkedTo.Num() > 0) return true;
	}
#endif
	return false;
}
