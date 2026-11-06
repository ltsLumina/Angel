class UWeaponRegistrySubsystem : UScriptGameInstanceSubsystem
{
	// Editor-filled mapping: WeaponID -> DataAsset (soft)
	UPROPERTY(Category = "Weapons")
	TMap<FName, TSoftObjectPtr<UWeaponDefinition>> Weapons;

	// Runtime fast cache (resolved pointers) - not serialized
	TMap<FName, UWeaponDefinition> LoadedWeapons;

	// Get asset synchronously (or nullptr)
	UWeaponDefinition GetWeaponDataSync(FName Id)
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

    UWeaponDefinition Asset;

	UFUNCTION()
	private void OnWeaponDataLoaded(UObject LoadedObject)
	{
        Asset = Cast<UWeaponDefinition>(LoadedObject);
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
