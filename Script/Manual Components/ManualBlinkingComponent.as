class UManualBlinkingComponent : UActorComponent
{
    UCameraComponent Camera;

    // The rate at which the blur effect is applied. A higher value will make the blue reach the minimum focal distance faster.
    UPROPERTY(Category = "Gameplay | Blinking")
    float BlurRate;
    default BlurRate = 0.1; 

// Minimum focal distance for the blur effect. A lower value will make the blur more pronounced.
    UPROPERTY(Category = "Gameplay | Blinking")
    float MinFocalDistance;
    default MinFocalDistance = 5;

// Maximum focal distance for the blur effect. A higher value will make the blur take longer to reach the minimum focal distance.
    UPROPERTY(Category = "Gameplay | Blinking")
    float MaxFocalDistance;
    default MaxFocalDistance = 100;

    // - config | blinking
    UPROPERTY(Category = "Config | Blinking", EditDefaultsOnly)
    bool UseBlinking;
    default UseBlinking = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Camera = UCameraComponent::Get(GetOwner());
        if (IsValid(Camera))
        {
            Camera.PostProcessSettings.bOverride_DepthOfFieldFocalDistance = true;
            Camera.PostProcessSettings.bOverride_ColorGamma = true;
            Camera.PostProcessSettings.DepthOfFieldFocalDistance = MaxFocalDistance; // Initial focal distance
            Camera.PostProcessSettings.ColorGamma = FVector4(1.0f, 1.0f, 1.0f, 1.0f); // Initial color gain
        }
        
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Blur(DeltaSeconds);
        
        BP_Tick(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Tick"))
    void BP_Tick(float DeltaSeconds) { }

    UFUNCTION(BlueprintCallable, Category = "Blinking")
    void Blur(float DeltaSeconds)
    {
        if (!UseBlinking) return;
        
         Camera.PostProcessSettings.DepthOfFieldFocalDistance = Math::FInterpTo(
            Camera.PostProcessSettings.DepthOfFieldFocalDistance, 
            MinFocalDistance, 
            DeltaSeconds, 
            BlurRate);
    }

    UFUNCTION(BlueprintCallable, Category = "Blinking")
    void Blink(FKey _)
    {
        Camera.PostProcessSettings.ColorGamma = FVector4(0,0,0, 0); // Initial color gain

        System::SetTimer(this, n"OnBlink", 0.1f, false);
    }

    UFUNCTION(NotBlueprintCallable, Category = "Blinking")
    void OnBlink()
    {
        Camera.PostProcessSettings.DepthOfFieldFocalDistance = MaxFocalDistance; // Reset focal distance
        Camera.PostProcessSettings.ColorGamma = FVector4(1.0f, 1.0f, 1.0f, 1.0f); // Reset color gain

        BP_OnBlink();
    }

    UFUNCTION(BlueprintEvent, Category = "Blinking")
    void BP_OnBlink()
    {
        // This can be overridden in Blueprints to add custom behavior after blinking.
    }
};