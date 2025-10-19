UCLASS(Abstract)
class UAbilityWidget : UUserWidget
{
	UPROPERTY(Category = "Config", BlueprintReadOnly, ExposeOnSpawn)
	FText AbilityName;
	default AbilityName = FText::FromString("Ability");

	UPROPERTY(Category = "Config", BlueprintReadOnly)
	EAbility AbilityType = EAbility::Basic_C;

	UPROPERTY(Category = "Config", BlueprintReadOnly, ExposeOnSpawn)
	FName AbilityID;
	default AbilityID = NAME_None;

	UPROPERTY(Category = "Config", BlueprintReadOnly, ExposeOnSpawn, Meta = (ClampMin = "1", UIMin = "1", ClampMax = "3", UIMax = "3"))
	int Charges = 1;

	UPROPERTY(Category = "Config", BlueprintReadOnly, VisibleAnywhere)
	int RemainingCharges;
	default RemainingCharges = Charges;

	UPROPERTY(Category = "Config", BlueprintReadOnly, ExposeOnSpawn)
	bool IsUltimate = false;

	UPROPERTY(Category = "Config", BlueprintReadOnly, ExposeOnSpawn, Meta = (EditCondition = "IsUltimate == true", EditConditionHides, ClampMin = "1", UIMin = "1", ClampMax = "8", UIMax = "8"))
	int NumUltimatePoints = 8;

	UPROPERTY(Category = "Config", BlueprintReadOnly, ExposeOnSpawn)
	UTexture2D Icon;

	/**
	 * A default icon to use if no icon is specified.
	 */
	UPROPERTY(Category = "Config", EditDefaultsOnly, BlueprintReadOnly, ExposeOnSpawn, Meta = (EditCondition = "Icon == nullptr", EditConditionHides))
	UTexture2D DefaultIcon;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BP_Construct();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		RemainingCharges = Math::Clamp(Math::RoundToInt(GetAngelCharacter().Attributes.GetAbilityUses(AbilityType)), 0, Charges);
		
		BP_Tick(MyGeometry, InDeltaTime);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(FGeometry MyGeometry, float InDeltaTime)
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

	UFUNCTION()
	void SetWidgetRemainingCharges(UHorizontalBox ParentWidget, TArray<UWidget> Children, FLinearColor AvailableColour, FLinearColor UnavailableColour)
	{
		if (RemainingCharges == Children.Num())
		{
			for (UWidget Child : Children)
			{
                auto Image = Cast<UImage>(Child);
                if (Image != nullptr)
                {
                    Image.SetColorAndOpacity(AvailableColour);
                }
			}
		}
        else
        {
           for (int i = 0; i < Children.Num(); i++)
		   {
			   auto Image = Cast<UImage>(Children[i]);
			   if (Image != nullptr)
			   {
				   if (i < RemainingCharges)
				   {
					   Image.SetColorAndOpacity(AvailableColour);
				   }
				   else
				   {
					   Image.SetColorAndOpacity(UnavailableColour);
				   }
			   }
		   }
        }
	}
};