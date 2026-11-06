#include "BlueprintExceptionLibrary.h"
#if WITH_EDITOR
#include "Editor.h"
#include "Blueprint/BlueprintExceptionInfo.h"
#include "Misc/AssertionMacros.h"
#endif

FString UBlueprintExceptionLibrary::GetCallStack()
{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST || USE_LOGGING_IN_SHIPPING)
	FString ScriptStack = FFrame::GetScriptCallstack();
	return ScriptStack;
#else
	return TEXT("Callstack is unavailable in Shipping builds.");
#endif
}

FString UBlueprintExceptionLibrary::GetFormattedCallStack()
{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST || USE_LOGGING_IN_SHIPPING)
	FString ScriptStack = FFrame::GetScriptCallstack();
	ScriptStack.ReplaceInline(TEXT("/Game/"), TEXT(""));

	// Remove everything before the first triple-hyphen '---' (inclusive)
	{
		int32 SepIndex = ScriptStack.Find(TEXT("---"), ESearchCase::IgnoreCase, ESearchDir::FromStart);
		if (SepIndex != INDEX_NONE)
		{
			// Keep everything after the '---'
			ScriptStack = ScriptStack.Mid(SepIndex + 3);
			// Trim any leading whitespace/newlines that may follow
			ScriptStack = ScriptStack.TrimStart();
		}
	}

	// Remove any code between two periods, e.g., .BP_FishCharacter.BP_FishCharacter_C.
	{
		FString Result;
		int32 Len = ScriptStack.Len();
		int32 i = 0;
		while (i < Len)
		{
			TCHAR C = ScriptStack[i];
			if (C == TEXT('.'))
			{
				// Find next dot
				int32 NextDot = INDEX_NONE;
				for (int32 k = i + 1; k < Len; ++k)
				{
					if (ScriptStack[k] == TEXT('.'))
					{
						NextDot = k;
						break;
					}
				}

				// If there's text between two dots, collapse the whole segment to a single dot
				if (NextDot != INDEX_NONE && NextDot > i + 1)
				{
					Result += TEXT('.');
					i = NextDot + 1;
					continue;
				}
				else
				{
					// Either consecutive dots or no closing dot: keep the dot as-is
					Result += TEXT('.');
					i++;
					continue;
				}
			}

			// Regular character: append
			Result.AppendChar(C);
			i++;
		}

		ScriptStack = MoveTemp(Result);
		
		// Remove any trailing newlines
		ScriptStack = ScriptStack.TrimEnd();
		ScriptStack.ReplaceInline(TEXT("\r\n"), TEXT("\n"));
	}

	return ScriptStack;
#else
	return TEXT("Callstack is unavailable in Shipping builds.");
#endif
}

void UBlueprintExceptionLibrary::BlueprintAssert(UObject* Target, const FString Message, const bool Breakpoint)
{
#if WITH_EDITOR
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST || USE_LOGGING_IN_SHIPPING)
	check(Target);
	
	const FString ProblemBlueprint = Target->GetName();
	const FString HasBreakpointMessage = FString::Printf(TEXT("Assert Failed in Blueprint \"%s\":\n%s\n\nPress Retry to go to Blueprint. Otherwise, press Continue to keep playing."), *ProblemBlueprint, *Message);
	const FString NoBreakpointMessage = FString::Printf(TEXT("Assert Failed in Blueprint \"%s\":\n%s\n\nPress Ok to keep playing."), *ProblemBlueprint, *Message);
	const FText Description = FText::FromString(Breakpoint ? HasBreakpointMessage : NoBreakpointMessage);

	// If Breakpoint is false, we can skip showing the "Retry" option since it won't do anything.
	const EAppMsgType::Type MsgType = Breakpoint ? EAppMsgType::CancelRetryContinue : EAppMsgType::Ok;
	
	switch (FMessageDialog::Open(EAppMsgCategory::Warning, MsgType, Description, FText::FromString("Assert Failed")))
	{
	case EAppReturnType::Cancel: // STOP PLAYING
			// Prompt user if they're sure they want to stop playing.
			if (FMessageDialog::Open(EAppMsgCategory::Warning, EAppMsgType::YesNo, FText::FromString(TEXT("Do you want to end PIE? (Stop Playing)")), FText::FromString("Assert Failed")) == EAppReturnType::Yes)
			{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST || USE_LOGGING_IN_SHIPPING)
				if (GEditor)
				{
					GEditor->RequestEndPlayMap();
				}
#endif
			}
			else // loop back to the start of the function.
			{
				BlueprintAssert(Target, Message, Breakpoint);
			}
			break;
		
	case EAppReturnType::Retry: // GO TO BLUEPRINT w/ DEBUGGER
		if (Breakpoint)
		{
			// Must be called before throwing the exception, otherwise the window won't open unless you continue blueprint execution or end PIE.
			const auto Tab = FGlobalTabmanager::Get()->TryInvokeTab(FName("BlueprintDebugger"), false);
		
			const FBlueprintExceptionInfo BreakpointExceptionInfo(EBlueprintExceptionType::Breakpoint, Description);
			FBlueprintCoreDelegates::ThrowScriptException(Target, *FBlueprintContextTracker::Get().GetCurrentScriptStackWritable().Last(), BreakpointExceptionInfo);
		}
		break;
		
	case EAppReturnType::Ok:
	case EAppReturnType::Continue: //  KEEP PLAYING
	default:
		break;
	}
#else
	// do nothing in shipping
#endif
#endif
}
