class UManualWalkingComponent : UActorComponent
{
    UPROPERTY(Category = "Gameplay | Stamina")
    bool UseStamina;
    default UseStamina = true;

    UPROPERTY(Category = "Gameplay | Stamina", EditDefaultsOnly, Meta = (ClampMin = MinStamina, ClampMax = MaxStamina))
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
    bool GetIsStaminaDepleted() const { return Stamina <= MinStamina; }

    UFUNCTION(BlueprintPure, Category = "Config | Stamina")
    bool GetIsRegeneratingStamina() const { return TimeSinceInput >= StaminaRegenDelay && !GetIsStaminaFull(); }
    
    UFUNCTION(BlueprintPure, Category = "Config | Stamina")
    bool GetIsStaminaFull() const { return Stamina >= MaxStamina; }

// - flow state

    UPROPERTY(Category = "Stamina | Flow State")
    float FlowStateStaminaRegenerationRate;
    default FlowStateStaminaRegenerationRate = 30; // per second

// - config | movement

    UPROPERTY(Category = "Config | Movement", BlueprintGetter = GetCanMove, VisibleAnywhere)
    bool CanMove;

    bool GetCanMoveOutput(bool&out MoveDelay, bool&out SufficientStamina, bool&out Input, bool&out InputMagnitude) const
    {
        MoveDelay = MoveDelayCondition();
        SufficientStamina = StaminaCondition();
        Input = InputCondition();
        InputMagnitude = InputMagnitudeCondition();

        bool Allowed = MoveDelay && SufficientStamina && Input && InputMagnitude;
        return Allowed;
    }

    /* Requires the following conditions to be true:
       1. Time since last input is greater than or equal to the input delay.
       2. Stamina is greater than the minimum required stamina.
       3. Move input is not zero (i.e., player is trying to move).
       4. Move input magnitude is greater than or equal to the minimum input magnitude.
    */
    UFUNCTION(BlueprintPure, Category = "Config | Movement")
    bool GetCanMove() const
    {
        return MoveDelayCondition() && 
               StaminaCondition() && 
               InputCondition() && 
               InputMagnitudeCondition();
    }

    bool MoveDelayCondition() const { return TimeSinceInput >= InputDelay;}
    bool StaminaCondition() const { return Stamina >= MoveLegStaminaCost; }
    bool InputCondition() const { return MoveInput != FVector2D::ZeroVector; }
    bool InputMagnitudeCondition() const { return MoveInput.Size() >= MinInputMagnitude; }

// - config | input

    // The minimum input magnitude required to move. If the input is below this value, the player will not move. This also doubles as a minimum move distance.
    UPROPERTY(Category = "Config | Input")
    float MinInputMagnitude;
    default MinInputMagnitude = 0.2f;

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    bool MoveCooldown;
    default MoveCooldown = true;

    UPROPERTY(Category = "Config | Input", VisibleAnywhere)
    FKey ExpectedMoveKey;
    default ExpectedMoveKey = FKey(n"Q");

    float TimeSinceInput;
    float InputDelay;
    default InputDelay = 0.05;

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

        if (Character.GameplayTags.HasTag(GameplayTags::Buffs_State_Flow))
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
            // Handled in Blueprint
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

    UFUNCTION()
    void OnMove(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        if (MoveCooldown)
        {
            MoveInput = ActionValue.GetAxis2D();
        }
        else
        {
            Character.AddMovementInput(Character.GetActorRightVector(), MoveInput.X, false);
            Character.AddMovementInput(Character.GetActorForwardVector(), MoveInput.Y, false);
        }
    }

    UFUNCTION()
    void OnMoveCompleted(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        MoveInput = FVector2D::ZeroVector;
    }

    UFUNCTION(NotBlueprintCallable)
    void OnKeyPressed(FKey Key)
    {
        if (Key == ExpectedMoveKey)
        {
            bool MoveDelay, SufficientStamina, Input, InputMagnitude;
            if (!GetCanMoveOutput(MoveDelay, SufficientStamina, Input, InputMagnitude))
            {
                Print(f"Cannot Move: Conditions not met. \n(Move Delay: {MoveDelay}, Sufficient Stamina: {SufficientStamina}, Input: {Input}, Input Magnitude: {InputMagnitude})", 5, FLinearColor(0.93, 0.29, 0.44));
                return;
            }

            MoveCharacter(Key);
            SwapExpectedMoveKey();
        }
        else if (Key != ExpectedMoveKey)
        {
            Print(f"Cannot Move: Incorrect key pressed. \n(Expected: {ExpectedMoveKey.ToString()}, Received: {Key.ToString()})", .5f, FLinearColor(0.93, 0.29, 0.44));
            return;
        }
    }

    void SwapExpectedMoveKey()
    {
        ExpectedMoveKey = (ExpectedMoveKey == FKey(n"Q")) ? FKey(n"E") : FKey(n"Q");
    }

    void MoveCharacter(FKey Key, float MoveDuration = 0.3)
    {
        TimeSinceInput = 0;

        float Distance;
        if (Stamina < MoveLegStaminaCost && MoveLegStaminaCost > 0)
        {
            float MinDistance = MoveDuration * 0.33;
            Distance = Math::Clamp(MoveDuration * (Stamina / MoveLegStaminaCost), MinDistance, MoveDuration);
        }
        else
        {
            Distance = MoveDuration;
        }

        MoveCooldown = !MoveCooldown;
        System::SetTimer(this, n"EnableMoveCooldown", Distance, bLooping=false);
        CharacterMoved(Distance, Key);

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