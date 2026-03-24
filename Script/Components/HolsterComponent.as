event void FOnGunSwitched(int NewIndex);

UCLASS(Abstract)
class UHolsterComponent : UActorComponent
{
	UPROPERTY(Category = "Holster | Guns", EditDefaultsOnly, BlueprintReadOnly)
	TArray<TSubclassOf<AGunBase>> InitialGuns;

	UPROPERTY(Category = "Holster | Guns", VisibleAnywhere, BlueprintReadOnly)
	TArray<AGunBase> HolsteredGuns;

	UPROPERTY(Category = "Holster | Guns", VisibleAnywhere, BlueprintReadOnly)
	AGunBase EquippedGun;

	UPROPERTY(Category = "Holster | Current", VisibleAnywhere, BlueprintReadOnly)
	AGunBase Primary; // always has index 0

	UPROPERTY(Category = "Holster | Current", VisibleAnywhere, BlueprintReadOnly)
	AGunBase Sidearm; // always has index 1

	UPROPERTY(Category = "Events")
	FOnGunSwitched GunSwitched;

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

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//check(Sidearm != nullptr, "Holster component requires a sidearm!");

		if (!IsValid(Sidearm))
		{
			PrintError("Holster component requires a sidearm!");
			GrantGun(InitialGuns[1], true, FEquipData(EEquipSpeed::Fast, true));
		}
	}

	UFUNCTION(Category = "Holster")
	AGunBase CreateGun(TSubclassOf<AGunBase> GunClass)
	{
		AGunBase NewGun = SpawnActor(GunClass);
		if (IsValid(NewGun))
		{
			NewGun.AttachToComponent(ArmsMesh, n"ik_hand_gun", EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, true);
			// NewGun.AttachToComponent(ArmsMesh, n"GripPoint", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
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
	private void EquipGun(AGunBase Gun, FEquipData EquipData)
	{
		for (AGunBase ExistingGun : HolsteredGuns)
		{
			ExistingGun.SetActorHiddenInGame(true);
		}

		// If the gun isn't already in our holster, add it
		if (!HolsteredGuns.Contains(Gun))
		{
			HolsteredGuns.Add(Gun);
		}

		if (EquipData.Reload)
		{
			Gun.CurrentAmmo = Gun.MaxAmmo;
			Gun.ReserveAmmo = Gun.MaxReserveAmmo;
		}
		else if (EquipData.Ammo >= 0) 
		{
			Gun.CurrentAmmo = Math::Clamp(EquipData.Ammo, 0, Gun.MaxAmmo);
		}
		
		if (EquipData.ReserveAmmo >= 0) 
		{
			Gun.ReserveAmmo = Math::Clamp(EquipData.ReserveAmmo, 0, Gun.MaxReserveAmmo);
		}

		Gun.SetOwner(GetOwner());
		Gun.SetActorHiddenInGame(false);

		EquippedGun = Gun;

		if (Gun.GunType == EGunType::Sidearm && HasSidearm())
			Sidearm = Gun;
		else if (Gun.GunType != EGunType::Sidearm && HasPrimary())
			Primary = Gun;

		Gameplay::PlaySound2D(EquippedGun.GetEquipSound(EquipData.Speed));

		BP_GunEquipped(Gun, EquipData);
	}

	/**
	 *  Equip gun by class, if it exists in the holster.
	 */
	UFUNCTION(Category = "Holster")
	private void EquipGunByClass(TSubclassOf<AGunBase> GunClass, FEquipData EquipData)
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
	void BP_GunEquipped(AGunBase Gun, FEquipData EquipData)
	{}

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

	/**
	 * Grants a new gun to the holster. If the gun type already exists, it will replace the existing one.
	 * @param GunClass The class of the gun to grant.
	 * @param AutoEquip If true, the gun will be automatically equipped after being granted.
	 * @param EquipData Additional data for equipping the gun.
	 */
	UFUNCTION(Category = "Holster")
	AGunBase GrantGun(TSubclassOf<AGunBase> GunClass, bool AutoEquip = true, FEquipData EquipData = FEquipData())
	{
		if (!HasGun(GunClass))
		{
			AGunBase NewGun = CreateGun(GunClass);
			if (!IsValid(NewGun)) return nullptr;

			if (NewGun.GunType == EGunType::Sidearm && HasSidearm())
			{
				// replace existing sidearm
				HolsteredGuns.Remove(Sidearm);
				Sidearm.DestroyActor();

				Sidearm = NewGun;
				Print("Replaced existing sidearm with new one.");
			}
			else if (NewGun.GunType != EGunType::Sidearm && HasPrimary())
			{
				// replace existing primary
				HolsteredGuns.Remove(Primary);
				Primary.DestroyActor();

				Primary = NewGun;
				Print("Replaced existing primary with new one.");
			}

			NewGun.SetOwner(GetOwner());
			NewGun.SetActorHiddenInGame(true);
			HolsteredGuns.Add(NewGun);

			Primary = NewGun.GunType != EGunType::Sidearm && !HasPrimary() ? NewGun : Primary;
			Sidearm = NewGun.GunType == EGunType::Sidearm && !HasSidearm() ? NewGun : Sidearm;

			Print(f"Granted new gun: {NewGun.GunName}\nType: {NewGun.GunType}", 2, FLinearColor(0.22, 0.47, 0.75));

			if (AutoEquip)
			{
				EquipGun(NewGun, EquipData);
			}

			return NewGun;
		}
		else
		{
			EquipGunByClass(GunClass, EquipData);
			return EquippedGun;
		}
	}

	UFUNCTION()
	void RemoveGun(AGunBase Gun)
	{
		if (HolsteredGuns.Contains(Gun))
		{
			HolsteredGuns.Remove(Gun);

			if (Gun == Primary)
				Primary = nullptr;
			else if (Gun == Sidearm)
				Sidearm = nullptr;

			Gun.DestroyActor();

			// Equip the next available gun, if any
			if (HolsteredGuns.Num() > 0)
			{
				EquipGun(HolsteredGuns[0], FEquipData(EEquipSpeed::Fast, true));
			}
			return;
		}

		PrintWarning(f"Attempted to remove gun {Gun.GunName}, but it was not found in the holster.", 5);
	}

	UFUNCTION()
	void RemoveGunByClass(TSubclassOf<AGunBase> GunClass)
	{
		for (AGunBase Gun : HolsteredGuns)
		{
			if (IsValid(Gun) && Gun.GetClass() == GunClass)
			{
				RemoveGun(Gun);
				return;
			}
		}

		PrintWarning(f"Attempted to remove gun of class {GunClass.DefaultObject.GetName()}, but it was not found in the holster.", 5);
	}

	UFUNCTION(Category = "Holster")
	void CycleGun(float Direction = 1.0f, int OptionalIndex = -1)
	{
		if (HolsteredGuns.Num() == 0)
			return;

		int NumGuns = HolsteredGuns.Num();
		int EquippedIndex = HolsteredGuns.FindIndex(EquippedGun);
		int NextIndex = EquippedIndex + int(Direction);

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
			GunSwitched.Broadcast(Index);
		}
		else
		{
			PrintError(f"Invalid gun index: {Index}. Total guns available: {HolsteredGuns.Num()}");
		}
	}
};