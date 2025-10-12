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
	UInputAction InventoryAction;

	UPROPERTY(Category = "Input")
	UInputAction SwitchGunAction;

	UPROPERTY(Category = "Input")
	UInputMappingContext Context;

	UPROPERTY(Category = "Shop", EditDefaultsOnly)
	TSubclassOf<UShopWidget> ShopWidgetClass;

	default CheatClass = UAngelCheatManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PushInputComponent(InputComponent);

		UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(this);
		EnhancedInputSubsystem.AddMappingContext(Context, 0, FModifyContextOptions());

		AAngelPlayerCharacter Character = GetAngelCharacter(0);
		ReloadComponent = UReloadComponent::Get(Character);

		// Movement

		// Shooting
		InputComponent.BindAction(ShootAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"Fire"));

		// ADS (Aim Down Sights)
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"StartADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Canceled, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"CancelledADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"OnADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"EndADS"));

		// Reloading
		InputComponent.BindKey(EKeys::R, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ReloadComponent, n"Reload"));

		// UI/Inventory
		InputComponent.BindAction(InventoryAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"ToggleInventory"));

		// Gun Switching
		InputComponent.BindAction(SwitchGunAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"CycleGun"));
		InputComponent.BindKey(EKeys::AnyKey, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"SelectGun"));

		// -- menus

		InputComponent.BindKey(EKeys::B, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"ToggleShop"));
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
	void ToggleInventory(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
	{
		Print(f"Toggled inventory!");
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

		if (GunIndex >= 0 && GunIndex < Holster.Guns.Num())
		{
			Holster.SwitchGun(GunIndex);
		}
	}

	UUserWidget ShopWidget;

	UFUNCTION()
	void ToggleShop(FKey Key)
	{
        auto GameState = GetAngelGameState();
        if (IsValid(GameState) && GameState.CurrentPhase != EGamePhase::BuyPhase)
        {
            PrintWarning("Can only open shop during Buy Phase!", 3);
            return;
        }

		if (IsValid(ShopWidget) && ShopWidget.IsInViewport())
		{
			ShopWidget.RemoveFromParent();

			Widget::SetInputMode_GameOnly(this, true);
			EnableInput(this);
			bShowMouseCursor = false;
			return;
		}

		ShopWidget = WidgetBlueprint::CreateWidget(ShopWidgetClass, this);
		ShopWidget.AddToViewport();
		Widget::SetInputMode_UIOnlyEx(this, ShopWidget, EMouseLockMode::LockInFullscreen);
		DisableInput(this);
		bShowMouseCursor = true;
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
