UCLASS(Abstract, EditInlineNew)
class UDamageFalloff : UObject
{
    /**
	 * Damage falloff over distance. The key is the distance range in meters, and the value is a vector where X = Head, Y = Body, Z = Legs.
	 * For example, a value of (156, 40, 34) at a key range of (0, 50) means that within 0 to 50 meters,
	 * headshots deal 156 damage, body shots deal 40 damage, and leg shots deal 34 damage.
	 */
    UPROPERTY(Category = "Range", EditDefaultsOnly)
    TMap<FVector2D, FVector> DamageMap;

    UFUNCTION(BlueprintPure)
	float GetDamageAtDistance(float Distance, bool Headshot)
	{
		// Sort keys to ensure correct range checking
		TArray<FVector2D> SortedKeys;
		DamageMap.GetKeys(SortedKeys);

		for (int i = 0; i < SortedKeys.Num(); i++)
		{
			FVector2D Range = SortedKeys[i];
			if (Distance <= Range.Y)
			{
				FVector DamageValues = DamageMap[Range];
				if (Headshot)
				{
					//Print(f"Headshot damage at {Distance}m: {DamageValues.X}", 2, FLinearColor(1.00, 0.00, 0.00));
					return DamageValues.X;
				}
				else
				{
					//Print(f"Body/Leg damage at {Distance}m: {DamageValues.Y}", 2, FLinearColor(0.02, 1.00, 0.02));
					return DamageValues.Y;
				}
			}
		}

		return DamageMap[SortedKeys.Last()].Y; // Return the lowest damage if out of range
	}
}

UCLASS(EditInlineNew)
class UVandalFalloff : UDamageFalloff
{
    default DamageMap.Add(FVector2D(0, 50), FVector(150, 40, 34));
}

UCLASS(EditInlineNew)
class UPhantomFallof : UDamageFalloff
{
    default DamageMap.Add(FVector2D(0, 20), FVector(156, 39, 33));
    default DamageMap.Add(FVector2D(20, 50), FVector(140, 35, 29));
}