UCLASS(Abstract)
class UHolsterComponent : UActorComponent
{
    // The classes of guns that can be holstered
    UPROPERTY(BlueprintReadOnly, Category = "Holster")
    TArray<TSubclassOf<AGunBase>> InitialGuns;

    // The guns that are currently in the holster
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Holster")
    TArray<AGunBase> Guns;

    UPROPERTY(EditDefaultsOnly, Category = "Holster | Debug")
    int MaxGuns = 3;

    // The currently equipped gun
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Holster")
    AGunBase EquippedGun;

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

        for (TSubclassOf<AGunBase> GunClass : InitialGuns)
        {
            CreateGun(GunClass);
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

    UFUNCTION()
    AGunBase CreateGun(TSubclassOf<AGunBase> GunClass)
    {
        AGunBase NewGun = SpawnActor(GunClass);
            if (IsValid(NewGun))
            {
                Guns.Add(NewGun);
                NewGun.AttachToComponent(ArmsMesh, n"ik_hand_gun", EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, true);
                NewGun.SetActorHiddenInGame(true);
                NewGun.ActorTickEnabled = false;
                return NewGun;
            }
            else
            {
                PrintError(f"Failed to spawn gun of class: {GunClass.DefaultObject.GetName()}");
                return nullptr;
            }
    }

    UFUNCTION(Category = "Holster")
    void GrantGun(TSubclassOf<AGunBase> GunClass)
    {
        if (!HasGun(GunClass))
        {
            EquipGun(CreateGun(GunClass));
        }
        else
        {
            ReplaceGun(GunClass, GunClass);
        }
    }

    UFUNCTION(Category = "Holster")
    void EquipGun(AGunBase Gun)
    {
        if (IsValid(Gun))
        {
            if (IsValid(EquippedGun))
            {
                // Hide all guns
                for (AGunBase ExistingGun : Guns)
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
            
            Gun.SetOwner(GetOwner());
            Gun.SetActorHiddenInGame(false);
            Gun.ActorTickEnabled = true;

            EquippedGun = Gun;
            GunComponent.EquippedGun = Gun;

            BP_OnGunEquipped(Gun, GunComponent);
        }
    }

    bool HasGun(TSubclassOf<AGunBase> GunClass)
    {
        for (AGunBase Gun : Guns)
        {
            if (Gun.IsA(GunClass))
                return true;
        }
        return false;
    }

    UFUNCTION(Category = "Holster")
    void ReplaceGun(TSubclassOf<AGunBase> OldGun, TSubclassOf<AGunBase> NewGun)
    {
        for (int i = 0; i < Guns.Num(); i++)
        {
            if (Guns[i].IsA(OldGun))
            {
                AGunBase NewGunInstance = CreateGun(NewGun);
                if (IsValid(NewGunInstance))
                {
                    Guns[i].DestroyActor();
                    Guns[i] = NewGunInstance;
                    if (EquippedGun.IsA(OldGun))
                    {
                        EquipGun(NewGunInstance);
                    }
                }
                return;
            }
        }
        PrintError(f"Cannot replace gun: {OldGun.DefaultObject.GetName()} not found in holster.");
    }

    UFUNCTION(BlueprintEvent, Category = "Holster", Meta = (DisplayName = "Gun Equipped"))
    void BP_OnGunEquipped(AGunBase Gun, UGunComponent InGunComponent) 
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