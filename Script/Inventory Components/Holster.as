class UHolster : UActorComponent
{
    // The classes of guns that can be holstered
    UPROPERTY(Category = "Holster")
    TArray<TSubclassOf<AManualGun>> GunClasses;

    // The guns that are currently in the holster
    UPROPERTY(VisibleAnywhere, Category = "Holster")
    TArray<AManualGun> Guns;

    // The currently equipped gun
    UPROPERTY(VisibleAnywhere, Category = "Holster")
    AManualGun EquippedGun;

    UPROPERTY(VisibleAnywhere, Category = "Holster")
    int EquippedGunIndex;

    UPROPERTY(EditDefaultsOnly, Category = "Holster | Debug")
    bool AutoEquipFirstGun;
    default AutoEquipFirstGun = true;

    USkeletalMeshComponent ArmsMesh;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ArmsMesh = Cast<USkeletalMeshComponent>(GetOwner().GetComponentsByTag(USkeletalMeshComponent::StaticClass(), n"FirstPersonMesh")[0]);
        if (!IsValid(ArmsMesh))
        {
            PrintError("Holster component requires a FirstPersonMesh component on the owner actor!");
            return;
        }

        for (TSubclassOf<AManualGun> GunClass : GunClasses)
        {
            AManualGun NewGun = SpawnActor(GunClass);
            if (IsValid(NewGun))
            {
                Guns.Add(NewGun);
                NewGun.AttachToComponent(ArmsMesh, n"GripPoint", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
                NewGun.SetActorHiddenInGame(true);
            }
            else
            {
                PrintError(f"Failed to spawn gun of class: {GunClass.DefaultObject.GetName()}");
            }
        }

        // Initialize the equipped gun to the first gun in the list, if available
        if (Guns.Num() > 0 && AutoEquipFirstGun)
        {
            EquipGun(Guns[0]);
        }
        else if (AutoEquipFirstGun)
        {
            PrintError("Holster has no guns to equip!");
        }

        // Call the Blueprint BeginPlay event
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintCallable, Category = "Holster")
    void EquipGun(AManualGun Gun)
    {
        if (IsValid(Gun))
        {
            if (IsValid(EquippedGun))
            {
                // Hide the currently equipped gun
                EquippedGun.SetActorHiddenInGame(true);
            }

            // Set the new gun as the equipped gun
            Gun.AttachToComponent(ArmsMesh, n"GripPoint", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
            Gun.SetActorHiddenInGame(false);
            EquippedGun = Gun;

            OnGunEquipped(Gun);
        }
    }

    void OnGunEquipped(AManualGun Gun)
    {
        BP_OnGunEquipped(Gun);
    }

    UFUNCTION(BlueprintEvent, Category = "Holster", Meta = (DisplayName = "Gun Equipped"))
    void BP_OnGunEquipped(AManualGun Gun) 
    { }

    UFUNCTION(BlueprintCallable, Category = "Holster")
    void SwitchGun(int Index)
    {
        if (Guns.IsValidIndex(Index))
        {
            EquipGun(Guns[Index]);
            EquippedGunIndex = Index;
        }
        else
        {
            PrintError(f"Invalid gun index: {Index}. Total guns available: {Guns.Num()}");
        }
    }

    UFUNCTION(BlueprintCallable, Category = "Holster")
    void CycleGun()
    {
        EquippedGunIndex = (EquippedGunIndex + 1) % Guns.Num();
        SwitchGun(EquippedGunIndex);
    }
};