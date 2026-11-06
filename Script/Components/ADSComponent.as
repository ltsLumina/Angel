UCLASS(Abstract)
class UADSComponent : UActorComponent
{
	UPROPERTY(Category = "ADS", VisibleAnywhere, BlueprintReadOnly)
	bool IsADS;

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void StartADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = false;
	}

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void CancelledADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = false;
	}

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void TriggeredADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = true;
	}

	UFUNCTION(NotBlueprintCallable, Category = "ADS")
	void EndADS(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		IsADS = false;
	}
};
