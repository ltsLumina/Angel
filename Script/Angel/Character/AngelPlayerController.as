class AAngelPlayerController : AAngelPlayerControllerBase
{
	UPROPERTY(DefaultComponent, NotVisible, BlueprintReadOnly)
	UEnhancedInputComponent InputComponent;

	UPROPERTY(Category = "Components", DefaultComponent)
	UGunComponent GunComponent;

	UPROPERTY(Category = "Components", DefaultComponent)
	UReloadComponent ReloadComponent;

	UPROPERTY(Category = "Components", BindComponent)
	UHolsterComponent HolsterComponent;

	UPROPERTY(Category = "Components", DefaultComponent)
	UADSComponent ADSComponent;

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

	UFUNCTION()
	void Push()
	{
		PushInputComponent(InputComponent);
	}

	UFUNCTION()
	void Pop()
	{
		PopInputComponent(InputComponent);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(BlueprintOverride)
	void ReceivePossess(APawn PossessedPawn)
	{
		System::SetTimerForNextTick(this, "Init");
	}

	UFUNCTION(NotBlueprintCallable)
	private void Init()
	{
		if (!IsLocalController())
			return;

		InitInputs();

		SetupInputEvents();
	}

	void InitInputs()
	{
		ThrowIf(IMC_Gameplay == nullptr, "IMC_Gameplay is required!");
		ThrowIf(IMC_Shop == nullptr, "IMC_Shop is required!");
		PushInputComponent(InputComponent);

		UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(this);
		FModifyContextOptions Options;
		EnhancedInputSubsystem.AddMappingContext(IMC_Gameplay, 0, Options);

		if (!EnhancedInputSubsystem.UserSettings.IsMappingContextRegistered(IMC_Gameplay))
			EnhancedInputSubsystem.UserSettings.RegisterInputMappingContext(IMC_Gameplay);
	}

	void SetupInputEvents()
	{
		AAngelPlayerCharacter Char = Cast<AAngelPlayerCharacter>(ControlledPawn);
		if (Char == nullptr)
			return;

		SetupMouseEvents(Char);
		SetupKeyboardEvents(Char);
	}

	void SetupMouseEvents(AAngelPlayerCharacter Char)
	{
		// Shooting
		InputComponent.BindAction(ShootAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(GunComponent, n"Fire"));

		// ADS (Aim Down Sights)
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(ADSComponent, n"StartADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Canceled, FEnhancedInputActionHandlerDynamicSignature(ADSComponent, n"CancelledADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(ADSComponent, n"TriggeredADS"));
		InputComponent.BindAction(ADS_Action, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(ADSComponent, n"EndADS"));
	}

	void SetupKeyboardEvents(AAngelPlayerCharacter Char)
	{
		// Movement

		// Reloading
		InputComponent.BindKey(EKeys::R, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ReloadComponent, n"Reload"));

		// Gun Switching
		InputComponent.BindAction(SwitchGunAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"CycleGun"));
		InputComponent.BindKey(EKeys::AnyKey, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"SelectGun"));

		// Ability
		InputComponent.BindAction(AbilityAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(Char, n"UseAbility"));

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
		AAngelPlayerCharacter Char = Cast<AAngelPlayerCharacter>(ControlledPawn);
		if (Char == nullptr)
			return;

		if (CycleGunTimer > 0.0f)
			return;

		float Direction = ActionValue.GetAxis1D();

		if (IsValid(HolsterComponent))
		{
			FString DirectionString = (Direction > 0) ? "Next" : "Previous";
			Print(f"Cycle gun with direction: {DirectionString}", 2, FLinearColor(0.15, 0.32, 0.52));
			HolsterComponent.CycleGun(Direction);
			CycleGunTimer = CycleGunCooldown;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void SelectGun(FKey Key)
	{
		AAngelPlayerCharacter Char = Cast<AAngelPlayerCharacter>(ControlledPawn);
		if (Char == nullptr)
			return;

		int GunIndex = -1;
		if (Key == EKeys::One)
			GunIndex = 0;
		else if (Key == EKeys::Two)
			GunIndex = 1;
		else if (Key == EKeys::Three)
			GunIndex = 2;

		if (GunIndex >= 0 && GunIndex < HolsterComponent.HolsteredGuns.Num())
		{
			if (CycleGunTimer > 0.0f) return;
			HolsterComponent.SwitchGun(GunIndex);
			CycleGunTimer = 0.3;
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
		auto GameState = Game::GameState;
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

	/**
	 * Note: We could make this function a server RPC, but because its called almost exclusively from PostGameplayEffectExecute --
	 * which is server-only -- and from OnRep_Ammo -- which is client-only -- we don't gain anything from an RPC, other than
	 * for the initial replication to be handled server-side. So we're essentially trusting the player's very first bullet wholeheartedly!!
	 */
	void UpdateAmmoTags(UAngelscriptAbilitySystemComponent ASC, float Ammo, float MaxAmmo) const
	{
		SetTagState(ASC, GameplayTags::State_Ammo_Last, Ammo == 1.f && Ammo > 0.f);
		SetTagState(ASC, GameplayTags::State_Ammo_Empty, Ammo <= 0.f);
		SetTagState(ASC, GameplayTags::State_Ammo_Full, Ammo >= MaxAmmo);
	}

	void UpdateMovementTags(UAngelscriptAbilitySystemComponent ASC, EAngelMovementState MoveState) const
	{
		SetTagState(ASC, GameplayTags::State_Movement_Still, MoveState == EAngelMovementState::Still);
		SetTagState(ASC, GameplayTags::State_Movement_Airborne, MoveState == EAngelMovementState::Airborne);
		SetTagState(ASC, GameplayTags::State_Movement_Walk, MoveState == EAngelMovementState::Walk);
		SetTagState(ASC, GameplayTags::State_Movement_Run, MoveState == EAngelMovementState::Run);
		SetTagState(ASC, GameplayTags::State_Movement_Crouch, MoveState == EAngelMovementState::Crouch);
		SetTagState(ASC, GameplayTags::State_Movement_CrouchWalk, MoveState == EAngelMovementState::CrouchWalk);
	}

	void SetTagState(UAngelscriptAbilitySystemComponent ASC, FGameplayTag Tag, bool bShouldHave) const
	{
		const bool bHas = ASC.HasGameplayTag(Tag);
		if (bShouldHave && !bHas)
			ASC.AddLooseGameplayTag(Tag, 1, EGameplayTagReplicationState::TagAndCountToAll);
		else if (!bShouldHave && bHas)
			ASC.RemoveLooseGameplayTag(Tag, 1, EGameplayTagReplicationState::TagAndCountToAll);
	}
};

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
