class AAngelPlayerCharacter : ACharacter
{
    UPROPERTY(Category = "Player", EditDefaultsOnly)
    FGameplayTagContainer GameplayTags;

    UManualWalkingComponent ManualWalkingComponent;
    UManualReloadComponent ManualReloadComponent;
    UManualBlinkingComponent ManualBlinkingComponent;
    UManualBreathingComponent ManualBreathingComponent;
    UManualHeartbeatComponent ManualHeartbeatComponent;

    UHolster HolsterComponent;

    UPROPERTY(Category = "Player", NotVisible)
    AAngelPlayerController AngelController;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ManualWalkingComponent = UManualWalkingComponent::Get(this);
        ManualReloadComponent = UManualReloadComponent::Get(this);
        ManualBlinkingComponent = UManualBlinkingComponent::Get(this);
        ManualBreathingComponent = UManualBreathingComponent::Get(this);
        ManualHeartbeatComponent = UManualHeartbeatComponent::Get(this);

        HolsterComponent = UHolster::Get(this);

        AngelController = GetAngelController(this);

        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Tick")
    void BP_Tick(float DeltaSeconds) { }

};

AAngelPlayerCharacter GetAngelCharacter(AActor Actor)
{
    return Cast<AAngelPlayerCharacter>(Actor);
}

AAngelPlayerCharacter GetAngelCharacter(int PlayerIndex)
{
    return Cast<AAngelPlayerCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}