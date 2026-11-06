namespace String
{
	/**
	 * Inserts a substring into a string at the specified index.
	 * Because angelscript doesn't have a built-in function for this.
	 */
	UFUNCTION(Category = "String")
	void Insert(FString&out InString, FString ToInsert, int Index)
	{
		if (Index < 0 || Index > InString.Len())
		{
			return;
		}
		InString = InString.Left(Index) + ToInsert + InString.RightChop(Index);
	}
}

namespace Credits
{
    UFUNCTION(BlueprintPure, Category = "UI | Economy")
	int GetCredits() property
	{
		AAngelPlayerState PlayerState = Game::PlayerState;
		return PlayerState.Credits;
	}
    
	UFUNCTION(BlueprintPure, Category = "UI | Economy", DisplayName = "Get Credits (Pretty)")
	FText GetCreditsFormatted() property
	{
		AAngelPlayerState PlayerState = Game::PlayerState;
		return Format(PlayerState.Credits);
	}

	UFUNCTION(BlueprintPure, Category = "UI | Economy", DisplayName = "Format Credits")
	FText Format(int Credits)
	{
		FString Pretty;

		FNumberFormattingOptions FormatOptions;
		FormatOptions.SetUseGrouping(false);
		FormatOptions.SetMaximumIntegralDigits(4);
		FormatOptions.SetMaximumFractionalDigits(0);
		Pretty = FText::AsNumber(Credits, FormatOptions).ToString();
		if (Credits >= 1000)
		{
			String::Insert(Pretty, ",", 1);
		}

		return FText::FromString(f"¤{Pretty}");
	}
}

namespace Hit
{
	UFUNCTION(BlueprintPure)
	bool WasAgentHit(FHitResult HitResult)
	{
		return IsValid(HitResult.Actor) && HitResult.Actor.IsA(AAngelAgent);
	}

	UFUNCTION(BlueprintPure)
	EBodyPart GetBodyPartHit(UPrimitiveComponent Component)
	{
		if (!IsValid(Component))
			return EBodyPart::Unknown;

		if (Component.ComponentTags.Contains(n"Head"))
		{
			return EBodyPart::Head;
		}
		else if (Component.ComponentTags.Contains(n"Body"))
		{
			return EBodyPart::Body;
		}
		else if (Component.ComponentTags.Contains(n"Legs"))
		{
			return EBodyPart::Legs;
		}

		return EBodyPart::Unknown;
	}
}

namespace Math
{
	UFUNCTION(BlueprintPure)
	float ToMeters(float DistanceInCm)
	{
		return DistanceInCm / 100.0f;
	}

	UFUNCTION(BlueprintPure, Category = "Math", Meta = (CompactNodeTitle = "Round", Keywords = "round,decimal,places"))
	float RoundTo(float Value, int DecimalPlaces)
	{
		float Multiplier = Math::Pow(10.0f, DecimalPlaces);
		return Math::RoundToFloat(Value * Multiplier) / Multiplier;
	}
}

namespace AbilitySystem
{
	UFUNCTION(BlueprintPure)
	UAngelscriptAbilitySystemComponent GetAngelscriptAbilitySystemComponent(AActor Actor)
	{
		return Cast<UAngelscriptAbilitySystemComponent>(AbilitySystem::GetAbilitySystemComponent(Actor));
	}
}

namespace Asserts
{
	/**
	 * Throws a blueprint exception.
	 */
	UFUNCTION(Category = "Asserts", DisplayName = "Throw", Meta = (CompactNodeTitle = "throw", DevelopmentOnly))
	void Throw(FString Message)
	{
#if EDITOR
		Print(f"Blueprint Exception: {Message}\n{Exception::GetFormattedCallStack()}", 8.0f, FLinearColor::Red);
#endif
	}

	/**
	 * Throws a blueprint exception.
	 */
	UFUNCTION(Category = "Asserts", Meta = (CompactNodeTitle = "throw", DevelopmentOnly))
	void ThrowIf(bool Condition, FString Message)
	{
#if EDITOR
		if (Condition)
			Print(f"Blueprint Exception: {Message}\n{Exception::GetFormattedCallStack()}", 8.0f, FLinearColor::Red);
#endif
	}

	UFUNCTION(Category = "Asserts", Meta = (DevelopmentOnly))
	bool Ensure(bool Condition, FString Message)
	{
		ThrowIf(Condition, Message);
		return Condition;
	}

	/** Throw a check exception. Intended for packaged builds. */
	UFUNCTION(Category = "Asserts", DisplayName = "Check")
	bool BP_Check(bool Condition, FString Message)
	{
		check(Condition, Message);
		return Condition;
	}
}

namespace Editor
{
	/**
	 * Whether the game is currently running in the editor.
	 */
	UFUNCTION(BlueprintPure, Category = "Editor", Meta = (CompactNodeTitle = "Editor", Keywords = "editor,pc,platform"))
	bool IsEditor()
	{
#if EDITOR
		return true;
#else
		return false;
#endif
	}

	UFUNCTION(DisplayName = "Is Editor (branch)", Category = "Editor", Meta = (ExpandBoolAsExecs = "ReturnValue", Keywords = "editor,pc,platform"))
	bool IsEditor_Branch()
	{
#if EDITOR
		return true;
#else
		return false;
#endif
	}
}

/* namespace AdvancedSessions
{
	UFUNCTION(BlueprintPure)
	bool HasSteamConnection()
	{
		return AdvancedSessions::HasOnlineSubsystem(n"STEAM");
	}
} */

/**
 * Returns the current NetMode as a string, because script is unable to return ENetMode for some reason.
 * @return NetMode as string.
 */
UFUNCTION(BlueprintPure, DisplayName = "Get NetMode (String)", Meta = (WorldContext = "Target"))
FString BP_GetNetModeAsString(const UObject Target)
{
	return f"{Target.World.GetNetMode():n}";
}

UFUNCTION(BlueprintPure, Meta = (WorldContext = "Target"))
bool IsNetModeClient(const UObject Target)
{
	return Target.World.GetNetMode() == ENetMode::NM_Client;
}

UFUNCTION(BlueprintPure, Meta = (WorldContext = "Target"))
bool IsNetModeListenServer(const UObject Target)
{
	return Target.World.GetNetMode() == ENetMode::NM_ListenServer;
}

UFUNCTION(BlueprintPure, Meta = (WorldContext = "Target"))
bool IsNetModeStandalone(const UObject Target)
{
	return Target.World.GetNetMode() == ENetMode::NM_Standalone;
}

namespace AController
{
	/**
	 * Returns whether this Controller is a local controller.
	 */
	UFUNCTION(DisplayName = "Is Local Controller (branch)", Category = "Pawn", Meta = (ExpandBoolAsExecs = "ReturnValue"))
	mixin bool IsLocalController(AController Controller)
	{
		return Controller.IsLocalController();
	}
}

namespace UGameplayAbility
{
	UFUNCTION(BlueprintPure)
	mixin AController GetAvatarController(UGameplayAbility Ability)
	{
		return Ability.GetAvatarActorFromActorInfo().AsPawn().Controller;
	}

	UFUNCTION(BlueprintPure)
	mixin AAngelPlayerController GetAvatarPlayerController(UGameplayAbility Ability)
	{
		return Cast<AAngelPlayerController>(Ability.GetAvatarActorFromActorInfo().AsPawn().Controller);
	}
}

/**
 * Call this in Tick to billboard this actor to the player's view.
 */
UFUNCTION(Category = "Utils")
mixin void BillboardActor(AActor& Actor)
{
	auto PC = Gameplay::GetPlayerController(0);
	if (!IsValid(PC))
		return;

	FVector CameraLocation;
	FRotator CameraRotation;
	PC.GetPlayerViewPoint(CameraLocation, CameraRotation);

	FVector ToCamera = CameraLocation - Actor.ActorLocation;
	Actor.ActorRotation = ToCamera.Rotation();
}

/**
 * Call this in Tick to billboard this scene component to the player's view.
 */
UFUNCTION(Category = "Utils")
mixin void BillboardComponent(USceneComponent SceneComponent)
{
	auto PC = Gameplay::GetPlayerController(0);
	if (!IsValid(PC))
		return;

	FVector CameraLocation;
	FRotator CameraRotation;
	PC.GetPlayerViewPoint(CameraLocation, CameraRotation);

	FVector ToCamera = CameraLocation - SceneComponent.WorldLocation;
	SceneComponent.WorldRotation = ToCamera.Rotation();
}

UFUNCTION(BlueprintPure, Category = "Conversion", Meta = (BlueprintAutocast))
FVector Conv_ActorToVector(AActor Input)
{
	return IsValid(Input) ? Input.ActorLocation : FVector::ZeroVector;
}

namespace FHitResult
{
	UFUNCTION(BlueprintPure)
	bool IsPrecisionHitFromHitResult(FHitResult Hit)
	{
		if (IsValid(Hit.Component))
		{
			if (Hit.Component.ComponentTags.Contains(n"Weakpoint"))
				return true;

			// fallback
			else if (Hit.Component.IsA(USkeletalMeshComponent))
			{
				return Hit.BoneName.IsEqual(n"head1") || Hit.BoneName.IsEqual(n"head");
			}
		}

		return false;
	}

	/**
	 * @return The actor that was hit in the HitResult. May be null!
	 */
	UFUNCTION(BlueprintPure, Category = "Hit Result")
	float GetDistance(FHitResult HitResult)
	{
		return HitResult.Distance;
	}

	/**
	 * @return The actor that was hit in the HitResult. May be null!
	 */
	UFUNCTION(BlueprintPure, Category = "Hit Result")
	AActor GetActor(FHitResult HitResult)
	{
		return HitResult.Actor;
	}

	/**
	 * The location in world space where the moving shape would end up against the impacted object, if there is a hit. Equal to the point of impact for line tests.
	 * Example: for a sphere trace test, this is the point where the center of the sphere would be located when it touched the other object.
	 * For swept movement (but not queries) this may not equal the final location of the shape since hits are pulled back slightly to prevent precision issues from over
	 */
	UFUNCTION(BlueprintPure, Category = "Hit Result")
	FVector GetLocation(FHitResult HitResult)
	{
		return HitResult.Location;
	}

	/**
	 * Location in world space of the actual contact of the trace shape (box, sphere, ray, etc) with the impacted object.
	 * Example: for a sphere trace test, this is the point where the surface of the sphere touches the other object.
	 * Note: In the case of initial overlap (bStartPenetrating=true), ImpactPoint will be the same as Location because there is no meaningful single impact point to report.
	 */
	UFUNCTION(BlueprintPure, Category = "Hit Result")
	FVector GetImpactPoint(FHitResult HitResult)
	{
		return HitResult.ImpactPoint;
	}
}

namespace Widget
{
	UFUNCTION(Category = "Widget")
	UUserWidget GetWidgetOfClass(TSubclassOf<UUserWidget> WidgetClass)
	{
		TArray<UUserWidget> Widgets;
		Widget::GetAllWidgetsOfClass(Widgets, WidgetClass, false);

		if (Widgets.IsValidIndex(0))
			return Widgets[0];

		return nullptr;
	}
}

/**
 * Set the location of a hit result.
 */
UFUNCTION(BlueprintPure, Category = "Hit Result")
mixin FHitResult SetLocation(FHitResult& HitResult, FVector Location)
{
	HitResult.Location = Location;
	return HitResult;
}

namespace GameplayTags
{
	const FGameplayTag None = FGameplayTag::RequestGameplayTag(n"None");
}

namespace Math
{
	/** This function returns 0 if B (the denominator) is zero. */
	float SafeDivide(float A, float B)
	{
		if (B == 0)
			return 0;
		return A / B;
	}
}

UFUNCTION(BlueprintPure, Category = "Actor | View Target")
mixin AActor GetLookedAtActor(APlayerController Player, float TraceDistance = 2500, FHitResult&out Hit = FHitResult())
{
	APlayerController PC = Cast<APlayerController>(Player);
	if (!IsValid(PC))
		return nullptr;

	FVector CameraLocation;
	FRotator CameraRotation;
	PC.GetPlayerViewPoint(CameraLocation, CameraRotation);

	FVector TraceEnd = CameraLocation + CameraRotation.ForwardVector * TraceDistance;

	FCollisionQueryParams Params;
	Params.AddIgnoredActor(PC.ControlledPawn);

	bool bHit = System::LineTraceSingleByChannel(
		Hit,
		CameraLocation,
		TraceEnd,
		ECollisionChannel::ECC_Camera,
		Params);

	return bHit ? Hit.GetActor() : nullptr;
}

mixin float32 ClampAndLog(UAngelscriptAttributeSet AttributeSet, FGameplayAttribute Attribute, float32 Value, float32 MinVal, float32 MaxVal, FString OptionalMessage = "")
{
	float32 Clamped = Math::Clamp(Value, MinVal, MaxVal);
	if (Clamped != Value)
	{
		Log(n"PreChange", f"Attribute '{Attribute.AttributeName}' clamped from {Value} to {Clamped} | {OptionalMessage}");
	}
	return Clamped;
}

UFUNCTION(BlueprintPure)
mixin bool ArePlayersNear(AActor NearActor, float MinDistance, TArray<AAngelAgent>&out NearbyAgents)
{
	for (TObjectPtr<APlayerState> Player : Gameplay::GetGameState().PlayerArray)
	{
		auto Agent = Cast<AAngelAgent>(Player.Get().Pawn);

		float Dist = NearActor.GetDistanceTo(Agent);
		if (Dist < MinDistance)
		{
			NearbyAgents.Add(Agent);
		}
	}

	return !NearbyAgents.IsEmpty();
}

UFUNCTION(BlueprintPure)
mixin bool HasLineOfSight(const APawn LineOfSightActor, const APawn OtherActor, bool bIsAIControlled = false)
{
	if (!IsValid(OtherActor))
		return false;

	return LineOfSightActor.Controller.LineOfSightTo(OtherActor, FVector(), bIsAIControlled);
}


namespace AgentUtils
{
	UFUNCTION(Category = "Game State", Meta = (ReturnDisplayName = "Found Agents"))
	bool GetAllAgents(TArray<AAngelAgent>&out Agents)
	{
		auto GS = Gameplay::GetGameState();

		for (auto PS : GS.PlayerArray)
		{
			auto Agent = Cast<AAngelAgent>(PS.Get().Pawn);
			Agents.Add(Agent);
		}

		return !Agents.IsEmpty();
	}
}

namespace Random
{
	// Rolls a X/Y chance. Example: DiceRoll(1, 6) -> ~16.7% chance.
	bool DiceRoll(float Numerator, float Denominator)
	{
		if (Denominator <= 0.0f)
			return false;

		float Roll = Math::RandRange(0.0f, Denominator);
		return Roll < Numerator;
	}

	// Rolls a X/Y chance and returns the raw roll value via the out parameter.
	bool DiceRoll(float Numerator, float Denominator, float&out Roll)
	{
		if (Denominator <= 0.0f)
		{
			Roll = 0.0f;
			return false;
		}

		Roll = Math::RandRange(0.0f, Denominator);
		return Roll < Numerator;
	}
}

/* -- ACTOR MIXINS -- */

mixin APawn AsPawn(AActor Actor)
{
	auto Result = Cast<APawn>(Actor);
	ThrowIf(Result == nullptr, f"Cast from {Actor.GetName()} to Pawn failed!");
	return Result;
}

mixin AAIController GetAIController(APawn Pawn)
{
	return AIHelper::GetAIController(Pawn);
}

// ~

UFUNCTION(Category = "Asset Editor", Meta = (DevelopmentOnly))
void OpenEditorForAsset(UObject Asset)
{
#if EDITOR
	TArray<UObject> Assets;
	Assets.Add(Asset);
	UAssetEditorSubsystem::Get().OpenEditorForAssets(Assets, EAssetTypeActivationOpenedMethod::Edit);
#endif
}

UFUNCTION(Category = "Asset Editor", Meta = (DevelopmentOnly))
void OpenEditorForAssetByClass(TSubclassOf<UObject> AssetClass)
{
	UObject Asset = LoadObject(nullptr, AssetClass.DefaultObject.GetPackage().GetPathName());

#if EDITOR
	TArray<UObject> Assets;
	Assets.Add(Asset);
	UAssetEditorSubsystem::Get().OpenEditorForAssets(Assets, EAssetTypeActivationOpenedMethod::Edit);
#endif
}

UFUNCTION(Category = "Asset", DisplayName = "Load Object")
UObject BP_LoadObject(TSubclassOf<UObject> Class)
{
	UObject Asset = LoadObject(nullptr, Class.DefaultObject.GetPackage().GetPathName());
	return Asset;
}