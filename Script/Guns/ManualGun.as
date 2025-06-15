UCLASS(Abstract)
class AManualGun : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent Root;

    UPROPERTY(DefaultComponent, Category = "Config | Gun")
    USkeletalMeshComponent GunMesh;

// - config | gun

    UPROPERTY(Category = "Config | Gun")
    int AmmoCount;
    default AmmoCount = 6;

    UPROPERTY(Category = "Config | Gun")
    int MaxAmmoCount;
    default MaxAmmoCount = 6;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        
        
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    void OnReload()
    {
        Print(f"{GetName()} reloaded!", 2, FLinearColor(0.58, 0.95, 0.49));

        BP_OnReload();
    }

    UFUNCTION(BlueprintEvent)
    void BP_OnReload() { }
};