enum EManualBreathingState
{
    Inhale,
    Exhale,
    Hold,
};

event void FOnInhale();
event void FOnExhale();
event void FOnHoldBreath();

class UManualBreathingComponent : UActorComponent
{
    UCameraComponent Camera;
    UManualHeartbeatComponent HeartbeatComponent;

    UPROPERTY(Category = "Breathing")
    bool UseBreathing;
    default UseBreathing = true;

    UPROPERTY(Category = "Breathing", EditDefaultsOnly, Meta = (ClampMin = MinOxygen, ClampMax = MaxOxygen))
    float Oxygen;
    default Oxygen = 100;

    UPROPERTY(Category = "Breathing")
    float MaxOxygen;
    default MaxOxygen = 100;

    UPROPERTY(Category = "Breathing")
    float MinOxygen;
    default MinOxygen = 0;

    UPROPERTY(Category = "Breathing")
    float OxygenDepletionRate;
    default OxygenDepletionRate = 10; // per second

    // Amount of oxygen gained per inhale
    UPROPERTY(Category = "Breathing")
    float OxygenInhaleRate;
    default OxygenInhaleRate = 35; // per second

// -- breathing state

    UPROPERTY(Category = "Breathing", VisibleAnywhere)
    EManualBreathingState BreathingState;
    default BreathingState = EManualBreathingState::Exhale;

    UPROPERTY(Category = "Breathing | Inhale", BlueprintGetter = "GetBreathingState", VisibleAnywhere)
    bool IsInhaling;

    UFUNCTION(Category = "Breathing | Inhale", BlueprintPure)
    bool GetBreathingState() const { return BreathingState == EManualBreathingState::Inhale; }

    // Timer that ticks while inhaling.
    UPROPERTY(Category = "Breathing | Inhale", VisibleAnywhere, Meta = (Units = "Seconds"))
    float InhaleTime;
    default InhaleTime = 0;

    // Maximum time for inhaling before it stops. Defaults to the time it takes to fill the lungs completely based on the oxygen inhale rate.
    UPROPERTY(Category = "Breathing | Inhale", EditDefaultsOnly, Meta = (Units = "Seconds"))
    float MaxInhaleTime;
    default MaxInhaleTime = MaxOxygen / OxygenInhaleRate;

    UPROPERTY(Category = "Breathing | Inhale", Meta = (Units = "Seconds"))
    float TimeSinceInhale;
    default TimeSinceInhale = 4140; // Start with a high value to allow immediate inhalation

    // How long the player must wait before they can inhale again after exhaling.
    UPROPERTY(Category = "Breathing | Inhale", Meta = (Units = "Seconds"))
    float InhaleCooldown;
    default InhaleCooldown = 1.5;

// - hold breath

    // Timer that ticks while holding breath. If the player holds the inhale key, this timer will increase.
    UPROPERTY(Category = "Breathing | Hold", VisibleAnywhere, Meta = (Units = "Seconds"))
    float HoldBreathTime;
    default HoldBreathTime = 0;

    // The amount of time the player must be inhaling at >=100 oxygen before they begin to hold their breath.
    UPROPERTY(Category = "Breathing | Hold", EditDefaultsOnly, Meta = (Units = "Seconds"))
    float HoldBreathThreshold;
    default HoldBreathThreshold = 1.5;

    // Maximum time the player can hold their breath before they start to asphyxiate.
    UPROPERTY(Category = "Breathing | Hold", EditDefaultsOnly, Meta = (Units = "Seconds"))
    float MaxHoldBreathTime;
    default MaxHoldBreathTime = 2.5f;

    // How much oxygen is depleted per second while holding breath.
    UPROPERTY(Category = "Breathing | Hold", EditDefaultsOnly, Meta = (Units = "Percent"))
    float HoldBreathOxygenDepletionRateModifier;
    default HoldBreathOxygenDepletionRateModifier = 10; // Converts to percentage at usage.

// - asphyxia effect
    // The effect applied to the camera when the player is asphyxiating. This is a post-process effect that changes the color gain.
    UPROPERTY(Category = "Breathing | Asphyxia Effect", VisibleAnywhere)
    float AsphyxiaEffect;
    default AsphyxiaEffect = 0;

    UPROPERTY(Category = "Breathing | Asphyxia Effect", VisibleAnywhere, BlueprintGetter = "GetIsAsphyxiating")
    bool IsAsphyxiating;

    UFUNCTION(Category = "Breathing | Asphyxia Effect", BlueprintPure)
    bool GetIsAsphyxiating() const { return !Math::IsNearlyZero(AsphyxiaEffect, 0.1f); }

    // How fast the asphyxia effect applies and reaches its maximum value.
    UPROPERTY(Category = "Breathing | Asphyxia Effect")
    float AsphyxiaEffectRate;
    default AsphyxiaEffectRate = 1;

    UPROPERTY(Category = "Breathing | Asphyxia Effect")
    float AsphyxiaEffectThreshold;
    default AsphyxiaEffectThreshold = 25; // Oxygen level below which asphyxia effect starts

// events

    UPROPERTY()
    FOnInhale OnInhale;
    
    UPROPERTY()
    FOnExhale OnExhale;

    /* Event is called every tick while the player is holding their breath. */
    UPROPERTY()
    FOnHoldBreath OnHoldBreath;

    // end events

// end
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Camera = UCameraComponent::Get(GetOwner());
        Camera.PostProcessSettings.bOverride_ColorGain = true;

        HeartbeatComponent = UManualHeartbeatComponent::Get(GetOwner());

        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }


    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!UseBreathing) return;

        switch (BreathingState)
        {
            case EManualBreathingState::Inhale:
                Oxygen = Math::Clamp(Oxygen + (OxygenInhaleRate * DeltaSeconds), MinOxygen, MaxOxygen);
                InhaleTime += DeltaSeconds;

                // Stop inhaling after reaching the maximum inhale time
                if (InhaleTime >= MaxInhaleTime)
                {
                    Exhale();
                }

                if (Oxygen >= MaxOxygen && InhaleTime > HoldBreathThreshold)
                {
                    BreathingState = EManualBreathingState::Hold;
                    return;
                }

                BP_Inhaling();
                break;

            case EManualBreathingState::Exhale:
                Oxygen = Math::Clamp(Oxygen - (OxygenDepletionRate * DeltaSeconds), MinOxygen, MaxOxygen);
                TimeSinceInhale += DeltaSeconds;

                BP_Exhaling();
                break;

            case EManualBreathingState::Hold:
                HoldBreathTime += DeltaSeconds;
                InhaleTime = 0.0f;
                TimeSinceInhale = 4140; // Allow immediate inhalation again after holding breath
                
                if (HoldBreathTime >= MaxHoldBreathTime)
                {
                    Oxygen = 0;
                }

                OnHoldBreath.Broadcast();
                BP_HoldingBreath();
                break;
        }

        // Applies once oxygen is below a certain threshold (e.g., 25)
        float TargetAsphyxia = 0.0f;
        if (Oxygen < AsphyxiaEffectThreshold)
        {
            TargetAsphyxia = 1.0f - Math::Clamp(Oxygen / AsphyxiaEffectThreshold, 0, 1);
        }
        AsphyxiaEffect = Math::FInterpTo(AsphyxiaEffect, TargetAsphyxia, DeltaSeconds, AsphyxiaEffectRate);
        float InvertedAsphyxia = 1.0f - AsphyxiaEffect; // 0 = full effect, 1 = no effect for ColorGain
        Camera.PostProcessSettings.ColorGain = FVector4(InvertedAsphyxia, InvertedAsphyxia, InvertedAsphyxia, InvertedAsphyxia);

        // Player has asphyxiated.
        if (Math::IsNearlyEqual(AsphyxiaEffect, 1, 0.1f))
        {
            if (HeartbeatComponent.IsFlatlined) return;
            
            HeartbeatComponent.OnCardiacArrest();
        }

        BP_Tick(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Tick")
    void BP_Tick(float DeltaSeconds) { }

    // This function is only called once when the player starts inhaling.
    UFUNCTION(NotBlueprintCallable)
    void Inhale(FKey _ = EKeys::Invalid)
    {
        if (BreathingState == EManualBreathingState::Inhale) return;

        // If the inhale cooldown is active, do not allow inhaling
        if (TimeSinceInhale < InhaleCooldown) return;

        BreathingState = EManualBreathingState::Inhale;
        InhaleTime = 0.0f; // Reset the inhale timer
        TimeSinceInhale = 0.0f; // Reset the time since last inhale

        OnInhale.Broadcast();
        BP_OnInhale();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Inhaling")
    void BP_Inhaling()
    { }

    UFUNCTION(BlueprintEvent, DisplayName = "Inhale")
    void BP_OnInhale()
    { }

    // This function is only called once when the player starts exhaling (releasing the inhale key).
    UFUNCTION(NotBlueprintCallable)
    void Exhale(FKey _ = EKeys::Invalid)
    {
        if (BreathingState == EManualBreathingState::Exhale) return;

        BreathingState = EManualBreathingState::Exhale;
        InhaleTime = 0.0f; // Reset the inhale timer
        HoldBreathTime = 0.0f; // Reset the hold breath timer

        OnExhale.Broadcast();
        BP_OnExhale();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Exhaling")
    void BP_Exhaling()
    { }

    UFUNCTION(BlueprintEvent, DisplayName = "Exhale")
    void BP_OnExhale()
    { }

    UFUNCTION(BlueprintEvent, DisplayName = "Hold Breath")
    void BP_HoldingBreath() 
    { }
};