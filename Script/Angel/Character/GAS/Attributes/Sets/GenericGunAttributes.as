namespace UGenericGunAttributes
{
	const FName AmmoName = n"Ammo";
	const FName MaxAmmoName = n"MaxAmmo";
	const FName ZoomName = n"Zoom";
	const FName FireRateName = n"FireRate";
	const FName ReloadSpeedName = n"ReloadSpeed";
	const FName AimAssistName = n"AimAssist";
	const FName RecoilName = n"Recoil";
	const FName PrecisionName = n"Precision";
	const FName DamageName = n"Damage";

	const float32 AMMO_CAP = 999;
	const float32 ZOOM_CAP = 12;	   // 12x
	const float32 FIRE_RATE_CAP = 50;  // rounds/s
	const float32 RELOAD_CAP = 3;	   // 3x
	const float32 RELOAD_FLOOR = 0.5f;	   // half
	const float32 AIM_ASSIST_CAP = 3;  // 3 degrees
	const float32 RECOIL_CAP = 100;	   // fully vertical
	const float32 PRECISION_CAP = 10;  // 10x
	const float32 DAMAGE_CAP = 999999; // 999,999
}

class UGenericGunAttributes : UAngelscriptAttributeSet
{
	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Ammo, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData Ammo;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxAmmo, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData MaxAmmo;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Zoom, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData Zoom;

	/**
	 * Fire-rate in rounds/sec
	 */
	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_FireRate, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData FireRate;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_ReloadSpeed, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData ReloadSpeed;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_AimAssist, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData AimAssist;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Recoil, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData Recoil;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Precision, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData Precision;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Damage, Category = "Gun Attributes")
	FAngelscriptGameplayAttributeData Damage;

	UGenericGunAttributes()
	{
		Ammo.Initialize(30.0f);
		MaxAmmo.Initialize(30.0f);
		Zoom.Initialize(1.25f);
		FireRate.Initialize(30.0f);
		ReloadSpeed.Initialize(1.0f);
		AimAssist.Initialize(1.5f);
		Recoil.Initialize(100.0f);
		Precision.Initialize(1.5f);
		Damage.Initialize(10.0f);
	}

	/* #region OnRep */
	UFUNCTION(NotBlueprintCallable)
	void OnRep_Ammo(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);

		if (IsValid(OwningController))
			OwningController.UpdateAmmoTags(OwningAbilitySystemComponent, Ammo.CurrentValue, MaxAmmo.CurrentValue);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_MaxAmmo(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_Zoom(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_FireRate(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_ReloadSpeed(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_AimAssist(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_Recoil(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_Precision(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_Damage(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}
	/* #endregion */

	// ORDER OF EXECUTION AND RESPONSIBILITY
	// 1. | PRE ATTRIBUTE CHANGE: Perform clamping for ASC to use.
	// 2. | POST GAMEPLAY EFFECT EXECUTE: Update value to new clamped non-zero value, perform post-execute effects such as target death.
	// 3. | POST ATTRIBUTE CHANGE: Broadcast attribute update to listeners.

	//~
	UFUNCTION(BlueprintOverride)
	void PreAttributeChange(FGameplayAttribute Attribute, float32& NewValue)
	{
		if (Attribute.AttributeName == UGenericGunAttributes::AmmoName)
			NewValue = ClampAndLog(Attribute, Math::TruncToInt(NewValue), 0.0f, MaxAmmo.CurrentValue);
		if (Attribute.AttributeName == UGenericGunAttributes::MaxAmmoName)
		{
			NewValue = ClampAndLog(Attribute, Math::TruncToInt(NewValue), 0.0f, UGenericGunAttributes::AMMO_CAP);
			OwningAbilitySystemComponent.RemoveLooseGameplayTag(GameplayTags::State_Ammo_Full);
		}
		if (Attribute.AttributeName == UGenericGunAttributes::ZoomName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::ZOOM_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::FireRateName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::FIRE_RATE_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::ReloadSpeedName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::RELOAD_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::AimAssistName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, UGenericGunAttributes::AIM_ASSIST_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::RecoilName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::RECOIL_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::PrecisionName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::PRECISION_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::DamageName)
			NewValue = ClampAndLog(Attribute, NewValue, 1.0f, UGenericGunAttributes::DAMAGE_CAP); // damage cannot be reduced below 1, i.e., you will always deal 'some' damage.
	}

	UFUNCTION(BlueprintOverride)
	void PreAttributeBaseChange(FGameplayAttribute Attribute, float32& NewValue) const
	{
		if (Attribute.AttributeName == UGenericGunAttributes::AmmoName)
			NewValue = ClampAndLog(Attribute, Math::TruncToInt(NewValue), 0.0f, MaxAmmo.CurrentValue);
		if (Attribute.AttributeName == UGenericGunAttributes::MaxAmmoName)
		{
			NewValue = ClampAndLog(Attribute, Math::TruncToInt(NewValue), 0.0f, UGenericGunAttributes::AMMO_CAP);
			OwningAbilitySystemComponent.RemoveLooseGameplayTag(GameplayTags::State_Ammo_Full);
		}
		if (Attribute.AttributeName == UGenericGunAttributes::ZoomName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::ZOOM_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::FireRateName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::FIRE_RATE_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::ReloadSpeedName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::RELOAD_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::AimAssistName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, UGenericGunAttributes::AIM_ASSIST_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::RecoilName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::RECOIL_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::PrecisionName)
			NewValue = ClampAndLog(Attribute, NewValue, 0.1f, UGenericGunAttributes::PRECISION_CAP);
		if (Attribute.AttributeName == UGenericGunAttributes::DamageName)
			NewValue = ClampAndLog(Attribute, NewValue, 1.0f, UGenericGunAttributes::DAMAGE_CAP);
	}

	UFUNCTION(BlueprintOverride)
	void PostAttributeChange(FGameplayAttribute Attribute, float OldValue, float NewValue)
	{
		if (Attribute.AttributeName == UGenericGunAttributes::AmmoName)
		{
			Ammo.SetCurrentValue(Math::Clamp(Ammo.CurrentValue, 0.0f, MaxAmmo.CurrentValue));
			if (IsValid(OwningController))
				OwningController.UpdateAmmoTags(OwningAbilitySystemComponent, Ammo.CurrentValue, MaxAmmo.CurrentValue);
		}

		if (Attribute.AttributeName == UGenericGunAttributes::MaxAmmoName)
		{
			MaxAmmo.SetCurrentValue(Math::Clamp(MaxAmmo.CurrentValue, 1.0f, UGenericGunAttributes::AMMO_CAP));
		}

		if (Attribute.AttributeName == UGenericGunAttributes::ZoomName)
			Zoom.SetCurrentValue(Math::Clamp(Zoom.CurrentValue, 0.1f, UGenericGunAttributes::ZOOM_CAP));

		if (Attribute.AttributeName == UGenericGunAttributes::FireRateName)
			FireRate.SetCurrentValue(Math::Clamp(FireRate.CurrentValue, 0.1f, UGenericGunAttributes::FIRE_RATE_CAP));

		if (Attribute.AttributeName == UGenericGunAttributes::ReloadSpeedName)
			ReloadSpeed.SetCurrentValue(Math::Clamp(ReloadSpeed.CurrentValue, 0.1f, UGenericGunAttributes::RELOAD_CAP));

		if (Attribute.AttributeName == UGenericGunAttributes::AimAssistName)
			AimAssist.SetCurrentValue(Math::Clamp(AimAssist.CurrentValue, 0.0f, UGenericGunAttributes::AIM_ASSIST_CAP));

		if (Attribute.AttributeName == UGenericGunAttributes::RecoilName)
			Recoil.SetCurrentValue(Math::Clamp(Recoil.CurrentValue, 0.1f, UGenericGunAttributes::RECOIL_CAP));

		if (Attribute.AttributeName == UGenericGunAttributes::PrecisionName)
			Precision.SetCurrentValue(Math::Clamp(Precision.CurrentValue, 0.1f, UGenericGunAttributes::PRECISION_CAP));

		if (Attribute.AttributeName == UGenericGunAttributes::DamageName)
			Damage.SetCurrentValue(Math::Clamp(Damage.CurrentValue, 1.0f, UGenericGunAttributes::DAMAGE_CAP));
	}

	UFUNCTION(BlueprintOverride)
	void PostGameplayEffectExecute(FGameplayEffectSpec EffectSpec,
								   FGameplayModifierEvaluatedData& EvaluatedData,
								   UAngelscriptAbilitySystemComponent AbilitySystemComponent)
	{
		if (EvaluatedData.Attribute.AttributeName == UGenericGunAttributes::AmmoName)
		{
			Ammo.SetCurrentValue(Math::Clamp(Ammo.CurrentValue, 0, MaxAmmo.CurrentValue));

			OwningController.UpdateAmmoTags(AbilitySystemComponent, Ammo.CurrentValue, MaxAmmo.CurrentValue);
		}
	}

	AAngelAgent GetOwningHero() property
	{
		auto PS = Cast<APlayerState>(OwningActor);
		return Cast<AAngelAgent>(PS.Pawn);
	}

	AAngelPlayerController GetOwningController() property
	{
		auto PS = Cast<APlayerState>(OwningActor);
		return Cast<AAngelPlayerController>(PS.PlayerController);
	}
}