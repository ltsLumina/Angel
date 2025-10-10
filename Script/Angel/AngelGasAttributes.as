namespace UAngelGASAttributes
{
    const FName HealthName = n"Health";
}

class UAngelGASAttributes : UAngelscriptAttributeSet
{
    UPROPERTY(BlueprintReadOnly, Category = "Pawn Attributes")
    FAngelscriptGameplayAttributeData Health;

    UAngelGASAttributes()
    {
        Health.Initialize(100.0f);
    }

    
}