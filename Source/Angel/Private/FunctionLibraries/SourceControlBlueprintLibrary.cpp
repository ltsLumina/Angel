// Copyright 'Team PONDAGON' - All rights reserved.

#include "FunctionLibraries/SourceControlBlueprintLibrary.h"
#if WITH_EDITOR
#include "Diversion/Private/CustomWidgets/DiversionCommitHelper.h"
#endif

void USourceControlBlueprintLibrary::OpenCommitWindow()
{
#if WITH_EDITOR
	FDiversionCommitHelper::ExecuteCommit();
#endif
}
