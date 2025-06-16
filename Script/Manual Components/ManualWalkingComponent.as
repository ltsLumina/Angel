class UManualWalkingComponent : UActorComponent
{
    UPROPERTY(Category = "Gameplay | Stamina")
    bool UseStamina;
    default UseStamina = true;

    UPROPERTY(Category = "Gameplay | Stamina", Meta = (ClampMin = MinStamina, ClampMax = MaxStamina))
    float Stamina;
    default Stamina = 100;

    UPROPERTY(Category = "Gameplay | Stamina")
    float MaxStamina;
    default MaxStamina = 100;

    UPROPERTY(Category = "Gameplay | Stamina")
    float MinStamina;
    default MinStamina = 0;

    UPROPERTY(Category = "Gameplay | Stamina")
    float MoveLegStaminaCost;
    default MoveLegStaminaCost = 25;

    UPROPERTY(Category = "Gameplay | Stamina")
    float RepeatInputStaminaPenalty;
    default RepeatInputStaminaPenalty = 10;

    // Will begin to regenerate stamina after this amount of time, in seconds.
    UPROPERTY(Category = "Gameplay | Stamina")
    float StaminaRegenDelay;
    default StaminaRegenDelay = 1; // in seconds

    // The amount of stamina to regenerate per second.
    UPROPERTY(Category = "Gameplay | Stamina")
    float StaminaRegenRate;
    default StaminaRegenRate = 35; // per second

// - config | stamina

    UPROPERTY(BlueprintGetter = GetIsStaminaDepleted, Category = "Config | Stamina", VisibleAnywhere)
    bool IsStaminaDepleted;

    UPROPERTY(BlueprintGetter = GetIsRegeneratingStamina, Category = "Config | Stamina", VisibleAnywhere)
    bool IsRegeneratingStamina;

    UPROPERTY(BlueprintGetter = GetIsStaminaFull, Category = "Config | Stamina", VisibleAnywhere)
    bool IsStaminaFull;

    UFUNCTION(BlueprintPure, Category = "Config | Stamina")
    bool GetIsStaminaDepleted() const
    {
        return Stamina <= MinStamina;
    }

    UFUNCTION(BlueprintPure, Category = "Config | Stamina")
    bool GetIsRegeneratingStamina() const
    {
        // If stamina is not full and the time since input is greater than the Regen delay, then we are regenerating stamina.
        return TimeSinceInput >= StaminaRegenDelay && !GetIsStaminaFull();
    }
    
    UFUNCTION(BlueprintPure, Category = "Config | Stamina")
    bool GetIsStaminaFull() const
    {
        return Stamina >= MaxStamina;
    }

// - flow state

    UPROPERTY(Category = "Stamina | Flow State")
    float FlowStateStaminaRegenerationRate;
    default FlowStateStaminaRegenerationRate = 30; // per second

// - config | movement

    UPROPERTY(BlueprintGetter = GetCanMove, Category = "Config | Movement", VisibleAnywhere)
    bool CanMove;

    UPROPERTY(Category = "Config | Movement", VisibleAnywhere)
    FKey NextMoveKey;
    default NextMoveKey = FKey(n"Q");

// - config | input

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    bool MoveCooldown;
    default MoveCooldown = true;

    float TimeSinceInput;
    float InputDelay;
    default InputDelay = 0.05;

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    bool Q_Pressed;

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    bool E_Pressed;
    // Defaults E to be 'active' so that the first Q input counts as valid.
    default E_Pressed = true;

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    FVector2D MoveInput;

    AAngelPlayerCharacter Character;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Character = GetAngelCharacter(GetOwner());
        
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Begin Play"))
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        BP_Tick(DeltaSeconds);

        if (Character.GameplayTags.HasTag(GameplayTags::Buffs_FlowState))
        {
            RegenerateStamina(FlowStateStaminaRegenerationRate, DeltaSeconds);
        }

        if (MoveCooldown)
        {
            TimeSinceInput += DeltaSeconds;

            if (TimeSinceInput >= StaminaRegenDelay && !GetIsStaminaFull())
            {
                RegenerateStamina(StaminaRegenRate, DeltaSeconds);
            }
        }
        else // MoveCooldown False
        {
            Character.AddMovementInput(Character.GetActorForwardVector(), 1, false);
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Tick"))
    void BP_Tick(float DeltaSeconds) { }

    // Is BlueprintCallable in the event you want to begin stamina regeneration early.
    // Returns true if stamina is still regenerating, false if it is full.
    UFUNCTION(BlueprintCallable)
    void RegenerateStamina(float RegenerationRate, float DeltaSeconds)
    {
        AddStamina(RegenerationRate * DeltaSeconds);
    }

    UFUNCTION(BlueprintPure, Category = "Gameplay | Movement")
    bool GetCanMove() const
    {
        return TimeSinceInput >= InputDelay;
    }

    UFUNCTION(NotBlueprintCallable)
    void OnKeyPressed(FKey Key)
    {
        if (!GetCanMove())
        {
            Print("Cannot move yet!", 1, FLinearColor(0.93, 0.29, 0.44));
            SubtractStamina(RepeatInputStaminaPenalty);
            Print("Stamina Penalty Applied!", 1, FLinearColor(0.93, 0.29, 0.44));
            return;
        }

        TimeSinceInput = 0;

        if // Q Pressed
        (Key == FKey(n"Q"))
        {
            Q_Pressed = true;
            BP_OnKeyPressed(Key);

            if (E_Pressed)
            {
                E_Pressed = false;

                if (!E_Pressed)
                {
                    if (!TryPerformMove(Key))
                    {
                        // If the move failed due to stamina, we reset back to the previous state.
                        Q_Pressed = false;
                        E_Pressed = true;
                    }
                }
            }
        }
        else // E Pressed
        {
            E_Pressed = true;
            BP_OnKeyPressed(Key);

            if (Q_Pressed)
            {
                Q_Pressed = false;

                if (!Q_Pressed)
                {
                    if (!TryPerformMove(Key))
                    {
                        // If the move failed due to stamina, we reset back to the previous state.
                        Q_Pressed = true;
                        E_Pressed = false;
                    }
                }
            }
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Key Pressed"))
    void BP_OnKeyPressed(FKey Key) { }

    bool TryPerformMove(FKey Key)
    {
        if (UseStamina)
        {
            if (Stamina > 0)
            {
                MoveCharacter(Key);
                return true;
            }

            return false;
        }
        else
        {
            MoveCharacter(Key);
            return true;
        }
    }

    void MoveCharacter(FKey Key, float MoveDuration = 0.3)
    {
        float Distance;
        if (Stamina < MoveLegStaminaCost && MoveLegStaminaCost > 0)
        {
            // Clamp the distance to a minimum value to prevent too short of a move.
            float MinDistance = MoveDuration * 0.33; // 33% of the move duration.
            // Scale distance by the fraction of stamina available.
            Distance = Math::Clamp(MoveDuration * (Stamina / MoveLegStaminaCost), MinDistance, MoveDuration);
        }
        else
        {
            Distance = MoveDuration;
        }

        MoveCooldown = !MoveCooldown;
        System::SetTimer(this, n"EnableMoveCooldown", Distance, bLooping=false);
        CharacterMoved(Distance, Key);

        // Used to display the correct button prompt for the next move.
        if (Key == FKey(n"Q"))
        {
            NextMoveKey = FKey(n"E");
        }
        else if (Key == FKey(n"E"))
        {
            NextMoveKey = FKey(n"Q");
        }

        SubtractStamina(MoveLegStaminaCost);
    }

    UFUNCTION(NotBlueprintCallable)
    void EnableMoveCooldown()
    {
        MoveCooldown = true;
    }

    UFUNCTION(BlueprintEvent, Category = "Gameplay | Movement")
    void CharacterMoved(float Distance, FKey Key) { }

    UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Add"))
    float AddStamina(float Input)
    {
        float Result = Stamina + Input;
        float Clamped = Math::Clamp(Result, MinStamina, MaxStamina);

        Stamina = Clamped;

        return Stamina;
    }

    UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Subtract"))
    float SubtractStamina(float Input)
    {
        float Result = Stamina - Input;
        float Clamped = Math::Clamp(Result, MinStamina, MaxStamina);

        Stamina = Clamped;

        return Stamina;
    }
};