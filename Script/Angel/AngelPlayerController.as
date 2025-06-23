class AAngelPlayerController : APlayerController
{
    UPROPERTY(DefaultComponent)
    UEnhancedInputComponent InputComponent;

    UPROPERTY(Category = "Input", EditDefaultsOnly)
    UGunComponent GunComponent;

    UManualWalkingComponent ManualWalkingComponent;
    UManualReloadComponent ManualReloadComponent;
    UManualBlinkingComponent ManualBlinkingComponent;
    UManualBreathingComponent ManualBreathingComponent;
    UManualHeartbeatComponent ManualHeartbeatComponent;

    UPROPERTY(Category = "Input")
    UInputAction MoveAction;

    UPROPERTY(Category = "Input")
    UInputAction ShootAction;

    UPROPERTY(Category = "Input")
    UInputAction InitiateReloadAction;

    UPROPERTY(Category = "Input")
    UInputAction InventoryAction;

    UPROPERTY(Category = "Input")
    UInputAction SwitchGunAction;

    UPROPERTY(Category = "Input")
    UInputMappingContext Context;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PushInputComponent(InputComponent);

        UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(this);
        EnhancedInputSubsystem.AddMappingContext(Context, 0, FModifyContextOptions());

        AAngelPlayerCharacter Character = GetAngelCharacter(0);

        ManualWalkingComponent = UManualWalkingComponent::Get(Character);
        ManualReloadComponent = UManualReloadComponent::Get(Character);
        ManualBlinkingComponent = UManualBlinkingComponent::Get(Character);
        ManualBreathingComponent = UManualBreathingComponent::Get(Character);
        ManualHeartbeatComponent = UManualHeartbeatComponent::Get(Character);

        // Movement
        InputComponent.BindAction(MoveAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(ManualWalkingComponent, n"OnMove"));
        InputComponent.BindAction(MoveAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(ManualWalkingComponent, n"OnMoveCompleted"));
        InputComponent.BindKey(EKeys::Q, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualWalkingComponent, n"OnKeyPressed"));
        InputComponent.BindKey(EKeys::E, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualWalkingComponent, n"OnKeyPressed"));

        // Shooting
        InputComponent.BindAction(ShootAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(UGunComponent::Get(GetAngelCharacter(0)), n"OnShoot"));
        
        // Reloading
        InputComponent.BindKey(EKeys::AnyKey, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualReloadComponent, n"OnKeyPressed"));
        InputComponent.BindAction(InitiateReloadAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(ManualReloadComponent, n"InitiateReload"));

        // Blinking
        InputComponent.BindKey(EKeys::F, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualBlinkingComponent, n"Blink"));

        // Breathing
        InputComponent.BindKey(EKeys::SpaceBar, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualBreathingComponent, n"Inhale"));
        InputComponent.BindKey(EKeys::SpaceBar, EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(ManualBreathingComponent, n"Exhale"));

        // UI/Inventory
        InputComponent.BindAction(InventoryAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"ToggleInventory"));

        // Gun Switching
        InputComponent.BindAction(SwitchGunAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"CycleGun"));
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

    UFUNCTION()
    void ToggleInventory(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        Print(f"Toggled inventory!");
    }

    UFUNCTION()
    void CycleGun(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        if (CycleGunTimer > 0.0f) return;

        float Direction = ActionValue.GetAxis1D();

        UHolster Holster = UHolster::Get(Gameplay::GetPlayerCharacter(0));

        if (IsValid(Holster))
        {
            FString DirectionString = (Direction > 0) ? "Next" : "Previous";
            Print(f"Cycle gun with direction: {DirectionString}", 2, FLinearColor(0.15, 0.32, 0.52));
            Holster.CycleGun(Direction);
            CycleGunTimer = CycleGunCooldown;
        }
    }
};

AAngelPlayerController GetAngelController(int PlayerIndex)
{
    return Cast<AAngelPlayerController>(Gameplay::GetPlayerController(PlayerIndex));
}
