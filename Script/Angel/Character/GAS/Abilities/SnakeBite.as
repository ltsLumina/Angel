UCLASS(Abstract)
class USnakeBite : UAngelAbility
{
    UPROPERTY(Category = "Ability | Snake Bite", Meta = (UIMin = "1.0", UIMax = "10.0", BlueprintGetter = "GetRadius"))
    float Radius = 5.0f;

    UFUNCTION(BlueprintPure)
    float GetRadius()
    {
        return Radius * 100; // convert to cm
    }
};