UCLASS(Abstract)
class UShopUserWidget : UUserWidget
{
	UPROPERTY(Category = "UI", BindWidget)
	UTextBlock Credits;

	UPROPERTY(Category = "UI", BindWidget)
	UTextBlock MinNextRoundText;

	UPROPERTY(Category = "UI", BindWidget)
	UTextBlock MinNextRoundValue;

	UPROPERTY(Category = "UI", BindWidget)
	UImage Avatar;

	UPROPERTY(Category = "UI", BindWidget)
	UButton LetsBuy;

	UPROPERTY(Category = "UI", BindWidget)
	UButton ExtraCreds;

	UPROPERTY(Category = "UI", BindWidget)
	UButton LetsSave;

	UPROPERTY(Category = "UI", BindWidget)
	UImage ArmorImage;

	UPROPERTY(Category = "UI", BindWidget)
	UImage SidearmImage;

	UPROPERTY(Category = "UI", BindWidget)
	UImage PrimaryImage;

	UPROPERTY(Category = "User | Armor")
	EArmorType Armor;

	UPROPERTY(Category = "User | Armor")
	UTexture2D LightArmorIcon;

	UPROPERTY(Category = "User | Armor")
	UTexture2D HeavyArmorIcon;

	UPROPERTY(Category = "User | Weapons")
	TSubclassOf<AGunBase> Sidearm;

	UPROPERTY(Category = "User | Weapons")
	TSubclassOf<AGunBase> Primary;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		if (IsValid(GetAngelCharacter(0).HolsterComponent))
		{
			Sidearm = GetAngelCharacter(0).HolsterComponent.Sidearm.GetClass();
			Primary = GetAngelCharacter(0).HolsterComponent.Primary.GetClass();
		}

		ArmorImage.SetBrushFromTexture(GetArmorIcon(Armor));
		if (!IsValid(GetArmorIcon(Armor)))
			ArmorImage.Opacity = 0;
		else
			ArmorImage.Opacity = 1;

		SidearmImage.SetBrushFromTexture(GetWeaponIcon(Sidearm));
		if (!IsValid(Sidearm))
			SidearmImage.Opacity = 0;
		else
			SidearmImage.Opacity = 1;

		PrimaryImage.SetBrushFromTexture(GetWeaponIcon(Primary));
		if (!IsValid(Primary))
			PrimaryImage.Opacity = 0;
		else
			PrimaryImage.Opacity = 1;

		BP_PreConstruct(IsDesignTime);
	}

	UFUNCTION(BlueprintEvent)
	void BP_PreConstruct(bool IsDesignTime)
	{}

	UFUNCTION(BlueprintEvent)
	void BP_Construct()
	{}

	UFUNCTION(BlueprintPure)
	UTexture2D GetArmorIcon(EArmorType ArmorType)
	{
		switch (ArmorType)
		{
			case EArmorType::Light:
				return LightArmorIcon;
			case EArmorType::Heavy:
				return HeavyArmorIcon;
			default:
				return nullptr;
		}
	}
}

UFUNCTION(BlueprintPure)
UTexture2D GetWeaponIcon(TSubclassOf<AGunBase> GunClass)
{
	if (!IsValid(GunClass))
		return nullptr;
	return GunClass.DefaultObject.Icon;
}