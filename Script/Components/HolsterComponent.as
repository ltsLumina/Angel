UCLASS(Abstract)
class UHolsterComponent : UActorComponent
{
	UPROPERTY(Category = "Holster | Guns", EditDefaultsOnly, BlueprintReadOnly)
	TArray<TSubclassOf<AGunBase>> InitialGuns;

	UPROPERTY(Category = "Holster | Guns", VisibleAnywhere, BlueprintReadOnly)
	TArray<AGunBase> HolsteredGuns;

	UPROPERTY(Category = "Holster | Guns", VisibleAnywhere, BlueprintReadOnly)
	AGunBase EquippedGun;

	UPROPERTY(Category = "Holster | Guns", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = GetEquippedGunIndex)
	int EquippedGunIndex;

	UPROPERTY(Category = "Holster | Current", VisibleAnywhere, BlueprintReadOnly)
	AGunBase Primary; // always has index 0

	UPROPERTY(Category = "Holster | Current", VisibleAnywhere, BlueprintReadOnly)
	AGunBase Sidearm; // always has index 1

	// - holster helpers
	UFUNCTION(BlueprintPure)
	int GetEquippedGunIndex()
	{
		return HolsteredGuns.FindIndex(EquippedGun);
	}

	// - flags

	UPROPERTY(Category = "Holster", VisibleAnywhere)
	bool IsEquipping;

	USkeletalMeshComponent ArmsMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ArmsMesh = Cast<USkeletalMeshComponent>(GetOwner().GetComponentsByTag(USkeletalMeshComponent, n"Character Arms")[0]);
		if (!IsValid(ArmsMesh))
		{
			PrintError("Holster component requires a 'Character Arms (Mesh)' component on the owner actor!");
			return;
		}

		for (TSubclassOf<AGunBase> GunClass : InitialGuns)
		{
			GrantGun(GunClass, false);
		}

		if (HolsteredGuns.Num() > 0)
		{
			EquipGun(HolsteredGuns[0], FEquipData(EEquipSpeed::Fast, true));
		}

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	/*
			Sidearm = NewGun.GunType == EGunType::Sidearm ? NewGun : Sidearm;
			Primary = NewGun.GunType != EGunType::Sidearm ? NewGun : Primary;
	*/

	UFUNCTION(Category = "Holster")
	AGunBase CreateGun(TSubclassOf<AGunBase> GunClass)
	{
		AGunBase NewGun = SpawnActor(GunClass);
		if (IsValid(NewGun))
		{
			NewGun.AttachToComponent(ArmsMesh, n"ik_hand_gun", EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, true);
			//NewGun.AttachToComponent(ArmsMesh, n"GripPoint", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
			NewGun.SetActorHiddenInGame(true);
			return NewGun;
		}
		else
		{
			PrintError(f"Failed to spawn gun of class: {GunClass.DefaultObject.GetName()}");
			return nullptr;
		}
	}

	/**
	 * Equips the specified gun by instance, hiding all others.
	 * @param Gun The gun to equip.
	 * @param Speed The speed at which to equip the gun.
	 * @param Refresh If true, the gun's ammo will be refilled to max. (useful for testing or when purchasing a new gun)
	 */
	UFUNCTION(Category = "Holster")
	void EquipGun(AGunBase Gun, FEquipData EquipData)
	{
		for (AGunBase ExistingGun : HolsteredGuns)
		{
			ExistingGun.SetActorHiddenInGame(true);
		}

		// If the gun isn't already in our holster, add it
		if (!HolsteredGuns.Contains(Gun))
		{
			if (Gun.GunType == EGunType::Sidearm && HasSidearm())
			{
				// replace existing sidearm
				HolsteredGuns.Remove(Sidearm);
				Sidearm.DestroyActor();

				Sidearm = Gun;
				Print("Replaced existing sidearm with new one.");
			}
			else if (Gun.GunType != EGunType::Sidearm && !HasPrimary())
			{
				// replace existing primary
				HolsteredGuns.Remove(Primary);
				Primary.DestroyActor();

				Primary = Gun;
				Print("Replaced existing primary with new one.");
			}

			Gun.SetOwner(GetOwner());
			Gun.SetActorHiddenInGame(false); // <<<<<<<<<<<< TODO
			HolsteredGuns.Add(Gun);
		}

		if (EquipData.Reload)
		{
			Gun.CurrentAmmo = Gun.MaxAmmo;
			Gun.ReserveAmmo = Gun.MaxReserveAmmo;
		}

		EquippedGun = Gun;
		Primary = Gun.GunType != EGunType::Sidearm ? Gun : Primary;
		Sidearm = Gun.GunType == EGunType::Sidearm ? Gun : Sidearm;

		BP_GunEquipped(Gun, EquipData.Speed); // regular equip uses normal speed. Can be overridden based on context.
	}

	/**
	 *  Equip gun by class, if it exists in the holster.
	 */
	UFUNCTION(Category = "Holster")
	void EquipGunByClass(TSubclassOf<AGunBase> GunClass, FEquipData EquipData)
	{
		for (AGunBase Gun : HolsteredGuns)
		{
			if (IsValid(Gun) && Gun.GetClass() == GunClass)
			{
				EquipGun(Gun, EquipData);
				return;
			}
		}

		PrintError(f"Cannot equip gun of class {GunClass.DefaultObject.GetName()} because it is not in the holster.");
	}

	UFUNCTION(BlueprintEvent, Category = "Holster", DisplayName = "Gun Equipped")
	void BP_GunEquipped(AGunBase Gun, EEquipSpeed Speed = EEquipSpeed::Normal)
	{}

	UFUNCTION(BlueprintPure, Category = "Holster | Guns")
	bool HasGunOfType(EGunType Type)
	{
		for (AGunBase Gun : HolsteredGuns)
		{
			if (IsValid(Gun) && Gun.GunType == Type)
			{
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintPure, Category = "Holster | Guns")
	bool HasPrimary()
	{
		return IsValid(Primary);
	}

	UFUNCTION(BlueprintPure, Category = "Holster | Guns")
	bool HasSidearm()
	{
		return IsValid(Sidearm);
	}

	UFUNCTION(BlueprintPure, Category = "Holster | Guns")
	bool HasGun(TSubclassOf<AGunBase> GunClass)
	{
		for (AGunBase Gun : HolsteredGuns)
		{
			if (IsValid(Gun) && Gun.GetClass() == GunClass)
			{
				return true;
			}
		}
		return false;
	}

	UFUNCTION(Category = "Holster")
	void GrantGun(TSubclassOf<AGunBase> GunClass, bool AutoEquip = true, FEquipData EquipData = FEquipData())
	{
		if (!HasGun(GunClass))
		{
			AGunBase NewGun = CreateGun(GunClass);
			if (IsValid(NewGun))
			{
				NewGun.SetOwner(GetOwner());
				NewGun.SetActorHiddenInGame(true);
				HolsteredGuns.Add(NewGun);
				Print(f"Granted new gun: {NewGun.GetName()}");

				if (AutoEquip)
				{
					EquipGun(NewGun, EquipData);
				}
			}
		}
		else
		{
			EquipGunByClass(GunClass, FEquipData(EEquipSpeed::Normal, true));
		}
	}

	UFUNCTION(Category = "Holster", DisplayName = "OptionalIndex")
	void CycleGun(float Direction = 1.0f, int OptionalIndex = -1)
	{
		if (HolsteredGuns.Num() == 0)
			return;

		int NumGuns = HolsteredGuns.Num();
		int NextIndex = EquippedGunIndex + int(Direction);

		// Handle wrapping with float direction
		if (NextIndex < 0)
			NextIndex = NumGuns - 1;
		else if (NextIndex >= NumGuns)
			NextIndex = 0;

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
		if (HolsteredGuns.IsValidIndex(Index))
		{
			EquipGun(HolsteredGuns[Index], FEquipData(EEquipSpeed::Normal));
			EquippedGunIndex = Index;
		}
		else
		{
			PrintError(f"Invalid gun index: {Index}. Total guns available: {HolsteredGuns.Num()}");
		}
	}
};