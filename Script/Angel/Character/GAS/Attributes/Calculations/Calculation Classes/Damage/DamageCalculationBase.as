/**
 * Base class for damage calculation. Provides useful helper functions for damage calculation and boilerplate.
 */
UCLASS()
class UGEXC_DamageCalculationBase : UGameplayEffectExecutionCalculation
{
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UHealthAttributes, UHealthAttributes::HealthName, EGameplayEffectAttributeCaptureSource::Target, true));
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UHealthAttributes, UHealthAttributes::ShieldName, EGameplayEffectAttributeCaptureSource::Target, true));
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UGenericGunAttributes, UGenericGunAttributes::DamageName, EGameplayEffectAttributeCaptureSource::Source, true));
	default RelevantAttributesToCapture.Add(UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UGenericGunAttributes, UGenericGunAttributes::PrecisionName, EGameplayEffectAttributeCaptureSource::Source, true));

	UFUNCTION(BlueprintOverride)
	void Execute(FGameplayEffectCustomExecutionParameters ExecutionParams,
				 FGameplayEffectCustomExecutionOutput& OutExecutionOutput) const
	{
		// for debugging/logging purposes only.
		UObject WorldContextObject = ExecutionParams.TargetAbilitySystemComponent.World;

		auto SourceASC = Cast<UAngelscriptAbilitySystemComponent>(ExecutionParams.SourceAbilitySystemComponent);
		auto TargetASC = Cast<UAngelscriptAbilitySystemComponent>(ExecutionParams.TargetAbilitySystemComponent);
		if (!IsValid(TargetASC))
		{
			TargetASC = SourceASC;
			check(false); // i want to see when this occurs -alex
			throw("uhh idk why this happened please notify alex");
		}

		// We can't damage something that doesn't have any attributes, let alone some sort of health attribute.
		if (TargetASC.GetSpawnedAttributes().IsEmpty() || TargetASC.Avatar == nullptr || TargetASC.AbilityActorInfo.OwnerActor == nullptr)
		{
			throw("Attempt to apply damage failed! Target is missing attributes, or is improperly setup!");
			return;
		}

		// PvP Check
		if (IsValid(SourceASC) && SourceASC.Avatar.IsA(AScriptPondHero) && IsValid(TargetASC) && TargetASC.Avatar.IsA(AScriptPondHero) && SourceASC != TargetASC)
		{
			auto GM = Cast<AScriptGameModeBase>(TargetASC.World.GameState.AuthorityGameMode);
			if (!IsValid(GM) || (TargetASC.Avatar.IsA(AScriptPondHero) && !GM.EnablePvP))
			{
				PrintFromObject(WorldContextObject, f"PvP is not enabled in this GameMode!", 1.5, FLinearColor::Yellow);
				return;
			}
		}

		if (IsValid(TargetASC) && (TargetASC.HasGameplayTag(GameplayTags::State_DBNO) || TargetASC.HasGameplayTag(GameplayTags::State_Dead)))
		{
			// No need to process anything if you're dead.
			return;
		}

		FGameplayEffectContextHandle Context = ExecutionParams.OwningSpec.Context;
		FGameplayEffectContextHandle ContextRef = ExecutionParams.OwningSpecForPreExecuteMod.Context;
		ContextRef.PrecisionMultiplier = 1.0f;
		if (Context.IsPrecisionHit)
		{
			ContextRef.PrecisionMultiplier = GetCapturedAttributeValue(ExecutionParams, UGenericGunAttributes, UGenericGunAttributes::PrecisionName, EGameplayEffectAttributeCaptureSource::Source);
			if (ContextRef.PrecisionMultiplier <= 0)
			{
				ContextRef.PrecisionMultiplier = 1.0f;
			}
		}

		float32 Damage = GetDamageMagnitude(ExecutionParams);
		ThrowIf(Damage < 0, "GetDamageMagnitude expects an absolute value!");

		float32 Health = GetHealthMagnitude(ExecutionParams);
		float32 Shield = GetShieldMagnitude(ExecutionParams);
		ContextRef.DamageResult = CalculateDamageDistribution(Damage, Health, Shield);
		FDamageResult Result = Context.DamageResult; // cached helper

		bool IsInvulnerable = false;
		bool IsDamageImmune = false;
		bool IsTriggerImmune = false;

		IsInvulnerable = TargetASC.HasGameplayTag(GameplayTags::Buffs_Invulnerable);
		if (IsInvulnerable)
		{
			ContextRef.SetInvulnerabilityType(EInvulnerabilityType::Invulnerable);

			PrintFromObject(WorldContextObject, f"Target is invulnerable! Damage application will NOT occur.", 1.5, FLinearColor::Yellow);
		}

		IsDamageImmune = TargetASC.HasGameplayTag(GameplayTags::Buffs_Damage_Immune);
		if (IsDamageImmune)
		{
			ContextRef.SetInvulnerabilityType(EInvulnerabilityType::DamageImmune);

			PrintFromObject(WorldContextObject, f"Target is immune to damage! Effect will be applied without damage.", 1.5, FLinearColor::Yellow);
		}

		IsTriggerImmune = TargetASC.HasGameplayTag(GameplayTags::Buffs_Enchant_Immune);
		if (IsTriggerImmune)
		{
			ContextRef.SetInvulnerabilityType(EInvulnerabilityType::TriggerImmune); // TODO: Rename to EnchantImmune

			PrintFromObject(WorldContextObject, f"Target is immune to enchantment triggers! Effect will be applied without applying enchants.", 3, FLinearColor::Yellow);
		}

		if (Result.HealthDamage <= 0 && ContextRef.InvulnerabilityType != EInvulnerabilityType::DamageImmune) // zero damage is allowed if we're damage immune (so we can display the damage dealt as 'Immune!')
		{
			throw("Attempt to apply damage failed! Applying zero (0) damage without 'damage immunity' is not allowed!");
			check(false);
			return;
		}

		if (Result.ShieldDamage > 0)
		{
			throw("SHIELD DAMAGE HAS NOT BEEN UPDATED TO ACCOUNT FOR INVULNERABILITY/DAMAGE IMMUNITY.");

			FGameplayAttribute ShieldAttribute = UAngelscriptAttributeSet::GetGameplayAttribute(UHealthAttributes, UHealthAttributes::ShieldName);
			OutExecutionOutput.AddOutputModifier(UAngelscriptGameplayEffectUtils::MakeGameplayModifierEvaluationData(ShieldAttribute, EGameplayModOp::Additive, -Result.ShieldDamage));

			PrintFromObject(WorldContextObject, f"{Result.ShieldDamage=}", 1.5f, FLinearColor::Blue);
		}
		if (Result.HealthDamage > 0 || IsDamageImmune)
		{
			if (IsInvulnerable || IsDamageImmune)
			{
				FGameplayEventData Payload;
				Payload.ContextHandle = Context;
				Payload.Instigator = ExecutionParams.OwningSpec.Context.Instigator;
				Payload.EventMagnitude = -Result.HealthDamage;
				Payload.TargetData = AbilitySystem::AbilityTargetDataFromActor(TargetASC.Avatar);

				// Send on on-hit event to the target if they're not able to take damage so they can still react to being hit.
				ExecutionParams.TargetAbilitySystemComponent.SendGameplayEvent(GameplayTags::Ability_Enchant_Trigger_OnHit, Payload);

				if (IsInvulnerable && Health > 0)
				{
					UAngelscriptAbilitySystemComponent InstigatorASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(Context.Instigator);
					auto PC = Cast<AScriptPondController>(InstigatorASC.PlayerController);

					if (PC != nullptr)
						PC.Client_ShowHitmarker(false);
					return;
				}
			}

			// Apply zero damage if target is damage immune (HealthAttributes::PostGEExecute still fires, but with an EvaluatedData.Magnitude of zero/0)
			float32 AppliedDamage = (IsDamageImmune || IsInvulnerable) ? 0 : (-Result.HealthDamage);
			ContextRef.IsFatalHit = Health - Math::Abs(AppliedDamage) <= 0;

			FGameplayAttribute HealthAttribute = UAngelscriptAttributeSet::GetGameplayAttribute(UHealthAttributes, UHealthAttributes::HealthName);
			OutExecutionOutput.AddOutputModifier(UAngelscriptGameplayEffectUtils::MakeGameplayModifierEvaluationData(HealthAttribute, EGameplayModOp::AddBase, AppliedDamage));

			if (!IsInvulnerable && !IsDamageImmune)
			{
				FString Msg = f"Dealt {AppliedDamage} damage to {TargetASC.Avatar.ActorNameOrLabel}! (Precision: {Context.IsPrecisionHit})";
				// PrintFromObject(WorldContextObject, Msg, 2.f, FLinearColor::Red);
				Log(n"DamageCalculation", Msg + f"\n{Context.IsPrecisionHit=}\n{Context.IsFatalHit=}\n{Context.PrecisionMultiplier=:.2}\n{Context.InvulnerabilityType=:n}\n{Context.AdditionalEnchantTriggers.Num()=}");
			}

			OutExecutionOutput.MarkConditionalGameplayEffectsToTrigger();
		}
	}

	/**
	 * Override this in a calculation class to define custom damage logic and formulas.
	 * Always accounts for precision hits by default.
	 * @return The final computed absolute value of a mathematical expression, or the damage magnitude from the SetByCaller.Damage tag if not overriden.
	 */
	float32 GetDamageMagnitude(FGameplayEffectCustomExecutionParameters ExecutionParams) const
	{
		if (ExecutionParams.OwningSpec.SetByCallerTagMagnitudes.IsEmpty())
		{
			ExecutionParams.OwningSpecForPreExecuteMod.SetByCallerMagnitude(GameplayTags::SetByCaller_Damage, GetWeaponDamageWithPrecision(ExecutionParams));
			Exception::BlueprintAssert(ExecutionParams.SourceAbilitySystemComponent, f"{ExecutionParams.OwningSpec.ToSimpleString()} is missing a SetByCallerTag for Damage.", false);
		}
		
		float32 SetByCallerMagnitude = ExecutionParams.OwningSpec.GetSetByCallerMagnitude(GameplayTags::SetByCaller_Damage, true, -1);
		auto PrecisionMult = ExecutionParams.OwningSpec.Context.PrecisionMultiplier;
		float32 Magnitude = SetByCallerMagnitude * PrecisionMult;
		check(Magnitude > 0);
		return Magnitude;
	}

	/**
	 * Helper: Capture any gameplay attribute from a target.
	 * @param AttributeSet The attribute set class (e.g., UGenericGunAttributes)
	 * @param AttributeName The attribute name (e.g., DamageName)
	 * @param Source Whether to capture from source or target
	 * @return The captured attribute value, or -1 if not found
	 */
	protected float32 GetCapturedAttributeValue(FGameplayEffectCustomExecutionParameters ExecutionParams, UClass AttributeSet, FName AttributeName, EGameplayEffectAttributeCaptureSource Source = EGameplayEffectAttributeCaptureSource::Source) const
	{
		float32 OutValue = -1.f;
		FGameplayEffectAttributeCaptureDefinition AttrDef = UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(AttributeSet, AttributeName, Source, true);
		ExecutionParams.AttemptCalculateCapturedAttributeMagnitude(AttrDef, FGameplayEffectExecutionParameters(), OutValue);
		return OutValue;
	}

	/**
	 * Helper: Get weapon damage with precision multiplier applied.
	 * @return Raw weapon damage * precision multiplier (if precision hit)
	 */
	protected float32 GetWeaponDamageWithPrecision(FGameplayEffectCustomExecutionParameters ExecutionParams) const
	{
		float32 RawDamage = GetCapturedAttributeValue(ExecutionParams, UGenericGunAttributes, UGenericGunAttributes::DamageName, EGameplayEffectAttributeCaptureSource::Source);
		bool IsPrecisionHit = ExecutionParams.OwningSpec.Context.IsPrecisionHit;
		float32 PrecisionMult = ExecutionParams.OwningSpecForPreExecuteMod.Context.PrecisionMultiplier;
		return IsPrecisionHit ? RawDamage * PrecisionMult : RawDamage;
	}

	/**
	 * Helper: Get raw weapon damage without precision applied.
	 */
	protected float32 GetWeaponDamage(FGameplayEffectCustomExecutionParameters ExecutionParams) const
	{
		return GetCapturedAttributeValue(ExecutionParams, UGenericGunAttributes, UGenericGunAttributes::DamageName, EGameplayEffectAttributeCaptureSource::Source);
	}

	/**
	 * Helper: Get precision multiplier from context.
	 * @return Precision multiplier if precision hit, else 1.0
	 */
	protected float32 GetPrecisionMultiplier(FGameplayEffectCustomExecutionParameters ExecutionParams) const
	{
		return ExecutionParams.OwningSpecForPreExecuteMod.Context.PrecisionMultiplier;
	}

	/**
	 * Helper: Check if this hit was a precision hit.
	 */
	protected bool IsPrecisionHit(FGameplayEffectCustomExecutionParameters ExecutionParams) const
	{
		return ExecutionParams.OwningSpec.Context.IsPrecisionHit;
	}

	/**
	 * Helper: Apply a scalar multiplier to base damage.
	 */
	protected float32 ApplyDamageMultiplier(float32 BaseDamage, float32 Multiplier) const
	{
		return BaseDamage * Multiplier;
	}

	/**
	 * Helper: Apply an additive bonus expressed as a fraction.
	 * Example: BonusFraction = 0.25 => +25% damage.
	 */
	protected float32 ApplyDamageBonus(float32 BaseDamage, float32 BonusFraction) const
	{
		return ApplyDamageMultiplier(BaseDamage, 1.0f + BonusFraction);
	}

	/**
	 * Helper: Get current ammo value from source.
	 */
	protected float32 GetAmmo(FGameplayEffectCustomExecutionParameters ExecutionParams) const
	{
		return GetCapturedAttributeValue(ExecutionParams, UGenericGunAttributes, UGenericGunAttributes::AmmoName, EGameplayEffectAttributeCaptureSource::Source);
	}

	float32 GetHealthMagnitude(FGameplayEffectCustomExecutionParameters ExecutionParams,
							   EGameplayEffectAttributeCaptureSource Source = EGameplayEffectAttributeCaptureSource::Target,
							   FGameplayEffectExecutionParameters Params = FGameplayEffectExecutionParameters()) const
	{
		float32 CurrentHealth = 0.f;

		FGameplayEffectAttributeCaptureDefinition HealthAttribute;
		HealthAttribute = UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UHealthAttributes, UHealthAttributes::HealthName, Source, true);

		ExecutionParams.AttemptCalculateCapturedAttributeMagnitude(HealthAttribute, Params, CurrentHealth);
		return CurrentHealth;
	}

	float32 GetShieldMagnitude(FGameplayEffectCustomExecutionParameters ExecutionParams, EGameplayEffectAttributeCaptureSource Source = EGameplayEffectAttributeCaptureSource::Target, FGameplayEffectExecutionParameters Params = FGameplayEffectExecutionParameters()) const
	{
		float32 CurrentShield = 0.f;

		FGameplayEffectAttributeCaptureDefinition ShieldAttribute;
		ShieldAttribute = UAngelscriptGameplayEffectUtils::CaptureGameplayAttribute(UHealthAttributes, UHealthAttributes::ShieldName, Source, true);

		ExecutionParams.AttemptCalculateCapturedAttributeMagnitude(ShieldAttribute, Params, CurrentShield);
		return CurrentShield;
	}

	/**
	 * Calculate the distribution of damage across shield and health.
	 * @note Must be called in order to deal damage to shield!! Failure to call this will result in damage being dealt directly to the specified attribute.
	 */
	FDamageResult CalculateDamageDistribution(float RawDamage, float CurrentHealth, float CurrentShield) const
	{
		FDamageResult Result;

		float HealthDamage;
		float ShieldDamage;

		HealthUtils::CalculateShieldSplit(RawDamage, CurrentHealth, CurrentShield, HealthDamage, ShieldDamage);

		Result.HealthDamage = HealthDamage;
		Result.ShieldDamage = ShieldDamage;
		return Result;
	}
}