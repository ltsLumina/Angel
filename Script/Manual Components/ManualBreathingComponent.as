enum EManualBreathingState
{
    Inhale,
    Exhale,
};

class UManualBreathingComponent : UActorComponent
{
    UCameraComponent Camera;

    UPROPERTY(Category = "Breathing")
    bool UseBreathing;
    default UseBreathing = true;

    UPROPERTY(Category = "Breathing", Meta = (ClampMin = MinOxygen, ClampMax = MaxOxygen))
    float Oxygen;
    default Oxygen = 100;

    UPROPERTY(Category = "Breathing", DisplayName = "Lung Capacity")
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
    bool GetBreathingState() const
    {
        return BreathingState == EManualBreathingState::Inhale;
    }

    // Timer that ticks while inhaling. If the player holds the inhale key, this timer will increase.
    UPROPERTY(Category = "Breathing | Inhale", VisibleAnywhere)
    float InhaleTime;
    default InhaleTime = 0;

    // Maximum time for inhaling before it stops. Defaults to the time it takes to fill the lungs completely based on the oxygen inhale rate.
    UPROPERTY(Category = "Breathing | Inhale", EditDefaultsOnly)
    float MaxInhaleTime;
    default MaxInhaleTime = MaxOxygen / OxygenInhaleRate;

    UPROPERTY(Category = "Breathing | Inhale")
    float TimeSinceInhale;
    default TimeSinceInhale = 999; // Start with a high value to allow immediate inhalation

    UPROPERTY(Category = "Breathing | Inhale")
    float InhaleCooldown;
    default InhaleCooldown = 1.5; // Cooldown before the player can inhale again

    float AsphyxiaEffect = 1;

    // How fast the asphyxia effect applies and reaches its maximum value
    UPROPERTY(Category = "Breathing | Asphyxia Effect")
    float AsphyxiaEffectRate;
    default AsphyxiaEffectRate = 1;

    UPROPERTY(Category = "Breathing | Asphyxia Effect")
    float AsphyxiaEffectThreshold;
    default AsphyxiaEffectThreshold = 25; // Oxygen level below which asphyxia effect starts

// components

    UManualHeartbeatComponent ManualHeartbeatComponent;

// end
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ManualHeartbeatComponent = UManualHeartbeatComponent::Get(GetOwner());

        Camera = UCameraComponent::Get(GetOwner());
        Camera.PostProcessSettings.bOverride_ColorGain = true;

        // Initialize any necessary variables or states here
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }


    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        BP_Tick(DeltaSeconds);

        if (!UseBreathing) return;

        if (GetBreathingState())
        {
            // If inhaling, increase oxygen
            Oxygen = Math::Clamp(Oxygen + (OxygenInhaleRate * DeltaSeconds), MinOxygen, MaxOxygen);

            InhaleTime += DeltaSeconds;

            // If the inhale timer exceeds the maximum inhale time or oxygen is full, stop inhaling, and exhale
            if (InhaleTime >= MaxInhaleTime)
            {
                // Stop inhaling after reaching the maximum inhale time
                Exhale(EKeys::Invalid);
                InhaleTime = 0.0f; // Reset the inhale timer
            }

            // If oxygen is full, increase heartbeat BPM until you exhale
            if (Oxygen >= MaxOxygen)
            {
                ManualHeartbeatComponent.IncreaseBPM(0.5f);
            }
        }
        else
        {
            // Deplete oxygen over time
            Oxygen = Math::Clamp(Oxygen - (OxygenDepletionRate * DeltaSeconds), MinOxygen, MaxOxygen);

            TimeSinceInhale += DeltaSeconds;
        }

        // Applies once oxygen is below a certain threshold (e.g., 25)
        AsphyxiaEffect = Math::FInterpTo(AsphyxiaEffect, Math::Clamp(Oxygen / AsphyxiaEffectThreshold, 0, 1), DeltaSeconds, AsphyxiaEffectRate);
        Camera.PostProcessSettings.ColorGain = FVector4(AsphyxiaEffect, AsphyxiaEffect, AsphyxiaEffect, AsphyxiaEffect);
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Tick"))
    void BP_Tick(float DeltaSeconds) { }

    UFUNCTION(NotBlueprintCallable)
    void Inhale(FKey _)
    {
        // If the inhale cooldown is active, do not allow inhaling
        if (TimeSinceInhale < InhaleCooldown) return;

        BreathingState = EManualBreathingState::Inhale;
        TimeSinceInhale = 0.0f; // Reset the time since last inhale

        OnInhale();
    }

    UFUNCTION(BlueprintEvent)
    void OnInhale()
    { }

    UFUNCTION(NotBlueprintCallable)
    void Exhale(FKey _)
    {
        // Can't exhale if you haven't inhaled yet
        if (BreathingState != EManualBreathingState::Inhale) return;

        BreathingState = EManualBreathingState::Exhale;
        OnExhale();
    }

    UFUNCTION(BlueprintEvent)
    void OnExhale()
    { }
};