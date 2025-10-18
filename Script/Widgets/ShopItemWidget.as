UCLASS(Abstract)
class UShopItemWidget : UUserWidget
{
	UPROPERTY(Category = "UI | Shop")
	EShopCategory ShopCategory = EShopCategory::Primary;

	UPROPERTY(Category = "UI | Type", Meta = (InlineEditConditionToggle))
	bool GrantGun;
	default GrantGun = true;

	UPROPERTY(Category = "UI | Type", Meta = (EditCondition = "GrantGun"))
	TSubclassOf<AGunBase> GunToGrant;

	UPROPERTY(Category = "UI | Type", Meta = (InlineEditConditionToggle))
	bool GrantArmor;
	default GrantArmor = false;

	UPROPERTY(Category = "UI | Type", Meta = (EditCondition = "GrantArmor"))
	EArmorType ArmorToGrant;

	UPROPERTY(Category = "UI | Type", Meta = (InlineEditConditionToggle))
	bool GrantAbility;
	default GrantAbility = false;

	UPROPERTY(Category = "UI | Type", Meta = (EditCondition = "GrantAbility"))
	TSubclassOf<UAngelAbility> AbilityClass;

	UPROPERTY(Category = "UI | Shop", BlueprintReadOnly)
	FText ItemName;
	default ItemName = FText::FromString("???");

	UPROPERTY(Category = "UI | Shop", BlueprintReadOnly)
	int ItemCost;
	default ItemCost = 2900;

	UPROPERTY(Category = "UI | Shop", BlueprintReadOnly)
	UTexture2D ItemIcon;

	UPROPERTY(Category = "UI | Shop", BlueprintReadOnly, Meta = (EditCondition = "ItemIcon != nullptr", EditConditionHides))
	FVector2D IconSize;
	default IconSize = FVector2D(180, 50);

	UPROPERTY(Category = "UI | Visuals", BlueprintReadOnly)
	bool IsOwned;

	UPROPERTY(Category = "UI | Visuals", BlueprintReadOnly)
	FLinearColor OwnedColor;
	default OwnedColor = FLinearColor(0.05, 0.5, 0.3, 0.2);

	UPROPERTY(Category = "UI | Visuals", BlueprintReadOnly)
	FLinearColor NotOwnedColor;
	default NotOwnedColor = FLinearColor(0.05, 0.05, 0.05, 0.2);

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

	// end

	UHolsterComponent Holster;
	UShopWidget ShopWidget;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		SetIsOwned(IsOwned);

		Icon.SetBrushFromTexture(ItemIcon);
		ItemName = FText::FromString(ItemName.ToString().ToUpper());
		GunName.SetText(ItemName);
		CostText.SetText(IsOwned ? FText::FromString("OWNED") : Format(ItemCost));
		Icon.SetDesiredSizeOverride(IconSize);

		BP_PreConstruct(IsDesignTime);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Pre Construct")
	void BP_PreConstruct(bool IsDesignTime)
	{}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ShopWidget = Cast<UShopWidget>(GetParent().GetOuter().GetOuter());
		ShopWidget.PurchasedEvent.AddUFunction(this, n"UpdateOwnershipStatus");

		if (IsValid(GunToGrant))
		{
			SetIsOwned(GetAngelCharacter().HolsterComponent.HasGun(GunToGrant));
			return;
		}
		else if (GrantArmor)
		{
			SetIsOwned(HasRemainingArmor(GetAngelCharacter()));
			return;
		}
		else if (GrantAbility)
		{
			SetIsOwned(GetAngelCharacter().AbilitySystem.HasAbility(AbilityClass));
		}
		else
		{
			SetIsOwned(false);
		}

		BP_Construct();
	}

	void SetIsOwned(bool InIsOwned)
	{
		IsOwned = InIsOwned;
		if (IsOwned)
		{
			CostText.Text = FText::FromString("OWNED");

			Border.SetVisibility(ESlateVisibility::Visible);
			Background.SetColorAndOpacity(OwnedColor);
		}
		else
		{
			CostText.SetText(Format(ItemCost));

			Border.SetVisibility(ESlateVisibility::Hidden);
			Background.SetColorAndOpacity(NotOwnedColor);
		}
	}

	/**
	 * Updates the ownership status of this item based on what was just purchased.
	 */
	UFUNCTION(NotBlueprintCallable)
	void UpdateOwnershipStatus(FPurchaseData PurchaseInfo)
	{
		auto InGunClass = PurchaseInfo.GunClass;
		auto InArmorType = PurchaseInfo.ArmorType;
		auto InAbilityClass = PurchaseInfo.AbilityClass;
		auto Category = PurchaseInfo.Category;

		if (ShopCategory == Category)
		{
			if (GrantGun && IsValid(GunToGrant) && GunToGrant == InGunClass)
			{
				SetIsOwned(true);
			}
			else if (GrantArmor && ArmorToGrant == InArmorType)
			{
				SetIsOwned(true);
			}
			else if (GrantAbility)
			{
				// Abilities work differently, because you can have multiple abilities, and multiple charges of each ability.
				return;
			}
			else
			{
				SetIsOwned(false);
			}

			//GetAngelPlayerState().RefundSpend(ItemCost, ShopCategory);
		}
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

	FText Format(int InItemCost)
	{
		if (InItemCost <= 0)
		{
			return FText::FromString("FREE");
		}

		return FormatCredits(InItemCost);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		Background.SetColorAndOpacity((IsOwned || IsHovered()) ? OwnedColor : NotOwnedColor);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		Background.SetColorAndOpacity((IsOwned || IsHovered()) ? OwnedColor : NotOwnedColor);
	}

	float PreviousOpacity;

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
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
		FPurchaseData PurchaseInfo = FPurchaseData(ShopCategory, ItemCost, GunToGrant, ArmorToGrant, AbilityClass);

		if (!PlayerState.CanAfford(ItemCost) && !IsOwned)
		{
			PrintWarning("Cannot afford item!", 2);
			return;
		}
		else if (!IsOwned)
		{
			PlayerState.RecordSpend(ItemCost, ShopCategory);
		}

		Print(f"Purchased {ItemName}");
		CostText.Text = FText::FromString("OWNED");

		if (IsValid(GunToGrant))
		{
			auto Character = GetAngelCharacter(0);
			PreviousGunClass = Character.HolsterComponent.EquippedGun.GetClass();

			Character.HolsterComponent.GrantGun(GunToGrant, true, FEquipData(EEquipSpeed::Fast, true));
		}
		else if (GrantArmor)
		{
			//GetAngelCharacter(0).GrantArmor(ArmorToGrant);
		}
		else if (GrantAbility)
		{
			AbilityHandle = GetAngelCharacter(0).AbilitySystem.GiveAbility(AbilityClass, 1, -1, nullptr);
		}

		ShopWidget.PurchasedEvent.Broadcast(PurchaseInfo);
		SetIsOwned(true);

		BP_Purchase(PurchaseInfo);
	}

	FGameplayAbilitySpecHandle AbilityHandle;

	UFUNCTION(BlueprintEvent, DisplayName = "Purchased Item")
	void BP_Purchase(FPurchaseData PurchasedItemData)
	{}

	TSubclassOf<AGunBase> PreviousGunClass;

	void Sell()
	{
		AAngelPlayerState PlayerState = GetAngelPlayerState(0);
		
		if (!IsOwned)
		{
			PrintWarning("Cannot sell item you don't own!", 2);
			return;
		}
		else
		{
			if (!PlayerState.RefundSpend(ShopCategory)) return;

		}

		Print(f"Sold {ItemName}");
		CostText.SetText(Format(ItemCost));

		if (IsValid(PreviousGunClass))
		{
			auto Character = GetAngelCharacter(0);
			Character.HolsterComponent.GrantGun(PreviousGunClass);
		}
		else if (GrantArmor)
		{
			//GetAngelCharacter(0).GrantArmor(EArmorType::None, 0);
		}
		else if (GrantAbility)
		{
			GetAngelCharacter(0).AbilitySystem.ClearAbility(AbilityHandle);
		}

		BP_Sold(FSellData(ShopCategory, ItemCost, GunToGrant, ArmorToGrant, AbilityClass));
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Sold Item")
	void BP_Sold(FSellData SoldItemData)
	{}
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