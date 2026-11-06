class UPondCheatManager : UCheatManager
{
	UPROPERTY(Category = "Debug")
	TSubclassOf<UAngelscriptGameplayEffect> NoReloadEffect;

	UPROPERTY(Category = "Debug")
	TSubclassOf<UAngelscriptGameplayEffect> KillEffect;

	UPROPERTY(Category = "Debug")
	TSubclassOf<AScriptEnemyBase> EnemyClass;

	UPROPERTY(Category = "Debug")
	TSubclassOf<AScriptEnemyBase> DummyClass;

	UPROPERTY(Category = "Debug")
	TSubclassOf<UAngelscriptGameplayEffect> InvulnerableEffect = UGameplayAbilitiesGlobals::GetDefaultInvulnerableEffect();

	UPROPERTY(Category = "Debug")
	TSubclassOf<UAngelscriptGameplayEffect> ImmuneEffect = UGameplayAbilitiesGlobals::GetDefaultImmuneEffect();

	UPROPERTY(Category = "Debug")
	TSubclassOf<UAngelscriptGameplayEffect> UndyingEffect = UGameplayAbilitiesGlobals::GetDefaultUndyingEffect();

	UPROPERTY(Category = "Debug")
	TSubclassOf<UUserWidget> CheatMenuWidgetClass;

	UPROPERTY(Category = "Debug")
	TSubclassOf<AActor> TetherPylonActor;

	/**
	 * Become Invulnerable. (GAS)
	 */
	UFUNCTION(Exec)
	void GodMode()
	{
		auto Char = Cast<AScriptPondHero>(PlayerController.ControlledPawn);
		Char.AbilitySystem.ApplyGameplayEffectToSelf(InvulnerableEffect, 1, Char.AbilitySystem.MakeEffectContext());
	}

	UFUNCTION(Exec)
	void SelfDestruct()
	{
		UAngelscriptAbilitySystemComponent SourceASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(PlayerController.ControlledPawn);
		auto Handle = SourceASC.MakeOutgoingSpec(KillEffect, 1, SourceASC.MakeEffectContext());
		Handle.Spec.SetByCallerMagnitude(GameplayTags::SetByCaller_Damage, UGenericGunAttributes::DAMAGE_CAP);

		SourceASC.ApplyGameplayEffectSpecToTarget(Handle, SourceASC);
	}

	UFUNCTION(Exec)
	void SetDamage(int Amount)
	{
		auto Char = Cast<AScriptPondHero>(PlayerController.ControlledPawn);
		if (Char.AbilitySystem.TrySetAttributeBaseValue(UGenericGunAttributes, UGenericGunAttributes::DamageName, Amount))
		{
			Print(f"Set weapon damage to {Amount}!");
		}
	}

	UFUNCTION(Exec)
	void Sonic(float Amount)
	{
		auto Char = Cast<AScriptPondHero>(PlayerController.ControlledPawn);
		Char.AbilitySystem.TrySetAttributeBaseValue(UCharacterAttributes, UCharacterAttributes::MaxMoveSpeedName, Amount);
		Char.AbilitySystem.TrySetAttributeBaseValue(UCharacterAttributes, UCharacterAttributes::MoveSpeedName, Amount);
	}

	UFUNCTION(Exec)
	void ReviveSelf()
	{
		auto Char = Cast<AScriptPondHero>(PlayerController.ControlledPawn);
		Char.TryRevive();
	}

	UFUNCTION(Exec)
	void Nuke()
	{
		TArray<AScriptEnemyBase> Enemies;
		GetAllActorsOfClass(AScriptEnemyBase, Enemies);

		for (auto& Enemy : Enemies)
		{
			Enemy.Death();
		}
	}

	UFUNCTION(Exec)
	void KillTarget(bool IsPrecision = false)
	{
		FHitResult Hit;
		AActor Target = PlayerController.GetLookedAtActor(2500, Hit);

		UAngelscriptAbilitySystemComponent SourceASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(PlayerController.ControlledPawn);
		UAngelscriptAbilitySystemComponent TargetASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(Target);

		FGameplayEffectContextHandle Context = SourceASC.MakeEffectContext();
		Context.AddHitResult(Hit, true);
		auto Instigator = PlayerController.ControlledPawn;
		Context.AddInstigator(Instigator, Instigator);
		Context.AddOrigin(Hit.Location);
		Context.SetIsPrecisionHit(IsPrecision);

		auto Handle = SourceASC.MakeOutgoingSpec(KillEffect, 1, Context);
		Handle.Spec.SetByCallerMagnitude(GameplayTags::SetByCaller_Damage, UGenericGunAttributes::DAMAGE_CAP);

		SourceASC.ApplyGameplayEffectSpecToTarget(Handle, TargetASC);
	}

	UFUNCTION(Exec)
	void KillTargetWithTag(FGameplayTag TriggerTag)
	{
		FHitResult Hit;
		AActor Target = PlayerController.GetLookedAtActor(2500, Hit);

		UAngelscriptAbilitySystemComponent SourceASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(PlayerController.ControlledPawn);
		UAngelscriptAbilitySystemComponent TargetASC = AbilitySystem::GetAngelscriptAbilitySystemComponent(Target);

		FGameplayEffectContextHandle Context = SourceASC.MakeEffectContext();
		Context.AddHitResult(Hit, true);
		auto Instigator = PlayerController.ControlledPawn;
		Context.AddInstigator(Instigator, Instigator);
		Context.AddOrigin(Hit.Location);

		auto Handle = SourceASC.MakeOutgoingSpec(KillEffect, 1, Context);
		Handle.Spec.SetByCallerMagnitude(GameplayTags::SetByCaller_Damage, UGenericGunAttributes::DAMAGE_CAP);

		if (TriggerTag.IsValid())
			Handle.AddDynamicAssetTag(TriggerTag);

		SourceASC.ApplyGameplayEffectSpecToTarget(Handle, TargetASC);
	}

	UUserWidget CheatMenuWidget;

	UFUNCTION(Exec)
	void ShowCheatMenu(FKey _)
	{
		if (IsValid(CheatMenuWidget) && CheatMenuWidget.IsVisible())
			return;

		if (!IsValid(CheatMenuWidget))
		{
			CheatMenuWidget = WidgetBlueprint::CreateWidget(CheatMenuWidgetClass, PlayerController);
			CheatMenuWidget.AddToViewport();
		}

		Widget::SetInputMode_GameAndUIEx(PlayerController, CheatMenuWidget);
		CheatMenuWidget.SetVisibility(ESlateVisibility::Visible);
		CheatMenuWidget.SetFocus();

		PlayerController.SetIgnoreLookInput(true);
		PlayerController.bShowMouseCursor = true;
	}

	/**
	 * Alias for ShowCheatMenu.
	 */
	UFUNCTION(Exec)
	void OpenCheatMenu()
	{
		ShowCheatMenu(FKey());
	}

	UFUNCTION(Exec)
	void HideCheatMenu(FKey _)
	{
		if (!IsValid(CheatMenuWidget))
			return;

		CheatMenuWidget.SetVisibility(ESlateVisibility::Hidden);
		Widget::SetInputMode_GameOnly(PlayerController);

		PlayerController.SetIgnoreLookInput(false);
		PlayerController.bShowMouseCursor = false;
	}

	/**
	 * Alias for HideCheatMenu.
	 */
	UFUNCTION(Exec)
	void CloseCheatMenu()
	{
		HideCheatMenu(FKey());
	}

	UFUNCTION(Exec)
	void ToggleCheatMenu(FKey _)
	{
		if (!IsValid(CheatMenuWidget))
		{
			ShowCheatMenu(_); // init if not yet created.
			return;
		}

		if (CheatMenuWidget.IsVisible())
		{
			HideCheatMenu(_);
		}
		else
		{
			ShowCheatMenu(_);
		}
	}

	UFUNCTION(Exec)
	void NoReload()
	{
		auto Char = Cast<AScriptPondHero>(PlayerController.ControlledPawn);
		Char.AbilitySystem.ApplyGameplayEffectToSelf(NoReloadEffect, 1, FGameplayEffectContextHandle());
	}

	/**
	 * Spawns a basic enemy.
	 * @param Invulnerable By default this is false. Target Dummies are invulnerable by default.
	 */
	UFUNCTION(Exec)
	void SpawnEnemy(bool Invulnerable = false, bool DamageImmune = false, bool Undying = false, bool bSimulateBehaviour = false)
	{
		if (!PlayerController.HasAuthority())
		{
			PrintError("Only the server can run this command.");
			return;
		}

		FVector Location = PlayerController.ControlledPawn.ActorLocation + PlayerController.ControlRotation.ForwardVector * 100;
		Location.Z = PlayerController.ControlledPawn.ActorLocation.Z;

		FVector ZeroVector = FVector::ZeroVector;
		FRotator Rotation = (ZeroVector - PlayerController.ControlRotation.Vector()).Rotation();
		Rotation.Pitch = 0;

		auto Enemy = SpawnActor(EnemyClass, Location, Rotation, NAME_None, true);
		Enemy.SpawnCollisionHandlingMethod = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		Enemy.SetSimulateBehaviour(bSimulateBehaviour);
		FinishSpawningActor(Enemy);

		if (Invulnerable)
			Enemy.AbilitySystem.ApplyGameplayEffectToSelf(InvulnerableEffect, 1, FGameplayEffectContextHandle());

		if (DamageImmune)
			Enemy.AbilitySystem.ApplyGameplayEffectToSelf(ImmuneEffect, 1, FGameplayEffectContextHandle());

		if (Undying)
			Enemy.AbilitySystem.ApplyGameplayEffectToSelf(UndyingEffect, 1, FGameplayEffectContextHandle());
	}

	/**
	 * Summons a target dummy enemy, invulnerable by default.
	 * @params Invulnerable Set to false to be able to deal damage to the enemy.
	 */
	UFUNCTION(Exec)
	void SpawnDummy(bool Invulnerable = true, bool DamageImmune = false, bool Undying = false)
	{
		if (!PlayerController.HasAuthority())
		{
			PrintError("Only the server can run this command.");
			return;
		}

		FVector Location = PlayerController.ControlledPawn.ActorLocation + PlayerController.ControlRotation.ForwardVector * 100;
		Location.Z = PlayerController.ControlledPawn.ActorLocation.Z;

		FVector ZeroVector = FVector::ZeroVector;
		FRotator Rotation = (ZeroVector - PlayerController.ControlRotation.Vector()).Rotation();
		Rotation.Pitch = 0;

		auto Dummy = SpawnActor(DummyClass, Location, Rotation);

		if (Invulnerable)
			Dummy.AbilitySystem.ApplyGameplayEffectToSelf(InvulnerableEffect, 1, FGameplayEffectContextHandle());

		if (DamageImmune)
			Dummy.AbilitySystem.ApplyGameplayEffectToSelf(ImmuneEffect, 1, FGameplayEffectContextHandle());

		if (Undying)
			Dummy.AbilitySystem.ApplyGameplayEffectToSelf(UndyingEffect, 1, FGameplayEffectContextHandle());
	}

	UFUNCTION(Exec)
	void SetSensitivity(int NewSensitivity)
	{
		auto PondController = Cast<AScriptPondController>(PlayerController);
		PondController.SetSensitivity(NewSensitivity);
	}

	UFUNCTION(Exec)
	void SetHero(FString HeroName)
	{
#if EDITOR
		AHeroPickerTool HeroPicker = Gameplay::GetActorOfClass(AHeroPickerTool);

		if (HeroName == "Hawkmoon")
		{
			HeroPicker.aHawkmoon();
		}
		else if (HeroName == "Izanagi")
		{
			HeroPicker.bIzanagi();
		}
		else if (HeroName == "Tremolo")
		{
			HeroPicker.cTremolo();
		}
		else if (HeroName == "Bastion")
		{
			HeroPicker.dBastion();
		}
#endif
	}

	UFUNCTION(Exec)
	void SkipZone(bool bBeginNextEncounter = false)
	{
		UZoneSubsystem::Get().SetZone(UZoneSubsystem::Get().EditorOnlyGetZoneIndex() + 1);
	}

	UFUNCTION(Exec)
	void EndEncounter(bool bForce = false)
	{
		UZoneSubsystem::Get().EndEncounter(bForce);
	}

	AActor TeleportActor;

	UFUNCTION(Exec)
	void TravelToZone(FName ZoneIdentifier)
	{
		TArray<AActor> Actors;
		Gameplay::GetAllActorsOfClass(AZoneTrigger, Actors);

		TArray<AZoneTrigger> ZoneTriggers;
		for (auto A : Actors)
		{
			auto Zone = Cast<AZoneTrigger>(A);
			ZoneTriggers.Add(Zone);
			
			if (Zone.ActorNameOrLabel.Contains(ZoneIdentifier.ToString()))
			{
				UChatComponent::SendConsoleMessageToActor(PlayerController, f"Travelling to {Zone.ActorNameOrLabel}");
				System::SetTimer(this, n"Travel", 0.5f, false);
				TeleportActor = A;
				return;
			}
		}

		UChatComponent::SendConsoleMessageToActor(PlayerController, f"Map is not loaded.");
	}

	UFUNCTION(NotBlueprintCallable)
	private void Travel()
	{
		Cast<APondPlayerController>(PlayerController).FlushLevelStreaming();
		
		PlayerController.ControlledPawn.Teleport(TeleportActor.ActorLocation, PlayerController.ControlledPawn.ActorRotation);
		
		TeleportPlayersToMe();
	}

	UFUNCTION(Exec)
	void Unstuck()
	{
		TArray<AScriptPondHero> Heroes;
		for (auto PS : Gameplay::GetGameState().PlayerArray)
		{
			Heroes.Add(Cast<AScriptPondHero>(PS.Get().Pawn));
		}

		for (auto Hero : Heroes)
		{
			FVector UnstuckLocation = URoomSubsystem::Get().GetTeleportLocation();
			FVector TeleportBoxBottomLocation = UnstuckLocation;
			TeleportBoxBottomLocation.Z += Hero.CapsuleComponent.CapsuleHalfHeight;
			Hero.SetActorLocation(TeleportBoxBottomLocation);
		}
	}

	UFUNCTION(Exec)
	void SpawnPylon()
	{
		if (!PlayerController.HasAuthority())
		{
			PrintError("Only the server can run this command.");
			return;
		}

		FVector Location = PlayerController.ControlledPawn.ActorLocation + PlayerController.ControlRotation.ForwardVector * 100;
		Location.Z = PlayerController.ControlledPawn.ActorLocation.Z + 175;

		FVector ZeroVector = FVector::ZeroVector;
		FRotator Rotation = (ZeroVector - PlayerController.ControlRotation.Vector()).Rotation();
		Rotation.Pitch = 0;

		auto Pylon = SpawnActor(TetherPylonActor, Location, Rotation, NAME_None, false);
	}

	// System

	UFUNCTION(Exec)
	void ForceCrash()
	{
		// Let's definitely crash
		System::ExecuteConsoleCommand("debug crash");

		check(false);
	}

	UFUNCTION(Exec)
	void ForceGarbageCollection()
	{
		System::CollectGarbage();
	}

	UFUNCTION(Exec)
	void TeleportPlayersToMe()
	{
		TArray<AScriptPondHero> AllHeroes;
		GetAllActorsOfClass(AScriptPondHero, AllHeroes);

		float XVectorMultipier = 1;

		FVector MyLocation = PlayerController.ControlledPawn.ActorLocation;
		FVector ForwardLocation = PlayerController.ControlledPawn.ActorForwardVector;
		FVector XVectorLocation = PlayerController.ControlledPawn.ActorRightVector;

		for (AScriptPondHero Hero : AllHeroes)
		{
			FVector SpawnLocation = MyLocation + (ForwardLocation * 300) + (XVectorLocation * (XVectorMultipier * -200));
			XVectorMultipier--;

			if (Hero.Controller != PlayerController)
			{
				Hero.SetActorLocationAndRotation(SpawnLocation, PlayerController.ControlledPawn.ActorRotation);
				Print(f"Actor rotation: {PlayerController.ControlledPawn.ActorRotation}");
			}
		}
	}
}