UCLASS(Abstract)
class UShopWidget : UUserWidget
{
    UPROPERTY(Category = "Config", EditDefaultsOnly, BlueprintReadOnly)
    TSubclassOf<UUserWidget> ShopItemWidgetClass;

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        PopulateShop();
    }

    UFUNCTION()
    void PopulateShop()
    {
        
    }
}