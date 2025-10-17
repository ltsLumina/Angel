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
	AAngelAgent HitAgent;
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
		HitAgent = nullptr;
		HitBoneName = NAME_None;
		HitBodyPart = FBodyPartHit();
	}

	FBulletHit(bool InBlockingHit, bool InPlayerHit, bool InHeadshot, float InDistance, FVector InLocation, AActor InHitActor, AAngelAgent InHitPlayer, FName InHitBoneName, FBodyPartHit InHitBodyPart)
	{
		BlockingHit = InBlockingHit;
		PlayerHit = InPlayerHit;
		Headshot = InHeadshot;
		Distance = InDistance;
		Location = InLocation;
		HitActor = InHitActor;
		HitAgent = InHitPlayer;
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
	UPROPERTY()
	EEquipSpeed Speed;
	UPROPERTY()
	bool Reload;

	/**
	 * If greater than zero, sets the gun's current ammo to this value (clamped to max ammo).
	 */
	UPROPERTY()
	int Ammo;

	/**
	 * If greater than zero, sets the gun's reserve ammo to this value (clamped to max reserve ammo).
	 */
	UPROPERTY()
	int ReserveAmmo;

	FEquipData(EEquipSpeed InSpeed, bool InReload = false, int InAmmo = -1, int InReserveAmmo = -1)
	{
		Speed = InSpeed;
		Reload = InReload;
		Ammo = InAmmo;
		ReserveAmmo = InReserveAmmo;
	}
}
