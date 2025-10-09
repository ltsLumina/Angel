struct FBulletHit
{
    UPROPERTY()
    bool BlockingHit;
    UPROPERTY()
    bool PlayerHit;
    UPROPERTY()
    bool Headshot;
    UPROPERTY()
    float Distance;
    UPROPERTY()
    FVector Location;
    UPROPERTY()
    AActor HitActor;
    UPROPERTY()
    AAngelTrainingDummy HitPlayer;
    UPROPERTY()
    FName HitBoneName;
    UPROPERTY()
    FBodyPartHit HitBodyPart;
};

struct FBodyPartHit
{
    UPROPERTY()
    bool Head;
    UPROPERTY()
    bool Body; 
    UPROPERTY()
    bool Legs;
    UPROPERTY()
    EBodyPart BodyPart;
};