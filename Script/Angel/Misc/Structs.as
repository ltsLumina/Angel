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

	FBulletHit()
	{
		BlockingHit = false;
		PlayerHit = false;
		Headshot = false;
		Distance = 0.0f;
		Location = FVector::ZeroVector;
		HitActor = nullptr;
		HitPlayer = nullptr;
		HitBoneName = NAME_None;
		HitBodyPart = FBodyPartHit();
	}

	FBulletHit(bool InBlockingHit, bool InPlayerHit, bool InHeadshot, float InDistance, FVector InLocation, AActor InHitActor, AAngelTrainingDummy InHitPlayer, FName InHitBoneName, FBodyPartHit InHitBodyPart)
	{
		BlockingHit = InBlockingHit;
		PlayerHit = InPlayerHit;
		Headshot = InHeadshot;
		Distance = InDistance;
		Location = InLocation;
		HitActor = InHitActor;
		HitPlayer = InHitPlayer;
		HitBoneName = InHitBoneName;
		HitBodyPart = InHitBodyPart;
	}
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

	FBodyPartHit()
	{
		Head = false;
		Body = false;
		Legs = false;
		BodyPart = EBodyPart::Body;
	}

	FBodyPartHit(bool InHead, bool InBody, bool InLegs, EBodyPart InBodyPart)
	{
		Head = InHead;
		Body = InBody;
		Legs = InLegs;
		BodyPart = InBodyPart;
	}
};

struct FBulletSpreadData
{
	float ConeWidth;
	float ConeHeight;
	float ErrorAngle;
	bool IsAccurate;
}

struct FEquipData
{
	UPROPERTY(Meta = (EditCondition = "Equip", EditConditionHides))
	EEquipSpeed Speed;
	UPROPERTY()
	bool Reload;

	FEquipData(EEquipSpeed InSpeed, bool InReload = false)
	{
		Speed = InSpeed;
		Reload = InReload;
	}
}
