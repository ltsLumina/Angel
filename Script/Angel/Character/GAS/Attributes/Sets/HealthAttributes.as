namespace UHealthAttributes
{
	const FName HealthName = n"Health";
	const FName MaxHealthName = n"MaxHealth";
	const FName ShieldName = n"Shield";
	const FName MaxShieldName = n"MaxShield";
	const FName DamageMultiplierName = n"DamageMultiplier";
}

UCLASS(Abstract)
class UHealthAttributes : UAngelscriptAttributeSet
{
	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Health, Category = "Health Attributes")
	FAngelscriptGameplayAttributeData Health;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxHealth, Category = "Health Attributes")
	FAngelscriptGameplayAttributeData MaxHealth;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Shield, Category = "Health Attributes")
	FAngelscriptGameplayAttributeData Shield;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxShield, Category = "Health Attributes")
	FAngelscriptGameplayAttributeData MaxShield;

	// - Damage Resistances -
	// Scale from 0-1.

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_GenericDamageResistance, Category = "Health Attributes")
	FAngelscriptGameplayAttributeData DamageResistance;

	UHealthAttributes()
	{
		Health.Initialize(100.0f);
		MaxHealth.Initialize(100.0f);
		Shield.Initialize(0.f);
		MaxShield.Initialize(0.f);

		DamageResistance.Initialize(0.f);
	}

	// #region On_Rep
	UFUNCTION(NotBlueprintCallable)
	void OnRep_Health(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_MaxHealth(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_Shield(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_MaxShield(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_DamageMultiplier(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_GenericDamageResistance(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_MeleeDamageResistance(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_SniperDamageResistance(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRep_ConcussiveDamageResistance(FAngelscriptGameplayAttributeData& OldAttributeData)
	{
		OnRep_Attribute(OldAttributeData);
	}
	// #endregion

	// ORDER OF EXECUTION AND RESPONSIBILITY
	// 1. | PRE ATTRIBUTE CHANGE: Perform clamping for ASC to use.
	// 2. | POST GAMEPLAY EFFECT EXECUTE: Update value to new clamped non-zero value, perform post-execute effects such as target death.
	// 3. | POST ATTRIBUTE CHANGE: Broadcast attribute update to listeners.

	// 1.b | PRE/POST ATTRIBUTE BASE CHANGE: Handle clamping when the BASE value itself changes.
	UFUNCTION(BlueprintOverride)
	void PreAttributeBaseChange(FGameplayAttribute Attribute, float32& NewValue) const
	{
		if (Attribute.AttributeName == UCharacterAttributes::HealthName)
		{
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, MaxHealth.CurrentValue);
		}
		else if (Attribute.AttributeName == UCharacterAttributes::ShieldName)
		{
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, MaxShield.CurrentValue);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PostAttributeBaseChange(FGameplayAttribute Attribute, float OldValue, float NewValue) const
	{
		if (Attribute.AttributeName == UCharacterAttributes::HealthName)
		{
			OwningAbilitySystemComponent.RemoveLooseGameplayTag(GameplayTags::State_Health_Healthy, 1, EGameplayTagReplicationState::TagOnly);
			OwningAbilitySystemComponent.RemoveLooseGameplayTag(GameplayTags::State_Health_Critical, 1, EGameplayTagReplicationState::TagOnly);

			if (NewValue >= MaxHealth.CurrentValue)
			{
				OwningAbilitySystemComponent.AddLooseGameplayTag(GameplayTags::State_Health_Healthy, 1, EGameplayTagReplicationState::TagOnly);
			}
			else if (NewValue < (MaxHealth.CurrentValue * 0.2f))
			{
				OwningAbilitySystemComponent.AddLooseGameplayTag(GameplayTags::State_Health_Critical, 1, EGameplayTagReplicationState::TagOnly);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreAttributeChange(FGameplayAttribute Attribute, float32& NewValue)
	{
		if (Attribute.AttributeName == UCharacterAttributes::HealthName)
		{
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, MaxHealth.CurrentValue);
		}
		else if (Attribute.AttributeName == UCharacterAttributes::ShieldName)
		{
			NewValue = ClampAndLog(Attribute, NewValue, 0.0f, MaxShield.CurrentValue);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PostAttributeChange(FGameplayAttribute Attribute, float OldValue, float NewValue)
	{
		if (Attribute.AttributeName == UCharacterAttributes::HealthName)
		{
			Health.SetBaseValue(Math::Clamp(NewValue, 0, MaxHealth.CurrentValue));

			OwningAbilitySystemComponent.RemoveLooseGameplayTag(GameplayTags::State_Health_Healthy, 1, EGameplayTagReplicationState::TagOnly);
			OwningAbilitySystemComponent.RemoveLooseGameplayTag(GameplayTags::State_Health_Critical, 1, EGameplayTagReplicationState::TagOnly);

			if (NewValue >= MaxHealth.CurrentValue)
			{
				OwningAbilitySystemComponent.AddLooseGameplayTag(GameplayTags::State_Health_Healthy, 1, EGameplayTagReplicationState::TagOnly);
			}
			else if (NewValue < (MaxHealth.CurrentValue * 0.2f))
			{
				OwningAbilitySystemComponent.AddLooseGameplayTag(GameplayTags::State_Health_Critical, 1, EGameplayTagReplicationState::TagOnly);
			}
		}
		else if (Attribute.AttributeName == UCharacterAttributes::ShieldName)
		{
			Shield.SetBaseValue(Math::Clamp(NewValue, 0.0f, MaxShield.CurrentValue));
		}
	}

	/**
	 * CALLED ON THE SERVER ONLY!!
	 * ALSO ONLY CALLED ON BASE VALUE CHANGES, NOT CURRENT VALUE!
	 */
	UFUNCTION(BlueprintOverride)
	void PostGameplayEffectExecute(FGameplayEffectSpec EffectSpec,
								   FGameplayModifierEvaluatedData& EvaluatedData,
								   UAngelscriptAbilitySystemComponent AbilitySystemComponent)
	{
		if (EffectSpec.Period > 1.0f || EffectSpec.Period == 0.0f)
		{
			Log(n"PostApply", f"GameplayEffect: {EffectSpec.ToSimpleString()}");
		}

		bool IsPlayerInstigated = false;
		bool IsPlayerReceived = false;

		if (EvaluatedData.Attribute.AttributeName == UCharacterAttributes::HealthName)
		{
			UAngelscriptAbilitySystemComponent InstigatorASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(EffectSpec.Context.Instigator);

			ThrowIf(!IsValid(EffectSpec.Context.Instigator), f"An effect without an instigator is not allowed!");

			// if the player instigated damage
			IsPlayerInstigated = EffectSpec.Context.Instigator.IsA(AAngelAgent);
			// if the player took damage
			IsPlayerReceived = !InstigatorASC.Avatar.IsA(AAngelAgent);

			bool WasHealed = false;
			bool TookDamage = false;

			float AppliedMagnitude = EvaluatedData.Magnitude;
			float BaseDamage = Math::Abs(AppliedMagnitude);
			float FinalDamage = -1;

			// The applied magnitude will always be negative in the application of damage.
			if (AppliedMagnitude < 0)
			{
				float ResistanceMagnitude = DamageResistance.CurrentValue;
				
				// The amount of damage that was reduced by the resistance.
				float Reduction = AppliedMagnitude * Math::Max(ResistanceMagnitude, 0);
				FinalDamage = BaseDamage - Math::Abs(Reduction);
			}

			float OldHealth = Health.CurrentValue - EvaluatedData.Magnitude;

			bool IsDamageImmune = EffectSpec.Context.InvulnerabilityType == EInvulnerabilityType::DamageImmune;
			if (!IsDamageImmune)
			{
				switch (int(Math::Sign(AppliedMagnitude)))
				{
					case 1: // positive (receiving healing)
						WasHealed = Health.CurrentValue > OldHealth;
						break;

					case -1: // negative (receiving damage)
						TookDamage = Health.CurrentValue < OldHealth;
						break;

					case 0:
						break;

					default:
						// If a hero deals self damage, and eventually reaches 0 health, then this will run.
						if (AbilitySystemComponent.Avatar.IsA(AAngelAgent))
						{
							OwningAgent.Death();
							return;
						}

						throw("Math::Sign in this instance should never return 0 (EvaluatedData.Magnitude was 0)");
						return;
				}
			}

			if (Health.CurrentValue == OldHealth && !IsDamageImmune)
			{
				// health didnt change.
				Log(n"PostApply", f"GameplayEffect: {EffectSpec.ToSimpleString()} - VALUE HAD NO CHANGE.");
				return;
			}
			else if (WasHealed)
			{
			}
			// we want to continue the on-hit logic if we're damage immune,
			// but overwriting `TookDamage = true` would potentially lead to side effects like enchantment triggers,
			// hence why we do this odd check.
			else if (TookDamage || (IsDamageImmune))
			{
				// DamageDealt according to Calculation Class.
				float DamageDealt = FinalDamage; // is absolute
				float DamageCapped = Math::Clamp(DamageDealt, 0, UGenericGunAttributes::DAMAGE_CAP);

				bool WasPrecision = EffectSpec.Context.IsPrecisionHit;

				FHitResult Hit;
				if (AbilitySystem::EffectContextHasHitResult(EffectSpec.Context))
				{
					EffectSpec.Context.GetHitResult(Hit);
				}
				else
				{
					Hit.SetLocation(EffectSpec.Context.Origin);
				}

				if (EffectSpec.Context.Instigator == nullptr)
				{
					check(false); // shouldnt get here unless the actor is destroyed before the effect finishes properly
					return;
				}

				FGameplayEventData Payload;
				Payload.ContextHandle = EffectSpec.Context;
				Payload.Instigator = EffectSpec.Context.Instigator;
				Payload.Target = Hit.Actor;
				Payload.EventMagnitude = AppliedMagnitude;
				Payload.TargetData = AbilitySystem::AbilityTargetDataFromHitResult(Hit);

				// The instigator of the GE.
				AActor InstigatorAvatar = InstigatorASC.Avatar == nullptr ? InstigatorASC.Owner : InstigatorASC.Avatar;

				// The avatar of the ASC who received this GameplayEffect.
				AActor ReceiverAvatar = AbilitySystemComponent.Avatar == nullptr ? AbilitySystemComponent.Owner : AbilitySystemComponent.Avatar;

				// Player-instigated VFX/cosmetics
				if (InstigatorAvatar.IsA(AAngelAgent))
				{
					// Hitmarker

					if (InstigatorAvatar.IsA(AAngelAgent) && InstigatorASC != AbilitySystemComponent) // if the player instigated, and if we're not the player
					{
						auto PC = Cast<AAngelPlayerController>(InstigatorASC.PlayerController);
						if (PC != nullptr)
						{
							// TODO:
							//PC.Client_ShowHitmarker(WasKill);
							//PC.Client_PlayHitSFX(WasPrecision, WasKill);
						}
					}
				}
			}

			// Means the entity cannot die.
			bool HasUndyingBuff = OwningAbilitySystemComponent.HasGameplayTag(GameplayTags::Buffs_Undying);
			float MinHealth = HasUndyingBuff ? 1 : 0;

			Health.SetCurrentValue(Math::Clamp(Health.CurrentValue, MinHealth, MaxHealth.CurrentValue));
		}
		else if (EvaluatedData.Attribute.AttributeName == UCharacterAttributes::ShieldName)
		{
			float DamageDealt = EvaluatedData.Magnitude;
			float OldShieldValue = Shield.CurrentValue - EvaluatedData.Magnitude;
			float NewShieldValue = OldShieldValue + DamageDealt;

			Shield.SetCurrentValue(Math::Clamp(NewShieldValue, 0, MaxShield.CurrentValue));
			bool TookDamage = Shield.CurrentValue < OldShieldValue;

			if (TookDamage && Shield.CurrentValue <= 0)
			{
				FHitResult Hit;
				EffectSpec.Context.GetHitResult(Hit);

				auto InstigatorASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(EffectSpec.Context.Instigator);
				FGameplayEventData Payload;
				Payload.Instigator = EffectSpec.Context.Instigator;
				Payload.Target = Hit.Actor;
				Payload.EventMagnitude = DamageDealt;
				Payload.TargetData = AbilitySystem::AbilityTargetDataFromHitResult(Hit);

				// NOTE: This has not been tested!
				//InstigatorASC.SendGameplayEvent(GameplayTags::Ability_Enchant_Trigger_OnShieldBreak, Payload);

				PrintWarning("OnShieldBreak trigger has not been tested! - If you are seeing this, YOU are testing it!", 30);
			}
		}
	}

	protected AAngelAgent GetOwningAgent() property
	{
		auto PS = Cast<APlayerState>(OwningActor);
		return Cast<AAngelAgent>(PS.Pawn);
	}

	protected AAngelPlayerController GetOwningController() property
	{
		auto PS = Cast<APlayerState>(OwningActor);
		return Cast<AAngelPlayerController>(PS.PlayerController);
	}
}