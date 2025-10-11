UCLASS(Abstract)
class UKillfeedEntry : UUserWidget
{
    UPROPERTY(ExposeOnSpawn)
    UTexture2D AttackerIcon;
    
    UPROPERTY(ExposeOnSpawn)
    FString AttackerName;

    UPROPERTY(ExposeOnSpawn)
    UTexture2D WeaponOrAbilityIcon;

    UPROPERTY(ExposeOnSpawn)
    bool WasHeadshot = false;

    UPROPERTY(ExposeOnSpawn)
    FString VictimName;

    UPROPERTY(ExposeOnSpawn)
    UTexture2D VictimIcon;
}