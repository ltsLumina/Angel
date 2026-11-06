UCLASS(Abstract, HideDropdown)
class UGA_HeroAbility_AS : UAngelscriptGameplayAbility
{
	default InstancingPolicy = EGameplayAbilityInstancingPolicy::InstancedPerActor;
	default NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;

	default ActivationBlockedTags.AddTag(GameplayTags::State_Dead);
	default ActivationBlockedTags.AddTag(GameplayTags::Debuffs_Stun);
	default ActivationBlockedTags.AddTag(GameplayTags::State_Weapon_Reloading);
	default ActivationBlockedTags.AddTag(GameplayTags::State_Sprinting);

	UFUNCTION(BlueprintPure)
	AAngelAgent GetOwningHero() const property
	{
		return Cast<AAngelAgent>(AvatarActorFromActorInfo);
	}

	UFUNCTION(BlueprintPure)
	AAngelPlayerController GetOwningController() const property
	{
		return Cast<AAngelPlayerController>(AvatarActorFromActorInfo.AsPawn().Controller);
	}
}

UCLASS(HideDropdown)
class UGA_HeroShootAbility_AS : UGA_HeroAbility_AS
{
	default AbilityTags.AddTag(GameplayTags::State_Weapon_Firing);

	default ActivationBlockedTags.AddTag(GameplayTags::State_Weapon_Reloading);

	/**
	 * Does this ability deal damage?
	 */
	UPROPERTY(Category = "Ability | Spec", BlueprintReadOnly)
	bool bDealsDamage;

	/**
	 * GameplayEffect that performs damage calculation and applies damage.
	 */
	UPROPERTY(Category = "Ability | Spec", EditInline, BlueprintReadOnly, Meta = (EditCondition = "bDealsDamage"))
	TSubclassOf<UGameplayEffect> DamageEffectClass;

	UPROPERTY(Category = "Ability | Spec", BlueprintReadWrite, Meta = (ClampMin = 1))
	float Damage = 50.f;

	/**
	 * FGameplayEffectSpecHandle which is initialized after ability has been committed (only if bDealsDamage == true).
	 * Use this whenever you need to manage the damage spec.
	 */
	UPROPERTY(Category = "Ability | Spec", NotVisible, BlueprintReadOnly, DisplayName = "Damage Spec")
	protected FGameplayEffectSpecHandle DamageSpecHandle;

	UPROPERTY(Category = "Ability | Shake")
	FVector CameraShake = FVector(1.f, 10.f, 0.5f);

	//~

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UGunComponent GunComponent;

	UFUNCTION(BlueprintOverride)
	void ActivateAbility()
	{
		if (!IsValid(GunComponent))
			GunComponent = UGunComponent::Get(AvatarActorFromActorInfo);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void OnEndAbility(bool bWasCancelled)
	{
		if (bWasCancelled)
			return;

		float Amplitude = CameraShake.X;
		float Frequency = CameraShake.Y;
		float Duration = CameraShake.Z;
		// TODO: CameraShake
		//OwningController.Client_PlayCameraShake(Amplitude, Frequency, Duration);
	}

	/**
	 * Gathers all nearby targets, including players, enemies, environment actors, etc.
	 * Checks against EObjectTypeQuery::Enemy and Pawn.
	 * Note: A common misconception is that `IgnoreOwner` ignores the target -- it does not! It ignores whomever instigated the effect.
	 *
	 * @param IgnoreOwner Ignores the owner of the effect (the source ability system). On initial application of an enchant, this will likely be the player.
	 * @param IgnorePlayers Ignores all players (`APondHero`).
	 * @return All potential targets, including players, enemies, environment actors, etc. Use `IgnorePlayers = true` if you dont want to include players in the overlap.
	 */
	UFUNCTION(Category = "Targets", BlueprintPure, Meta = (AdvancedDisplay = "Duration,DebugColour", AutoCreateRefTerm = "IgnoreActors", RequiredParameters = "SpherePos"))
	TArray<AActor> GetNearbyTargets(FVector SpherePos, float Radius = 100.f, bool IgnoreOwner = true, bool IgnorePlayers = true, TArray<AActor>& IgnoreActors = TArray<AActor>(), bool DrawDebug = false, FLinearColor DebugColour = FLinearColor::White, float Duration = 1.f)
	{
		TArray<AActor> OutActors;

		TArray<EObjectTypeQuery> ObjTypes;
		ObjTypes.Add(EObjectTypeQuery::Pawn);

		TArray<AActor> ActorsToIgnore = IgnoreActors;

		if (IgnoreOwner)
			ActorsToIgnore.Add(AvatarActorFromActorInfo);

		System::SphereOverlapActors(SpherePos, Radius, ObjTypes, AActor, ActorsToIgnore, OutActors);

		if (IgnorePlayers)
		{
			for (int i = OutActors.Num() - 1; i >= 0; --i) // reverse for-loop to safely remove entries
			{
				AActor Actor = OutActors[i];
				if (Actor.IsA(AAngelAgent))
				{
					OutActors.Remove(Actor);
				}
			}
		}

#if EDITOR
		if (DrawDebug)
			System::DrawDebugSphere(SpherePos, Radius, 12, DebugColour, Duration, 1);
#endif

		return OutActors;
	}

	UFUNCTION(Category = "Targets", DisplayName = "Get Nearby Targets (From HitResult)", BlueprintPure, Meta = (AdvancedDisplay = "Duration,DebugColour", AutoCreateRefTerm = "IgnoreActors"))
	TArray<AActor> GetNearbyTargetsFromHitResult(FHitResult Hit, float Radius = 100.f, bool IgnoreOwner = true, bool IgnorePlayers = true, bool IgnoreHitActor = false, TArray<AActor>& IgnoreActors = TArray<AActor>(), bool DrawDebug = false, FLinearColor DebugColour = FLinearColor::White, float Duration = 1.f)
	{
		TArray<AActor> OutActors;

		TArray<EObjectTypeQuery> ObjTypes;
		ObjTypes.Add(EObjectTypeQuery::Pawn);

		TArray<AActor> ActorsToIgnore = IgnoreActors;

		if (IgnoreOwner)
			ActorsToIgnore.Add(AvatarActorFromActorInfo);

		if (IgnoreHitActor)
			ActorsToIgnore.Add(Hit.Actor);

		System::SphereOverlapActors(Hit.ImpactPoint, Radius, ObjTypes, AActor, ActorsToIgnore, OutActors);

		if (IgnorePlayers)
		{
			for (int i = OutActors.Num() - 1; i >= 0; --i) // reverse for-loop to safely remove entries
			{
				AActor Actor = OutActors[i];
				if (Actor.IsA(AAngelAgent))
				{
					OutActors.Remove(Actor);
				}
			}
		}

#if EDITOR
		if (DrawDebug)
			System::DrawDebugSphere(Hit.ImpactPoint, Radius, 12, DebugColour, Duration, 1);
#endif

		return OutActors;
	}

	private bool MakeDamageSpec(AActor Actor, EDamageType DamageType, FGameplayEffectSpecHandle&out OutSpec)
	{
		if (!HasAuthority())
			return false;

		DamageSpecHandle = ASC.MakeOutgoingSpec(DamageEffectClass, 1, ASC.MakeEffectContext());

		FGameplayAbilityTargetDataHandle TargetData = AbilitySystem::AbilityTargetDataFromActor(Actor);
		FHitResult Hit = AbilitySystem::GetHitResultFromTargetData(TargetData, 0);

		DamageSpecHandle.Spec.SetByCallerMagnitude(GameplayTags::SetByCaller_Damage, Damage);

		DamageSpecHandle.Spec.Context.DamageType = DamageType;
		DamageSpecHandle.Spec.Context.IsPrecisionHit = FHitResult::IsPrecisionHitFromHitResult(Hit);
		DamageSpecHandle.Spec.Context.AddInstigator(OwningActorFromActorInfo, AvatarActor);
		DamageSpecHandle.Spec.Context.AddHitResult(Hit, true);

		OutSpec = DamageSpecHandle;
		return true;
	}

	private bool MakeDamageSpec(FHitResult HitResult, EDamageType DamageType, FGameplayEffectSpecHandle&out OutSpec)
	{
		return MakeDamageSpec(HitResult.Actor, DamageType, OutSpec);
	}

	/**
	 * Handles dealing damage using the built-in effect spec, using the `damage` property.
	 * Updates the effect context with the hit result and if it was a precision hit (based on hit result).
	 * @param OverrideSpec Optional effect spec to pass instead of the built-in 'Damage Spec'.
	 */
	UFUNCTION(Category = "Damage", BlueprintAuthorityOnly, BlueprintAuthorityOnly, Meta = (AdvancedDisplay = "OptionalOverrideSpec"))
	void DealDamage(FHitResult Hit, EDamageType DamageType = EDamageType::Other, FGameplayEffectSpecHandle OptionalOverrideSpec = FGameplayEffectSpecHandle())
	{
		ThrowIf(bDealsDamage && !DamageEffectClass.IsValid(), "HeroAbility deals damage, but no valid damage effect has been set!");
		ThrowIf(!bDealsDamage, "Ability does not deal damage, but is marked bDealsDamage = true");

		if (HasAuthority())
		{
			if (!DamageSpecHandle.IsValid())
				DamageSpecHandle = MakeOutgoingGameplayEffectSpec(DamageEffectClass, 1);

			DamageSpecHandle = (bDealsDamage && DamageEffectClass.IsValid() && !OptionalOverrideSpec.IsValid()) ? DamageSpecHandle : OptionalOverrideSpec;

			FGameplayAbilityTargetDataHandle TargetData = AbilitySystem::AbilityTargetDataFromHitResult(Hit);
			DamageSpecHandle.Spec.Context = ASC.MakeEffectContext();
			DamageSpecHandle.Spec.Context.DamageType = DamageType;
			DamageSpecHandle.Spec.Context.IsPrecisionHit = FHitResult::IsPrecisionHitFromHitResult(Hit);
			DamageSpecHandle.Spec.Context.AddInstigator(OwningActorFromActorInfo, AvatarActor);
			DamageSpecHandle.Spec.Context.AddHitResult(Hit, true);

			ApplyGameplayEffectSpecToTarget(DamageSpecHandle, TargetData);
		}
	}

	/**
	 * @param IgnoreHitActorFromHitResult Tries to ignore the actor from the hit result that invoked this enchant. Depending on what you hit, this might not work.
	 */
	UFUNCTION(Category = "Damage", DisplayName = "Deal Damage (Actor)", BlueprintAuthorityOnly)
	TArray<FActiveGameplayEffectHandle> DealDamage_Actor(AActor Actor, EDamageType DamageType)
	{
		TArray<AActor> ActorsToIgnore;

		return DealDamage_IgnoreAdditional(Actor, DamageType, ActorsToIgnore);
	}

	UFUNCTION(Category = "Damage", DisplayName = "Deal Damage (Ignore Additional Actors)", BlueprintAuthorityOnly)
	TArray<FActiveGameplayEffectHandle> DealDamage_IgnoreAdditional(AActor Actor, EDamageType DamageType, TArray<AActor> ActorsToIgnore = TArray<AActor>())
	{
		TArray<FActiveGameplayEffectHandle> Handles;
		bool bShouldIgnore = false;
		if (!ActorsToIgnore.IsEmpty())
		{
			for (auto ItActor : ActorsToIgnore)
			{
				if (Actor == ItActor)
				{
					bShouldIgnore = true;
					break;
				}
			}
		}

		if (!bShouldIgnore)
		{
			FGameplayEffectSpecHandle Spec;
			bool bSuccess = MakeDamageSpec(Actor, DamageType, Spec);
			check(bSuccess);
			Handles = ApplyGameplayEffectSpecToTarget(Spec, AbilitySystem::AbilityTargetDataFromActor(Actor));
		}

		return Handles;
	}

	/**
	 * @param IgnoreHitActorFromHitResult Tries to ignore the actor from the hit result that invoked this enchant. Depending on what you hit, this might not work.
	 */
	UFUNCTION(Category = "Damage", BlueprintAuthorityOnly, Meta = (AdvancedDisplay = "ActorToIgnore,IgnoreHitActorFromHitResult"))
	TArray<FActiveGameplayEffectHandle> DealDamageToTargets(TArray<AActor> Actors, EDamageType DamageType, AActor ActorToIgnore = nullptr, bool IgnoreHitActorFromHitResult = false)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.AddUnique(ActorToIgnore);
		if (IgnoreHitActorFromHitResult)
		{
			FHitResult Hit = AbilitySystem::GetHitResultFromTargetData(CurrentEventData.TargetData, 0);
			ActorsToIgnore.AddUnique(Hit.Actor);
		}

		return DealDamageToTargets_IgnoreAdditional(Actors, DamageType, ActorsToIgnore);
	}

	UFUNCTION(Category = "Damage", DisplayName = "Deal Damage To Targets (Ignore Additional Actors)", BlueprintAuthorityOnly)
	TArray<FActiveGameplayEffectHandle> DealDamageToTargets_IgnoreAdditional(TArray<AActor> Actors, EDamageType DamageType, TArray<AActor> ActorsToIgnore = TArray<AActor>())
	{
		TArray<FActiveGameplayEffectHandle> FinalHandles;
		TArray<FActiveGameplayEffectHandle> IterationHandles;

		auto TargetData = AbilitySystem::AbilityTargetDataFromActorArray(Actors, true);
		for (auto TargetActor : AbilitySystem::GetAllActorsFromTargetData(TargetData))
		{
			IterationHandles = DealDamage_IgnoreAdditional(TargetActor, DamageType, ActorsToIgnore);
			AddRange(FinalHandles, IterationHandles);
		}

		return FinalHandles;
	}

	private TArray<FActiveGameplayEffectHandle> AddRange(TArray<FActiveGameplayEffectHandle>& Array, TArray<FActiveGameplayEffectHandle> Range, bool bAddUnique = false)
	{
		for (auto Object : Range)
		{
			if (!bAddUnique)
				Array.Add(Object);
			else
				Array.AddUnique(Object);
		}

		return Array;
	}
}

UCLASS(HideDropdown)
class UGA_HeroAltFireAbility_AS : UGA_HeroAbility_AS
{
	default AbilityTags.AddTag(GameplayTags::State_Weapon_AltFiring);

	default ActivationOwnedTags.AddTag(GameplayTags::State_Weapon_AltFiring);
	default ActivationBlockedTags.AddTag(GameplayTags::State_Weapon_AltFireBlocked);
	default CancelAbilitiesWithTag.AddTag(GameplayTags::State_Sprinting);

	default NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;

	UFUNCTION(BlueprintOverride)
	void ActivateAbility()
	{
		// TODO:
		/* auto GC = UGunComponent::Get(OwningHero);
		GC.StartAimDownSights(); */
	}

	UFUNCTION(BlueprintOverride)
	void OnEndAbility(bool bWasCancelled)
	{
		// TODO:
		/* auto GC = UGunComponent::Get(OwningHero);
		GC.EndAimDownSights(); */
	}
}

/**
 * This class expects you to call `CommitAbility` from the OnCompleted pin of your `PlayMontageAndWait` node.
 */
UCLASS(HideDropdown)
class UGA_HeroReloadAbility_AS : UGA_HeroAbility_AS
{
	default AbilityTags.AddTag(GameplayTags::State_Weapon_Reloading);

	default CancelAbilitiesWithTag.AddTag(GameplayTags::State_Weapon_AltFiring);
	default BlockAbilitiesWithTag.AddTag(GameplayTags::State_Weapon_AltFiring);
	default ActivationOwnedTags.AddTag(GameplayTags::State_Weapon_Reloading);

	default ActivationBlockedTags.AddTag(GameplayTags::State_Sprinting);
	default ActivationBlockedTags.AddTag(GameplayTags::State_Ammo_Full);

	// Run the ability client-side alongside the server, but let the server decide the result.
	default NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;

	/**
	 * Effect to apply when the reload animation has completed.
	 */
	UPROPERTY(Category = "Ability | Spec", EditInline)
	TSubclassOf<UGameplayEffect> ReloadEffectClass;

	UFUNCTION(BlueprintOverride)
	void OnEndAbility(bool bWasCancelled)
	{
		ASC.RemoveLooseGameplayTag(GameplayTags::State_Weapon_ReloadCancelBlocked);
	}

	UFUNCTION(BlueprintAuthorityOnly)
	void ApplyReloadEffect()
	{
		if (HasAuthority())
		{
			auto Context = ASC.MakeEffectContext();
			ASC.ApplyGameplayEffectToSelf(ReloadEffectClass, 1, Context);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetReloadMontagePlayRate()
	{
		float ReloadSpeed = ASC.GetAttributeCurrentValue(UGenericGunAttributes, UGenericGunAttributes::ReloadSpeedName, 1);
		float Result = Math::Max((1 * ReloadSpeed), UGenericGunAttributes::RELOAD_FLOOR);
		return Result;
	}
};

UCLASS(HideDropdown)
class UGA_HeroMeleeAbility_AS : UGA_HeroShootAbility_AS
{
	UPROPERTY(BlueprintReadOnly)
	UAnimMontage MeleeMontage;

	UAbilityTask_PlayMontageAndWait MontageTask;
	UAbilityTask_WaitGameplayEvent WaitGameplayEventTask;

	UFUNCTION(BlueprintOverride)
	void ActivateAbility()
	{
		Super::ActivateAbility();

		if (CommitAbility())
		{
			MontageTask = AngelscriptAbilityTask::PlayMontageAndWait(this, NAME_None, MeleeMontage);
			MontageTask.OnInterrupted.AddUFunction(this, n"OnInterrupted");
			MontageTask.OnCompleted.AddUFunction(this, n"OnComplete");
			MontageTask.ReadyForActivation();

			// TODO:
			//WaitGameplayEventTask = AngelscriptAbilityTask::WaitGameplayEvent(this, GameplayTags::AnimNotify_Events_Melee);
			WaitGameplayEventTask.EventReceived.AddUFunction(this, n"EventReceived");
			WaitGameplayEventTask.ReadyForActivation();
		}
		else
		{
			CancelAbility();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInterrupted()
	{
		MontageTask.EndTask();
		CancelAbility();
	}

	UFUNCTION()
	private void OnComplete()
	{
		MontageTask.EndTask();
		EndAbility();
	}

	UFUNCTION()
	private void EventReceived(FGameplayEventData Payload)
	{
		// TODO:
		//ExecuteGameplayCue(GameplayTags::GameplayCue_Hero_Generic_Melee_SFX, ASC.MakeEffectContext());

		TArray<AActor> IgnoreActors;
		TArray<AActor> NearbyActors = GetNearbyTargets(AvatarLocation, 300.f, true, false, IgnoreActors, DrawDebug = false);
		for (auto Actor : NearbyActors)
		{
			FVector Dir = AvatarLocation - Actor.ActorLocation;
			auto Normal = Dir.GetSafeNormal();
			FVector LaunchDir = -Normal * 2500;

			auto Target = Cast<ACharacter>(Actor);
			if (IsValid(Target))
			{
				Target.LaunchCharacter(LaunchDir, false, false);
			}
		}

		DealDamageToTargets(NearbyActors, EDamageType::Melee);

		WaitGameplayEventTask.EndTask();
		EndAbility();
	}
}