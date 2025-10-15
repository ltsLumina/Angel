class AAngelPlayerController : APlayerController
{
	UPROPERTY(DefaultComponent)
	UEnhancedInputComponent InputComponent;

	UPROPERTY(Category = "Input")
	UGunComponent GunComponent;

	UPROPERTY(Category = "Input")
	UReloadComponent ReloadComponent;

	UPROPERTY(Category = "Input")
	UInputAction MoveAction;

	UPROPERTY(Category = "Input")
	UInputAction ShootAction;

	UPROPERTY(Category = "Input")
	UInputAction ADS_Action;

	UPROPERTY(Category = "Input")
	UInputAction SwitchGunAction;

	UPROPERTY(Category = "Input")
	UInputAction AbilityAction;

	UPROPERTY(Category = "Input")
	UInputMappingContext IMC_Gameplay;

	UPROPERTY(Category = "Input")
	UInputMappingContext IMC_Shop;

	UPROPERTY(Category = "Shop", EditDefaultsOnly)
	TSubclassOf<UShopWidget> ShopWidgetClass;

	default CheatClass = UAngelCheatManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PushInputComponent(InputComponent);

		UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(this);
		EnhancedInputSubsystem.AddMappingContext(IMC_Gameplay, 0, FModifyContextOptions());

		AAngelPlayerCharacter Character = GetAngelCharacter(0);
		ReloadComponent = UReloadComponent::Get(Character);

		// Movement

		// Shooting
		InputComponent.BindAction(ShootAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"Fire"));

		// ADS (Aim Down Sights)
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"StartADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Canceled, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"CancelledADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"TriggeredADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"EndADS"));

		// Reloading
		InputComponent.BindKey(EKeys::R, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ReloadComponent, n"Reload"));

		// Gun Switching
		InputComponent.BindAction(SwitchGunAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"CycleGun"));
		InputComponent.BindKey(EKeys::AnyKey, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"SelectGun"));

		// Ability
		InputComponent.BindAction(AbilityAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(Character, n"UseAbility"));

		// -- menus

		InputComponent.BindKey(EKeys::B, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"ToggleShopInternal"));
	}

	float CycleGunCooldown = 0.2f;
	float CycleGunTimer = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CycleGunTimer > 0.0f)
		{
			CycleGunTimer -= DeltaSeconds;
		}
	}
	
	UFUNCTION(NotBlueprintCallable)
	void CycleGun(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
	{
		UHolsterComponent Holster = GetAngelCharacter(0).HolsterComponent;

		if (CycleGunTimer > 0.0f)
			return;

		float Direction = ActionValue.GetAxis1D();

		if (IsValid(Holster))
		{
			FString DirectionString = (Direction > 0) ? "Next" : "Previous";
			Print(f"Cycle gun with direction: {DirectionString}", 2, FLinearColor(0.15, 0.32, 0.52));
			Holster.CycleGun(Direction);
			CycleGunTimer = CycleGunCooldown;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void SelectGun(FKey Key)
	{
		UHolsterComponent Holster = GetAngelCharacter(0).HolsterComponent;
		if (!IsValid(Holster))
			return;

		int GunIndex = -1;
		if (Key == EKeys::One)
			GunIndex = 0;
		else if (Key == EKeys::Two)
			GunIndex = 1;
		else if (Key == EKeys::Three)
			GunIndex = 2;

		if (GunIndex >= 0 && GunIndex < Holster.HolsteredGuns.Num())
		{
			Holster.SwitchGun(GunIndex);
		}
	}

	UUserWidget ShopWidget;

	UFUNCTION(NotBlueprintCallable)
	private void ToggleShopInternal(FKey Key)
	{
		ToggleShop();
	}

	UFUNCTION(Category = "Shop")
	void ToggleShop(bool ForceClose = false)
	{
		auto GameState = GetAngelGameState();
		if (IsValid(GameState) && GameState.CurrentPhase != EGamePhase::BuyPhase)
		{
			PrintWarning("Can only open shop during Buy Phase!", 3);
			return;
		}

		if ((IsValid(ShopWidget) && ShopWidget.IsInViewport()))
		{
			ShopWidget.RemoveFromParent();
			ShopWidget = nullptr;

			bShowMouseCursor = false;
			Widget::SetInputMode_GameOnly(this, bFlushInput = false);
			SwitchMappingContext(this, IMC_Gameplay, 0);
		}
		else if (!ForceClose)
		{
			ShopWidget = WidgetBlueprint::CreateWidget(ShopWidgetClass, this);
			ShopWidget.AddToViewport();

			bShowMouseCursor = true;
			Widget::SetInputMode_GameAndUIEx(this, nullptr, EMouseLockMode::DoNotLock, false, bFlushInput = false);
			SwitchMappingContext(this, IMC_Shop, 0);
		}
	}
};

AAngelPlayerController GetAngelController(APawn Pawn)
{
	return Cast<AAngelPlayerController>(Pawn.GetController());
}

AAngelPlayerController GetAngelController(int PlayerIndex)
{
	return Cast<AAngelPlayerController>(Gameplay::GetPlayerController(PlayerIndex));
}

void SwitchMappingContext(APlayerController PC, UInputMappingContext NewContext, int Priority = 0)
{
	UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(PC);
	if (IsValid(EnhancedInputSubsystem))
	{
		EnhancedInputSubsystem.ClearAllMappings();
		EnhancedInputSubsystem.AddMappingContext(NewContext, Priority, FModifyContextOptions());
	}
	else
	{
		PrintError("Failed to get EnhancedInputLocalPlayerSubsystem!");
	}
}

void SwapMappingContext(APlayerController PC, UInputMappingContext OldContext, UInputMappingContext NewContext, int Priority = 0)
{
	UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(PC);
	if (IsValid(EnhancedInputSubsystem))
	{
		EnhancedInputSubsystem.RemoveMappingContext(OldContext, FModifyContextOptions());
		EnhancedInputSubsystem.AddMappingContext(NewContext, Priority, FModifyContextOptions());
	}
	else
	{
		PrintError("Failed to get EnhancedInputLocalPlayerSubsystem!");
	}
}

UFUNCTION(DisplayName = "Set Actor Label", Category = "Editor")
void BP_SetActorLabel(AActor Actor, FString NewLabel)
{
#if EDITOR
	if (IsValid(Actor))
	{
		Actor.SetActorLabel(NewLabel);
	}
#endif
}