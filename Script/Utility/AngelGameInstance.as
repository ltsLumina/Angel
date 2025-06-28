class UAngelGameInstance : UGameInstance
{
    UPROPERTY(Category = "Score")
    float32 PlayerScore = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Init()
	{
        
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{

	}
};