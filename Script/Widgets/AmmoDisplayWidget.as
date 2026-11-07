class UAmmoDisplayWidget : UUserWidget
{
    UPROPERTY()
    UGunComponent GunComponent;

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        GunComponent = UGunComponent::Get(OwningPlayer);
    }
}