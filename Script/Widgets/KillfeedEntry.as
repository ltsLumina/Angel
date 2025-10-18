UCLASS(Abstract)
class UKillfeedEntry : UUserWidget
{
    UPROPERTY(ExposeOnSpawn)
    UTexture2D KillerIcon;
    
    UPROPERTY(ExposeOnSpawn)
    FString KillerName;

    UPROPERTY(ExposeOnSpawn)
    UTexture2D WeaponIcon;

    UPROPERTY(ExposeOnSpawn)
    UTexture2D AbilityIcon;

    UPROPERTY(ExposeOnSpawn)
    bool WasHeadshot = false;

    UPROPERTY(ExposeOnSpawn)
    FString VictimName;

    UPROPERTY(ExposeOnSpawn)
    UTexture2D VictimIcon;
}