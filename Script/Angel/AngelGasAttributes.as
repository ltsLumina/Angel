namespace UAngelGASAttributes
{
    const FName HealthName = n"Health";
    const FName Mana = n"Mana";
}

class UAngelGASAttributes : UAngelscriptAttributeSet
{
    UPROPERTY(BlueprintReadOnly, Category = "Pawn Attributes")
    FAngelscriptGameplayAttributeData Health;

    UPROPERTY(BlueprintReadOnly, Category = "Pawn Attributes")
    FAngelscriptGameplayAttributeData Mana;

    UAngelGASAttributes()
    {
        Health.Initialize(100.0f);
        Mana.Initialize(100.0f);
    }

    
}