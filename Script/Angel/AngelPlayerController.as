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

    UPROPERTY(Category = "Input")
    UInputAction InventoryAction;

    UPROPERTY(Category = "Input")
    UInputAction SwitchGunAction;

    UPROPERTY(Category = "Input")
    UInputAction InitiateReloadAction;

    UPROPERTY(Category = "Input")
    UInputAction ShootAction;

    UPROPERTY(Category = "Input")
    UInputMappingContext Context;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PushInputComponent(InputComponent);

        UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(this);
        EnhancedInputSubsystem.AddMappingContext(Context, 0, FModifyContextOptions());

        ManualWalkingComponent = UManualWalkingComponent::Get(Gameplay::GetPlayerCharacter(0));
        ManualReloadComponent = UManualReloadComponent::Get(Gameplay::GetPlayerCharacter(0));
        ManualBlinkingComponent = UManualBlinkingComponent::Get(Gameplay::GetPlayerCharacter(0));
        ManualBreathingComponent = UManualBreathingComponent::Get(Gameplay::GetPlayerCharacter(0));

        // Manual actions
        InputComponent.BindKey(EKeys::Q, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualWalkingComponent, n"OnKeyPressed"));
        InputComponent.BindKey(EKeys::E, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualWalkingComponent, n"OnKeyPressed"));
        
        InputComponent.BindKey(EKeys::AnyKey, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualReloadComponent, n"OnKeyPressed"));
        InputComponent.BindAction(InitiateReloadAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(ManualReloadComponent, n"InitiateReload"));

        InputComponent.BindKey(EKeys::F, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualBlinkingComponent, n"Blink"));
        
        InputComponent.BindKey(EKeys::SpaceBar, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(ManualBreathingComponent, n"Inhale"));
        InputComponent.BindKey(EKeys::SpaceBar, EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(ManualBreathingComponent, n"Exhale"));

        // UI/Inventory actions
        InputComponent.BindAction(InventoryAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"ToggleInventory"));

        // Gun switching actions
        InputComponent.BindAction(SwitchGunAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"CycleGun"));

        // The GunComponent may not be valid at the time of binding, so we check it here. Depends on if the player starts with a gun or not.
        RegisterGunComponent(UGunComponent::Get(Gameplay::GetPlayerCharacter(0)));
    }

    UFUNCTION()
    void RegisterGunComponent(UGunComponent NewGunComponent)
    {
        if (!IsValid(NewGunComponent)) return;

        // Only register the GunComponent if it's not already set.
        if (!IsValid(GunComponent))
        {
            GunComponent = NewGunComponent;
            InputComponent.BindAction(ShootAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(NewGunComponent, n"OnShoot"));
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
        UHolster Holster = UHolster::Get(Gameplay::GetPlayerCharacter(0));

        if (IsValid(Holster))
        {
            Holster.CycleGun();
        }
    }
};

AAngelPlayerController GetAngelController(int PlayerIndex)
{
    return Cast<AAngelPlayerController>(Gameplay::GetPlayerController(PlayerIndex));
}
