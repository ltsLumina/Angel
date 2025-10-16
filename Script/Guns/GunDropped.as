class AGunDropped : AActor
{
    UPROPERTY()
    TSubclassOf<AGunDropped> Blueprint;

    UPROPERTY(Category = "Gun", EditDefaultsOnly, ExposeOnSpawn)
    TSubclassOf<AGunBase> GunClassToGrant;

    UPROPERTY(DefaultComponent, RootComponent)
    UBoxComponent Box;

    AGunBase OldGun;

    int CurrentAmmo;
    int ReserveAmmo;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentAmmo = GunClassToGrant.DefaultObject.MaxAmmo;
        ReserveAmmo = GunClassToGrant.DefaultObject.MaxReserveAmmo;

        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay()
    {}

    UFUNCTION()
    void PickupGun()
    {        
        AAngelPlayerCharacter Character = GetAngelCharacter(0);
        UHolsterComponent Holster = UHolsterComponent::Get(GetAngelCharacter(0));
        OldGun = Holster.Primary;

        AGunDropped NewDroppedGun = SpawnActor(Blueprint, Character.ActorLocation + FVector(0, 0, 75), FRotator::ZeroRotator, FName(f"Dropped {GunClassToGrant.DefaultObject.GunName}"));
        NewDroppedGun.GunClassToGrant = OldGun.GetClass();
        NewDroppedGun.CurrentAmmo = OldGun.CurrentAmmo;
        NewDroppedGun.ReserveAmmo = OldGun.ReserveAmmo;

        Holster.GrantGun(GunClassToGrant, true, FEquipData(EEquipSpeed::Normal, false, CurrentAmmo, ReserveAmmo));

        NewDroppedGun.Box.AddImpulse(UCameraComponent::Get(Character).ForwardVector * 250, NAME_None, true);

        DestroyActor();
    }
};