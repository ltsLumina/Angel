event void FOnKillEvent(AAngelAgent Killer, AGunBase WeaponUsed, AActor Victim, bool WasHeadshot);
event void FOnDeathEvent(AAngelAgent Killer, AGunBase WeaponUsed, AActor Victim, bool WasHeadshot);

UCLASS(Abstract)
class AAngelAgent : AAngelscriptGASCharacter
{
	UPROPERTY(Category = "Agent", EditDefaultsOnly)
	FText AgentName;
    default AgentName = FText::FromString("Agent");

	UPROPERTY(Category = "Agent", EditDefaultsOnly)
	UTexture2D Avatar;
    default check(IsValid(Avatar), "Avatar texture not assigned!");

    // Events

    UPROPERTY(Category = "Agent | Events", VisibleAnywhere)
    FOnKillEvent OnKill;

    UPROPERTY(Category = "Agent | Events", VisibleAnywhere)
    FOnDeathEvent OnDeath;
}