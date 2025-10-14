UCLASS(Abstract)
class UShopItemWidget : UUserWidget
{
	UPROPERTY(Category = "UI | Gun")
	TSubclassOf<AGunBase> GunClass;

	UPROPERTY(Category = "UI | Gun", BlueprintReadOnly)
	FText ItemName;
	default ItemName = FText::FromString("???");

	UPROPERTY(Category = "UI | Gun", NotVisible, BlueprintReadOnly)
	FName ItemID;
	default ItemID = n"unknown_item";

	UPROPERTY(Category = "UI | Gun", BlueprintReadOnly)
	int ItemCost;
	default ItemCost = 2900;

	UPROPERTY(Category = "UI | Gun", BlueprintReadOnly)
	UTexture2D ItemIcon;

	UPROPERTY(Category = "UI | Gun")
	bool IsOwned;

	// UI Elements

	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UImage Icon;

	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UTextBlock GunName;

	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UTextBlock CostText;

	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UImage Background;

	UPROPERTY(Category = "UI", BlueprintReadOnly, BindWidget)
	UImage Border;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		if (IsValid(ItemIcon))
			Icon.SetBrushFromTexture(ItemIcon);
		ItemName = FText::FromString(ItemName.ToString().ToUpper());
		ItemID = FName(ItemName.ToString());
		GunName.SetText(ItemName);
		if (IsOwned)
		{
			CostText.Text = FText::FromString("OWNED");
		}
		else
		{
			CostText.SetText(GetPrettyCost());
		}

		BP_PreConstruct(IsDesignTime);
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (IsValid(GunClass))
		{
			auto Character = GetAngelCharacter(0);
			IsOwned = Character.HolsterComponent.HasGun(GunClass);

			if (IsValid(ItemIcon))
				Icon.SetBrushFromTexture(ItemIcon);
			ItemName = FText::FromString(ItemName.ToString().ToUpper());
			ItemID = FName(ItemName.ToString());
			GunName.SetText(ItemName);
			if (IsOwned)
			{
				CostText.Text = FText::FromString("OWNED");
			}
			else
			{
				CostText.SetText(GetPrettyCost());
			}
		}

		BP_Construct();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Pre Construct")
	void BP_PreConstruct(bool IsDesignTime)
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

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

	float PreviousOpacity;

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		// highlight the item
		PreviousOpacity = Background.ColorAndOpacity.A;
		Background.SetOpacity(1);
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		Background.SetOpacity(PreviousOpacity);
		
		Purchase();
		return FEventReply::Handled();
	}

	void Purchase()
	{
		Print(f"Purchased {ItemName}");
		CostText.Text = FText::FromString("OWNED");
		IsOwned = true;

		auto Character = GetAngelCharacter(0);
		Character.HolsterComponent.GrantGun(GunClass);

		Purchased(GunClass, ItemCost);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Purchased")
	void Purchased(TSubclassOf<AGunBase> InGunClass, int InCost) { }
}