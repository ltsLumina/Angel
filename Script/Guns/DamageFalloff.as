USTRUCT()
struct FTTKInfo
{
	UPROPERTY()
	float Health;

	UPROPERTY()
	FVector2D Range;

	UPROPERTY()
	FBodyPartHit BodyPart;

	UPROPERTY()
	int BulletsToKill;

	UPROPERTY(Meta = (Units = "Seconds"))
	int TimeToKill;
};

UCLASS(Abstract)
class UDamageFalloff : UObject
{
	/**
	 * Damage falloff over distance. The key is the distance range in meters, and the value is a vector where X = Head, Y = Body, Z = Legs.
	 * For example, a value of (156, 40, 34) at a key range of (0, 50) means that within 0 to 50 meters,
	 * headshots deal 156 damage, body shots deal 40 damage, and leg shots deal 34 damage.
	 */
	UPROPERTY(Category = "Range", VisibleAnywhere, ToolTip = "Set these values in the angelscript subclass.", Meta = (ForceInlineRow))
	TMap<FVector2D, FVector> DamageMap;

	UFUNCTION(BlueprintPure)
	float GetDamageAtDistance(float Distance, EBodyPart BodyPart)
	{
		// Sort keys to ensure correct range checking
		TArray<FVector2D> SortedKeys;
		DamageMap.GetKeys(SortedKeys);

		for (int i = 0; i < SortedKeys.Num(); i++)
		{
			FVector2D Range = SortedKeys[i];
			// Check if distance is within or beyond the last range
			if (Distance <= Range.Y || i == SortedKeys.Num() - 1)
			{
				FVector DamageValues = DamageMap[Range];
				if (BodyPart == EBodyPart::Head)
				{
					return DamageValues.X;
				}
				else if (BodyPart == EBodyPart::Body)
				{
					return DamageValues.Y;
				}
				else if (BodyPart == EBodyPart::Legs)
				{
					return DamageValues.Z;
				}
			}
		}

		return -1; // Invalid distance
	}
}

UCLASS(EditInlineNew)
class UVandalFalloff : UDamageFalloff
{
	default DamageMap.Add(FVector2D(0, 50), FVector(160, 40, 34));
}

UCLASS(EditInlineNew)
class UPhantomFalloff : UDamageFalloff
{
	default DamageMap.Add(FVector2D(0, 20), FVector(156, 39, 33));
	default DamageMap.Add(FVector2D(20, 50), FVector(140, 35, 29));
}

UCLASS(EditInlineNew)
class UClassicFalloff : UDamageFalloff
{
	default DamageMap.Add(FVector2D(0, 30), FVector(78, 26, 22));
	default DamageMap.Add(FVector2D(30, 50), FVector(66, 22, 18));
}