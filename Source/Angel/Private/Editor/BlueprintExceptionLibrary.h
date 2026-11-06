#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "BlueprintExceptionLibrary.generated.h"

UCLASS()
class ANGEL_API UBlueprintExceptionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(ScriptCallable, meta=(DevelopmentOnly))
	static FString GetCallStack();
	
	UFUNCTION(ScriptCallable, meta=(DevelopmentOnly))
	static FString GetFormattedCallStack();

	/**
	 * Throws a Blueprint exception with a custom message. 
	 * This will display a warning dialog in the editor when the assertion fails, giving you the option to break into the Blueprint Debugger or continue execution.
	 * 
	 * Adapted from the Epic Games Community tutorial by Neren69420:
	 * "Implementing Blueprint Asserts in C": https://dev.epicgames.com/community/learning/tutorials/1lOj/unreal-engine-implementing-blueprint-asserts-in-c
	 * 
	 * @remark Inspired by the UnrealFest Stockholm 2025 talk by Sandfall Interactive. 
	 * @param Target
	 * @param Message A message to display in the log if the assertion fails.
	 * @param Breakpoint If true, execution will break at the point of the assertion failure and open the BlueprintDebugger, showing a full call stack and allowing you to inspect variables. If false, the warning dialog shows only an "OK" option that will dismiss the dialog and continue execution.
	 */
	UFUNCTION(BlueprintCallable, meta=(DevelopmentOnly, DefaultToSelf="Target", HidePin="Target"))
	static void BlueprintAssert(UObject* Target, FString Message, bool Breakpoint = true);
};
