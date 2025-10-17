event void FPurchasedEvent(FPurchaseData PurchaseInfo);

UCLASS(Abstract)
class UShopWidget : UUserWidget
{
	UPROPERTY(Category = "UI | Events", VisibleAnywhere)
	FPurchasedEvent PurchasedEvent;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.GetKey() == EKeys::B)
		{
			auto Controller = GetAngelController(0);
			if (IsValid(Controller))
			{
				Controller.ToggleShop();
				return FEventReply::Handled();
			}
		}
		return FEventReply::Unhandled();
	}
}

struct FPurchaseData
{
	EShopCategory Category;
	TSubclassOf<AGunBase> GunClass;
	EArmorType ArmorType;
	TSubclassOf<UAngelAbility> AbilityClass;
	int Cost;

	FPurchaseData(EShopCategory InCategory, int InCost, TSubclassOf<AGunBase> InGunClass = nullptr, EArmorType InArmorType = EArmorType::None, TSubclassOf<UAngelAbility> InAbilityClass = nullptr)
	{
		Category = InCategory;
		Cost = InCost;
		GunClass = InGunClass;
		ArmorType = InArmorType;
		AbilityClass = InAbilityClass;
	}
};

struct FSellData
{
    EShopCategory Category;
    TSubclassOf<AGunBase> GunClass;
    EArmorType ArmorType;
    TSubclassOf<UAngelAbility> AbilityClass;
    int RefundAmount;

    FSellData(EShopCategory InCategory, int InRefundAmount, TSubclassOf<AGunBase> InGunClass = nullptr, EArmorType InArmorType = EArmorType::None, TSubclassOf<UAngelAbility> InAbilityClass = nullptr)
    {
        Category = InCategory;
        RefundAmount = InRefundAmount;
        GunClass = InGunClass;
        ArmorType = InArmorType;
        AbilityClass = InAbilityClass;
    }
}