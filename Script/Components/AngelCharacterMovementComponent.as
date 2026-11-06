class UAngelCharacterMovementComponent : UAngelCharacterMovementComponentBase
{
	AAngelCharacterBase Char;
	AAngelAgent Agent;
	UWeaponDefinition Definition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Char = Cast<AAngelCharacterBase>(GetOwner());
		Agent = Cast<AAngelAgent>(Char);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Poll for weapon definition.
		UGunComponent GunComponent = UGunComponent::Get(GetOwner());
		if (!IsValid(GunComponent))
			return;

		if (Definition == nullptr && GunComponent.WeaponDefinition != nullptr)
		{
			Definition = UGunComponent::Get(GetOwner()).WeaponDefinition;
		}
	}

	UFUNCTION(BlueprintOverride)
	float BP_GetMaxSpeed() const
	{
		if (!HasBegunPlay())
			return 0;

		if (!IsValid(Char))
		{
			throw(f"No owner found on '{GetOwner().ActorNameOrLabel}'");
			return GetMaxSpeed();
		}

		if (Char.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead))
		{
			return 0.0f;
		}

		if (Char.AbilitySystem.HasGameplayTag(GameplayTags::Debuffs_Stun))
		{
			return 0.0f;
		}

		if (IsValid(Definition) && Owner.IsA(AAngelAgent))
		{
			if (RequestToStartSprinting && !HeroUtils::IsReloading(Agent))
			{
				return MaxWalkSpeed;
			}

			if (RequestToStartADS && !HeroUtils::IsReloading(Agent))
			{
				return MaxWalkSpeed * Definition.AltMoveSpeedRatio;
			}
		}

		return MaxWalkSpeed;
	}

	UFUNCTION(BlueprintOverride)
	bool CanAttemptJump() const
	{
		if (!IsValid(Char))
		{
			throw(f"No owner found on '{GetOwner().ActorNameOrLabel}'");
			return false;
		}

		if (Char.AbilitySystem.HasGameplayTag(GameplayTags::State_Dead))
		{
			return false;
		}

		if (Char.AbilitySystem.HasGameplayTag(GameplayTags::Debuffs_Stun))
		{
			return false;
		}

		return true;
	}
}