// base class for all gameplay abilities in the Angel project
UCLASS(Abstract)
class UAngelAbility : UGameplayAbility
{
	UPROPERTY(Category = "Ability | Charges", EditDefaultsOnly, Meta = (UIMin = "1", UIMax = "3"))
	int MaxCharges = 2;

    UPROPERTY(Category = "Ability | Duration", EditDefaultsOnly, Meta = (UIMin = "-1.0", UIMax = "10.0"))
    float Duration = 5.0f;

    UPROPERTY(Category = "Ability | Cooldown", EditDefaultsOnly, Meta = (UIMin = "0.0", UIMax = "60.0"))
    float Cooldown = 10.0f;

    UPROPERTY()
    UTexture2D Icon;
};