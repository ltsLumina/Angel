class AAngelPlayerCharacter : ACharacter
{
    UPROPERTY(Category = "Player", EditDefaultsOnly)
    FGameplayTagContainer GameplayTags;

    UPROPERTY(Category = "Player", EditDefaultsOnly)
    float Health;
    default Health = 100;

    UPROPERTY(Category = "Player", EditDefaultsOnly)
    float MaxHealth;
    default MaxHealth = 100;

    UManualWalkingComponent ManualWalkingComponent;
    UManualReloadComponent ManualReloadComponent;
    UManualBlinkingComponent ManualBlinkingComponent;
    UManualBreathingComponent ManualBreathingComponent;
    UHolster HolsterComponent;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        Health = MaxHealth;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ManualWalkingComponent = UManualWalkingComponent::Get(this);
        ManualReloadComponent = UManualReloadComponent::Get(this);
        ManualBlinkingComponent = UManualBlinkingComponent::Get(this);
        ManualBreathingComponent = UManualBreathingComponent::Get(this);
        HolsterComponent = UHolster::Get(this);

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

float GetPlayerHealth(int PlayerIndex)
{
    AAngelPlayerCharacter PlayerCharacter = GetAngelCharacter(PlayerIndex);
    if (IsValid(PlayerCharacter))
    {
        return PlayerCharacter.Health;
    }
    return -1; // Return -1 if the player character is not valid
}