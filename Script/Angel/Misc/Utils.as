namespace String
{
	/**
	 * Inserts a substring into a string at the specified index.
	 * Because angelscript doesn't have a built-in function for this.
	 */
	UFUNCTION(Category = "String")
	void Insert(FString&out InString, FString ToInsert, int Index)
	{
		if (Index < 0 || Index > InString.Len())
		{
			return;
		}
		InString = InString.Left(Index) + ToInsert + InString.RightChop(Index);
	}
}

namespace Credits
{
    UFUNCTION(BlueprintPure, Category = "UI | Economy")
	int GetCredits() property
	{
		AAngelPlayerState PlayerState = Game::PlayerState;
		return PlayerState.Credits;
	}
    
	UFUNCTION(BlueprintPure, Category = "UI | Economy", DisplayName = "Get Credits (Pretty)")
	FText GetCreditsFormatted() property
	{
		AAngelPlayerState PlayerState = Game::PlayerState;
		return Format(PlayerState.Credits);
	}

	UFUNCTION(BlueprintPure, Category = "UI | Economy", DisplayName = "Format Credits")
	FText Format(int Credits)
	{
		FString Pretty;

		FNumberFormattingOptions FormatOptions;
		FormatOptions.SetUseGrouping(false);
		FormatOptions.SetMaximumIntegralDigits(4);
		FormatOptions.SetMaximumFractionalDigits(0);
		Pretty = FText::AsNumber(Credits, FormatOptions).ToString();
		if (Credits >= 1000)
		{
			String::Insert(Pretty, ",", 1);
		}

		return FText::FromString(f"¤{Pretty}");
	}
}

namespace Math
{
	UFUNCTION(BlueprintPure)
	float ToMeters(float DistanceInCm)
	{
		return DistanceInCm / 100.0f;
	}
}

namespace Hit
{
	UFUNCTION(BlueprintPure)
	FBodyPartHit GetBodyPartHit(UPrimitiveComponent Component)
	{
		if (!IsValid(Component))
			return FBodyPartHit();

		if (Component.ComponentTags.Contains(n"Head"))
		{
			return FBodyPartHit(true, false, false, EBodyPart::Head);
		}
		else if (Component.ComponentTags.Contains(n"Body"))
		{
			return FBodyPartHit(false, true, false, EBodyPart::Body);
		}
		else if (Component.ComponentTags.Contains(n"Legs"))
		{
			return FBodyPartHit(false, false, true, EBodyPart::Legs);
		}

		return FBodyPartHit();
	}
}