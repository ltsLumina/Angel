class UHolsterComponent : UActorComponent
{
    // The classes of guns that can be holstered
    UPROPERTY(BlueprintReadOnly, Category = "Holster")
    TArray<TSubclassOf<AManualGun>> InitialGuns;

    // The guns that are currently in the holster
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Holster")
    TArray<AManualGun> Guns;

    UPROPERTY(EditDefaultsOnly, Category = "Holster | Debug")
    int MaxGuns = 3;

    // The currently equipped gun
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Holster")
    AManualGun EquippedGun;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Holster")
    int EquippedGunIndex;

    UPROPERTY(EditDefaultsOnly, Category = "Holster | Debug")
    bool AutoEquipFirstGun;
    default AutoEquipFirstGun = true;

    USkeletalMeshComponent ArmsMesh;
    UGunComponent GunComponent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ArmsMesh = Cast<USkeletalMeshComponent>(GetOwner().GetComponentsByTag(USkeletalMeshComponent, n"Character Arms")[0]);
        if (!IsValid(ArmsMesh))
        {
            PrintError("Holster component requires a 'Character Arms (Mesh)' component on the owner actor!");
            return;
        }

        GunComponent = UGunComponent::Get(GetOwner());
        if (!IsValid(UGunComponent::Get(GetOwner())))
        {
            PrintError("Holster component requires a GunComponent on the owner actor!");
            return;
        }

        for (TSubclassOf<AManualGun> GunClass : InitialGuns)
        {
            AManualGun NewGun = SpawnActor(GunClass);
            if (IsValid(NewGun))
            {
                Guns.Add(NewGun);
                NewGun.AttachToComponent(ArmsMesh, n"ik_hand_gun", EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, true);
                NewGun.SetActorHiddenInGame(true);
                NewGun.ActorTickEnabled = false;
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

    UFUNCTION(Category = "Holster")
    void EquipGun(AManualGun Gun)
    {
        if (IsValid(Gun))
        {
            if (IsValid(EquippedGun))
            {
                // Hide all guns
                for (AManualGun ExistingGun : Guns)
                {
                    ExistingGun.SetActorHiddenInGame(true);
                    ExistingGun.ActorTickEnabled = false;
                }
            }

            if (!Guns.Contains(Gun))
            {
                // Gun is not in the holster, add it
                Guns.Add(Gun);

                // Set the new gun as the equipped gun
                Gun.AttachToComponent(ArmsMesh, n"GripPoint", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
            }
            
            Gun.SetActorHiddenInGame(false);
            Gun.ActorTickEnabled = true;

            EquippedGun = Gun;
            GunComponent.EquippedGun = Gun;

            BP_OnGunEquipped(Gun, GunComponent);
        }
    }

    UFUNCTION(BlueprintEvent, Category = "Holster", Meta = (DisplayName = "Gun Equipped"))
    void BP_OnGunEquipped(AManualGun Gun, UGunComponent InGunComponent) 
    { }

    UFUNCTION(Category = "Holster", Meta = (AdvancedDisplay= "OptionalIndex"))
    void CycleGun(float Direction = 1.0f, int OptionalIndex = -1)
    {
        if (Guns.Num() == 0) return;

        int NumGuns = Guns.Num();
        int NextIndex = EquippedGunIndex + int(Direction);

        // Handle wrapping with float direction
        if (NextIndex < 0) NextIndex = NumGuns - 1;
        else if (NextIndex >= NumGuns) NextIndex = 0;

        // If an optional index is provided, use it instead
        if (OptionalIndex >= 0 && OptionalIndex < NumGuns)
        {
            NextIndex = OptionalIndex;
        }

        SwitchGun(NextIndex);
    }

    UFUNCTION(Category = "Holster")
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
};