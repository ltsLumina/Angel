UCLASS(Abstract)
class UShopItemWidget : UUserWidget
{
	UPROPERTY(Category = "UI", BlueprintReadOnly)
	FText ItemName;
	default ItemName = FText::FromString("???");

	UPROPERTY(Category = "UI", BlueprintReadOnly)
	int ItemCost;
	default ItemCost = 2900;

	UPROPERTY(Category = "UI", BlueprintReadOnly)
	UTexture2D ItemIcon;

    UPROPERTY(Category = "UI", BlueprintReadOnly)
    bool IsOwned;

	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UImage Icon;
	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UTextBlock GunName;
	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UTextBlock CostText;
	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UImage Background;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		if (IsValid(ItemIcon))
			Icon.SetBrushFromTexture(ItemIcon);
        ItemName = FText::FromString(ItemName.ToString().ToUpper());
		GunName.SetText(ItemName);
		CostText.SetText(GetPrettyCost());
        
        BP_PreConstruct(IsDesignTime);
	}

    UFUNCTION(BlueprintEvent, DisplayName = "Pre Construct")
    void BP_PreConstruct(bool IsDesignTime) { }

	FText GetPrettyCost()
	{
		// insert a comma at index 1 if cost is 4 digits
		FString PrettyCost = FText::AsNumber(ItemCost, FNumberFormattingOptions()).ToString();
		if (PrettyCost.Len() == 4)
		{
			PrettyCost = PrettyCost.Left(1) + "," + PrettyCost.Mid(1);
		}

		FString CostStr;

		if (ItemCost <= 0)
		{
			return FText::FromString("FREE");
		}
		else
		{
			CostStr = f"¤{PrettyCost}";
		}
		return FText::FromString(CostStr);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (IsOwned)
			return FEventReply::Unhandled();

		Print(f"Clicked on shop {ItemName}");
        CostText.Text = FText::FromString("OWNED");
        IsOwned = true;
		return FEventReply::Handled();
	}
}