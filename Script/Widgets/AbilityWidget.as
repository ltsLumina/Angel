UCLASS(Abstract)
class UAbilityWidget : UUserWidget
{
	UPROPERTY(Category = "Config", BlueprintReadOnly, ExposeOnSpawn)
	FText AbilityName;
	default AbilityName = FText::FromString("Ability");

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
		RemainingCharges = Charges;
		BP_Construct();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

	UFUNCTION()
	void CommitWidget()
	{
		if (RemainingCharges > 0)
		{
			RemainingCharges--;
		}
	}

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
            auto Child = ParentWidget.GetChildAt(RemainingCharges);
            if (Child != nullptr)
            {
                auto Image = Cast<UImage>(Child);
                if (Image != nullptr)
                {
                    Image.SetColorAndOpacity(UnavailableColour);
                }
            }
        }
	}
};