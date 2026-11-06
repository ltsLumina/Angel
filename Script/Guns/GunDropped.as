namespace Drop
{
	UFUNCTION()
	void DropGun(TSubclassOf<AGunDropped> GunDropClass)
	{
		AAngelPlayerCharacter Character = Game::Player;
		UHolsterComponent Holster = UHolsterComponent::Get(Character);
		AGunBase CurrentGun = Holster.EquippedGun;
		UGunComponent GunComponent = UGunComponent::Get(Character);

		AGunDropped DroppedGun = SpawnActor(GunDropClass, Character.ActorLocation + FVector(0, 0, 75), FRotator::ZeroRotator, FName(f"Dropped {GunComponent.WeaponDefinition.WeaponName}"));
		DroppedGun.GunClassToGrant = CurrentGun.GetClass();
		DroppedGun.CurrentAmmo = GunComponent.CurrentAmmo;
		DroppedGun.ReserveAmmo = GunComponent.ReserveAmmo;
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

	UPROPERTY(Category = "Gun")
	TSubclassOf<AGunBase> GunClassToGrant;

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;

	UPROPERTY(DefaultComponent, Attach = Box)
	USkeletalMeshComponent Mesh;

	AGunBase OldGun;

	int CurrentAmmo;
	int ReserveAmmo;

#if EDITOR
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        SetActorLabel(f"Dropped {GunClassToGrant.DefaultObject.GetName()}");
    }
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentAmmo = 0;
		ReserveAmmo = 0;

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION()
	void PickupGun()
	{
		AAngelPlayerCharacter Character = Game::Player;
		UHolsterComponent Holster = UHolsterComponent::Get(Game::Player);
		OldGun = Holster.EquippedGun;
		UGunComponent GunComponent = UGunComponent::Get(Character);

		AGunDropped NewDroppedGun = SpawnActor(Blueprint, Character.ActorLocation + FVector(0, 0, 75), FRotator::ZeroRotator, FName(f"Dropped {GunClassToGrant.DefaultObject.GetName()}"));
		NewDroppedGun.GunClassToGrant = OldGun.GetClass();
		NewDroppedGun.CurrentAmmo = GunComponent.CurrentAmmo;
		NewDroppedGun.ReserveAmmo = GunComponent.ReserveAmmo;
		NewDroppedGun.Mesh.SkeletalMeshAsset = OldGun.GunMesh.SkeletalMeshAsset;

		Holster.GrantGun(GunClassToGrant, true, FEquipParams(EEquipSpeed::Normal, false, CurrentAmmo, ReserveAmmo));

		NewDroppedGun.Box.AddImpulse(UCameraComponent::Get(Character).ForwardVector * 250, NAME_None, true);

		DestroyActor();
	}
};