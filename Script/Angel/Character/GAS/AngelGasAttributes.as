namespace UAngelGASAttributes
{
    const FName HealthName = n"Health";
    const FName ArmorName = n"Armor";
}

class UAngelGASAttributes : UAngelscriptAttributeSet
{
    UPROPERTY(BlueprintReadOnly, Category = "Pawn Attributes")
    FAngelscriptGameplayAttributeData Health;

    UPROPERTY(BlueprintReadOnly, Category = "Pawn Attributes")
    FAngelscriptGameplayAttributeData Armor;

    UAngelGASAttributes()
    {
        Health.Initialize(100.0f);
        Armor.Initialize(0.0f);
    }

    
}