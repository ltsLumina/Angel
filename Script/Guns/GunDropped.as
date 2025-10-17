namespace Drop
{
    UFUNCTION()
    void DropGun(TSubclassOf<AGunDropped> GunDropClass)
    {
        AAngelPlayerCharacter Character = GetAngelCharacter(0);
        UHolsterComponent Holster = UHolsterComponent::Get(Character);
        AGunBase CurrentGun = Holster.EquippedGun;

        AGunDropped DroppedGun = SpawnActor(GunDropClass, Character.ActorLocation + FVector(0, 0, 75), FRotator::ZeroRotator, FName(f"Dropped {CurrentGun.GunName}"));
        DroppedGun.GunClassToGrant = CurrentGun.GetClass();
        DroppedGun.CurrentAmmo = CurrentGun.CurrentAmmo;
        DroppedGun.ReserveAmmo = CurrentGun.ReserveAmmo;
        DroppedGun.Mesh.SkeletalMeshAsset = CurrentGun.GunMesh.SkeletalMeshAsset;

        Holster.RemoveGun(CurrentGun);

        DroppedGun.Box.AddImpulse(UCameraComponent::Get(Character).ForwardVector * 250, NAME_None, true);

        CurrentGun.DestroyActor();

        
    }
}

class AGunDropped : AActor
{
    UPROPERTY()
    TSubclassOf<AGunDropped> Blueprint;

    UPROPERTY(Category = "Gun", EditDefaultsOnly, ExposeOnSpawn)
    TSubclassOf<AGunBase> GunClassToGrant;

    UPROPERTY(DefaultComponent, RootComponent)
    UBoxComponent Box;

    UPROPERTY(DefaultComponent, Attach = Box)
    USkeletalMeshComponent Mesh;

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
        OldGun = Holster.EquippedGun;

        AGunDropped NewDroppedGun = SpawnActor(Blueprint, Character.ActorLocation + FVector(0, 0, 75), FRotator::ZeroRotator, FName(f"Dropped {GunClassToGrant.DefaultObject.GunName}"));
        NewDroppedGun.GunClassToGrant = OldGun.GetClass();
        NewDroppedGun.CurrentAmmo = OldGun.CurrentAmmo;
        NewDroppedGun.ReserveAmmo = OldGun.ReserveAmmo;
        NewDroppedGun.Mesh.SkeletalMeshAsset = OldGun.GunMesh.SkeletalMeshAsset;

        Holster.GrantGun(GunClassToGrant, true, FEquipData(EEquipSpeed::Normal, false, CurrentAmmo, ReserveAmmo));

        NewDroppedGun.Box.AddImpulse(UCameraComponent::Get(Character).ForwardVector * 250, NAME_None, true);

        DestroyActor();
    }
};