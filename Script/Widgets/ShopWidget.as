UCLASS(Abstract)
class UShopWidget : UUserWidget
{
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