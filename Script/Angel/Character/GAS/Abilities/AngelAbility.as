// base class for all gameplay abilities in the Angel project
UCLASS(Abstract)
class UAngelAbility : UGameplayAbility
{
    /**
     * The agent that owns this ability
     */
    UPROPERTY(Category = "Ability | Info", ToolTip = "The agent that owns this ability")
    FName Agent;

	UPROPERTY(Category = "Ability | Info")
	EAbility AbilityType;

	UPROPERTY(Category = "Ability | Info")
	UTexture2D Icon;

    UPROPERTY(Category = "Ability | Info")
    int Credits = 150;

	UPROPERTY(Category = "Ability | Uses", Meta = (UIMin = "1", UIMax = "3"))
	int Uses = 2;
	default Uses = AbilityType == EAbility::Ultimate_X ? 1 : 2;

    UPROPERTY(Category = "Ability | Uses", Meta = (UIMin = "-1", UIMax = "60", EditCondition = AbilityType == EAbility::Signature_E, EditConditionHides))
	float RestockTime = 40;

	UPROPERTY(Category = "Ability | Equip", Meta = (UIMin = "0", UIMax = "1"))
	float EquipTime = 0.8;

    UPROPERTY(Category = "Ability | Equip", Meta = (UIMin = "0", UIMax = "1"))
	float UnequipTime = 0.7;

	UPROPERTY(Category = "Ability | Equip")
	EEquipSpeed WeaponReequipSpeed = EEquipSpeed::Fast;

	UPROPERTY(Category = "Ability | Duration", Meta = (UIMin = "-1.0", UIMax = "10.0"))
	float Duration = 5.0f;

    UPROPERTY(Category = "Ability | Audio", ToolTip = "Sound to play when the ability is cast (used)")
    USoundBase ShotSound;

    UPROPERTY(Category = "Ability | Audio", ToolTip = "Sound to play when the ability is equipped")
    USoundBase EquipSound;
};