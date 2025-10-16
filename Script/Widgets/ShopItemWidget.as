UCLASS(Abstract)
class UShopItemWidget : UUserWidget
{
	UPROPERTY(Category = "UI | Gun")
	TSubclassOf<AGunBase> GunClass;

	UPROPERTY(Category = "UI | Gun")
	EShopCategory ShopCategory = EShopCategory::Primary;

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
	FVector2D IconSize;
	default IconSize = FVector2D(180, 50);

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
		CostText.SetText(IsOwned ? FText::FromString("OWNED") : GetPrettyCost());

		BP_PreConstruct(IsDesignTime);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Pre Construct")
	void BP_PreConstruct(bool IsDesignTime)
	{}

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

		auto ShopWidget = Cast<UShopWidget>(GetParent().GetOuter().GetOuter());
		ShopWidget.PurchasedEvent.AddUFunction(this, n"UpdateOwnershipFlag");

		BP_Construct();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOwnershipFlag(TSubclassOf<AGunBase> InGunClass, EShopCategory Category, int InCost)
	{
		if (ShopCategory != Category)
			return;

		IsOwned = UHolsterComponent::Get(GetAngelCharacter(0)).HasGun(GunClass);
		CostText.SetText(IsOwned ? FText::FromString("OWNED") : GetPrettyCost());

		Border.SetVisibility(IsOwned ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
		Background.SetColorAndOpacity(IsOwned ? FLinearColor(0, 0.5, 0.3, 0.2) : FLinearColor(0.05, 0.05, 0.05, 0.2));
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

	FText GetPrettyCost()
	{
		if (ItemCost <= 0)
		{
			return FText::FromString("FREE");
		}

		return FormatCredits(ItemCost);
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

		if (MouseEvent.GetEffectingButton() == EKeys::LeftMouseButton)
		{
			Purchase();
		}
		else if (MouseEvent.GetEffectingButton() == EKeys::RightMouseButton)
		{
			Sell();
		}
		return FEventReply::Handled();
	}

	void Purchase()
	{
		AAngelPlayerState PlayerState = GetAngelPlayerState(0);

		if (!PlayerState.CanAfford(ItemCost) && !IsOwned)
		{
			PrintWarning("Cannot afford item!", 2);
			return;
		}
		else if (!IsOwned)
		{
			PlayerState.SpendCredits(ItemCost, ShopCategory);
		}

		Print(f"Purchased {ItemName}");
		CostText.Text = FText::FromString("OWNED");
		IsOwned = true;

		if (IsValid(GunClass))
		{
			auto Character = GetAngelCharacter(0);
			Character.HolsterComponent.GrantGun(GunClass, true, FEquipData(EEquipSpeed::Fast, true));
		}

		auto ShopWidget = Cast<UShopWidget>(GetParent().GetOuter().GetOuter());
		ShopWidget.PurchasedEvent.Broadcast(GunClass, ShopCategory, ItemCost);

		Purchased(GunClass, ItemCost);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Purchased")
	void Purchased(TSubclassOf<AGunBase> InGunClass, int InCost)
	{}

	void Sell()
	{
	}
}

enum EShopCategory
{
	Sidearm,
	Primary,
	Armor,
	Ability
}

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