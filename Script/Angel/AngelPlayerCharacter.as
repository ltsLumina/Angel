class AAngelPlayerCharacter : ACharacter
{
    UPROPERTY(Category = "Player", EditDefaultsOnly)
    FGameplayTagContainer GameplayTags;

    UManualWalkingComponent ManualWalkingComponent;
    UManualReloadComponent ManualReloadComponent;
    UManualBlinkingComponent ManualBlinkingComponent;
    UManualBreathingComponent ManualBreathingComponent;
    UHolster HolsterComponent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ManualWalkingComponent = UManualWalkingComponent::Get(this);
        ManualReloadComponent = UManualReloadComponent::Get(this);
        ManualBlinkingComponent = UManualBlinkingComponent::Get(this);
        ManualBreathingComponent = UManualBreathingComponent::Get(this);
        HolsterComponent = UHolster::Get(this);

        // Call the Blueprint BeginPlay event
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }
};

AAngelPlayerCharacter GetAngelCharacter(AActor Actor)
{
    return Cast<AAngelPlayerCharacter>(Actor);
}

AAngelPlayerCharacter GetAngelCharacter(int PlayerIndex)
{
    return Cast<AAngelPlayerCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}