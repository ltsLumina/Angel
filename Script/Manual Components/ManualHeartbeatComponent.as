class UManualHeartbeatComponent : UActorComponent
{
    UPROPERTY(Category = "Config | Heartbeat", EditDefaultsOnly)
    bool UseHeartbeat;
    default UseHeartbeat = true;

    // The current heart rate in beats per minute (BPM). Average resting heart rate is around 60-100 BPM.
    UPROPERTY(Category = "Config | Heartbeat", VisibleAnywhere)
    float CurrentBPM;
    default CurrentBPM = 60; // Default to 60 beats per minute

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BP_BeginPlay();

        System::SetTimer(this, n"OnHeartBeat", 60.0f / CurrentBPM, true);
    }

    UFUNCTION()
    void OnHeartBeat()
    {
        if (!UseHeartbeat) return;
        Print(f"Heartbeat: {CurrentBPM} BPM", 0.5f, FLinearColor(0.79, 0.25, 0.55));

        
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        BP_Tick(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Tick"))
    void BP_Tick(float DeltaSeconds) { }
};