class UWeaponRegistrySubsystem : UScriptGameInstanceSubsystem
{
	// Editor-filled mapping: WeaponID -> DataAsset (soft)
	UPROPERTY(Category = "Weapons")
	TMap<FName, TSoftObjectPtr<UWeaponDataAsset>> Weapons;

	// Runtime fast cache (resolved pointers) - not serialized
	TMap<FName, UWeaponDataAsset> LoadedWeapons;

	// Get asset synchronously (or nullptr)
	UWeaponDataAsset GetWeaponDataSync(FName Id)
	{
        for (auto& Pair : Weapons)
        {
            Print(f"weapons: {Pair.Key}");
        }

		if (LoadedWeapons.Contains(Id))
        {
            return LoadedWeapons[Id];
        }
        else if (Weapons.Contains(Id))
        {
            Print("loading");

            FOnSoftObjectLoaded OnLoaded;
            OnLoaded.BindUFunction(this, n"OnWeaponDataLoaded");
            Weapons[Id].LoadAsync(OnLoaded);
            if (IsValid(Asset))
            {
                return Asset;
            }
            else
            {
                PrintError(f"WeaponRegistrySubsystem: Failed to load weapon data asset for ID '{Id}'");
                return nullptr;
            }
        }
        else
        {
            PrintError(f"WeaponRegistrySubsystem: No weapon registered with ID '{Id}'");
            return nullptr;
        }
	}

    UWeaponDataAsset Asset;

	UFUNCTION()
	private void OnWeaponDataLoaded(UObject LoadedObject)
	{
        Asset = Cast<UWeaponDataAsset>(LoadedObject);
        if (IsValid(Asset))
        {
            LoadedWeapons.Add(Asset.WeaponID, Asset);
            Print(f"WeaponRegistrySubsystem: Successfully loaded weapon data asset for ID '{Asset.WeaponID}'");
        }
        else
        {
            PrintError("WeaponRegistrySubsystem: OnWeaponDataLoaded received invalid object");
        }
	}


}

class UWeaponDataAsset : UPrimaryDataAsset
{
	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	TSoftClassPtr<AGunBase> WeaponClass;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	FName WeaponID;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	FText DisplayName;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	USkeletalMesh GunMesh;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	UTexture2D Icon;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	UTexture2D IconKillfeed;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	int Price;

	UPROPERTY(Category = "Weapon", BlueprintReadOnly)
	EGunType Type;
}