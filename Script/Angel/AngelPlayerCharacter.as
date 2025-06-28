event void FOnEffectGained(FGameplayTag EffectTag, AActor EffectInstigator);
event void FOnEffectLost(FGameplayTag EffectTag, AActor EffectInstigator);

class AAngelPlayerCharacter : ACharacter
{
    UPROPERTY(Category = "Player", NotVisible)
    AAngelPlayerController AngelController;

    UPROPERTY(Category = "Player", EditDefaultsOnly)
    FGameplayTagContainer GameplayTags;

// - events

    UPROPERTY(Category = "Player", VisibleAnywhere)
    FOnEffectGained OnEffectGained;

    UPROPERTY(Category = "Player", VisibleAnywhere)
    FOnEffectLost OnEffectLost;

// - end

    UManualWalkingComponent ManualWalkingComponent;
    UManualReloadComponent ManualReloadComponent;
    UManualBlinkingComponent ManualBlinkingComponent;
    UManualBreathingComponent ManualBreathingComponent;
    UManualHeartbeatComponent ManualHeartbeatComponent;

    UHolsterComponent HolsterComponent;
    UInventoryComponent InventoryComponent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ManualWalkingComponent = UManualWalkingComponent::Get(this);
        ManualReloadComponent = UManualReloadComponent::Get(this);
        ManualBlinkingComponent = UManualBlinkingComponent::Get(this);
        ManualBreathingComponent = UManualBreathingComponent::Get(this);
        ManualHeartbeatComponent = UManualHeartbeatComponent::Get(this);

        HolsterComponent = UHolsterComponent::Get(this);
        //InventoryComponent = UInventoryComponent::Get(this); // TODO

        AngelController = GetAngelController(this); // Equivalent to Cast<AAngelPlayerController>(this);

        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        BP_Tick(DeltaSeconds);
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