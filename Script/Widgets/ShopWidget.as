event void FPurchasedEvent(TSubclassOf<AGunBase> InGunClass, int InCost);

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