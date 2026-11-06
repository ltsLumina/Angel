// Copyright 'Team PONDAGON' - All rights reserved.


#include "FunctionLibraries/WorldBlueprintLibrary.h"

FString UWorldBlueprintLibrary::GetMapName(const UObject* WorldContextObject)
{
	if (const UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull))
	{
		return World->GetMapName();
	}
	return FString();
}

FString UWorldBlueprintLibrary::GetNiceMapName(const UObject* WorldContextObject)
{
	if (const UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull))
	{
		// Credit: @Ixiguis on UnrealEngine forums.
		FString LevelName = World->GetMapName();
		LevelName.RemoveFromStart(World->StreamingLevelsPrefix);
		return LevelName;
	}
	return FString();
}
