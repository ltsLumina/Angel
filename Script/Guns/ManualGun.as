UCLASS(Abstract)
class AManualGun : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent Root;

    UPROPERTY(DefaultComponent, Category = "Config | Gun")
    USkeletalMeshComponent GunMesh;

// - config

    UPROPERTY(Category = "Config | Gun", EditDefaultsOnly)
    FName GunName; 
    // Default the name to the class name, minus the BP_ prefix and any suffix.
    default GunName = GetClass().GetName();

    UPROPERTY(Category = "Config | Gun", EditDefaultsOnly)
    int CurrentAmmo;
    default CurrentAmmo = 6;

    UPROPERTY(Category = "Config | Gun", EditDefaultsOnly)
    int MaxAmmo;
    default MaxAmmo = 6;

    UPROPERTY(Category = "Config | Gun", BlueprintGetter = GetCanShoot, VisibleAnywhere)
    bool CanShoot;

    UFUNCTION(BlueprintPure, Category = "Gun")
    bool GetCanShoot() const { return CurrentAmmo > 0; }

    UPROPERTY(Category = "Config | Gun", EditDefaultsOnly)
    int ReloadSteps;
    default ReloadSteps = 3;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        CurrentAmmo = MaxAmmo;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        SetActorEnableCollision(false);
        GetAngelCharacter(0).HolsterComponent.EquipGun(this);
    }

    UFUNCTION(Category = "Gun")
    void Shoot(bool&out Success)
    {
        if (CurrentAmmo > 0)
        {
            CurrentAmmo--;
            Print(f"{GunName} fired! (Ammo: {CurrentAmmo}/{MaxAmmo})", 2, FLinearColor(0.15, 0.32, 0.52));
            Success = true;
        }
        else
        {
            Print(f"{GunName} cannot shoot, no ammo left!", 2, FLinearColor(1.00, 0.48, 0.00));
            Success = false;
        }
    }

    UFUNCTION(Category = "Gun")
    void OnReload()
    {
        Print(f"{GunName} reloaded!", 2, FLinearColor(0.58, 0.95, 0.49));

        CurrentAmmo = MaxAmmo;
    }
};