UCLASS(Abstract)
class UShopItemWidget : UUserWidget
{
	UPROPERTY(Category = "UI", BlueprintReadOnly)
	FText ItemName;
	default ItemName = FText::FromString("???");

	UPROPERTY(Category = "UI", NotVisible, BlueprintReadOnly)
	FName ItemID;
	default ItemID = n"unknown_item";

	UPROPERTY(Category = "UI", BlueprintReadOnly)
	int ItemCost;
	default ItemCost = 2900;

	UPROPERTY(Category = "UI", BlueprintReadOnly)
	UTexture2D ItemIcon;

    UPROPERTY(Category = "UI")
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
		ItemID = FName(ItemName.ToString());
		GunName.SetText(ItemName);
		CostText.SetText(GetPrettyCost());
        
        BP_PreConstruct(IsDesignTime);
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (IsValid(GunClass))
		{
			auto Character = GetAngelCharacter(0);

			IsOwned = Character.HolsterComponent.HasGun(GunClass);
			if (IsOwned)
			{
				CostText.Text = FText::FromString("OWNED");
			}
		}

		BP_Construct();
	}
	
	UFUNCTION(BlueprintEvent, DisplayName = "Pre Construct")
    void BP_PreConstruct(bool IsDesignTime) { }

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct() { }

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
		Purchase();
		return FEventReply::Handled();
	}

	UPROPERTY(Category = "Shop")
	TSubclassOf<AGunBase> GunClass;

	void Purchase()
	{
		Print(f"Purchased {ItemName}");
        CostText.Text = FText::FromString("OWNED");
        IsOwned = true;

		auto Character = GetAngelCharacter(0);
		Character.HolsterComponent.GrantGun(GunClass);
	}
}