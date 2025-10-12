UCLASS(Abstract)
class UShopWidget : UUserWidget
{
    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        // Make sure the widget can receive keyboard input so we can close it with the B key.
        // Input mode is set to UI Only in the player controller when opening the shop,
        // which means the widget must be focusable to receive key events.
        bIsFocusable = true;
        SetKeyboardFocus();
    }

    UFUNCTION(BlueprintOverride)
    FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
    {
        if (InKeyEvent.GetKey() == EKeys::B)
        {
            auto Controller = GetAngelController(0);
            if (IsValid(Controller))
            {
                Controller.ToggleShop(EKeys::B);
                return FEventReply::Handled();
            }
        }
        return FEventReply::Unhandled();
    }
}