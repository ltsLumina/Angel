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

struct FEquipParams
{
	UPROPERTY()
	EEquipSpeed Speed;
	UPROPERTY()
	bool Reload;
	UPROPERTY()
	int Ammo;
	UPROPERTY()
	int ReserveAmmo;

	FEquipParams(EEquipSpeed InSpeed, bool InReload = false, int InAmmo = -1, int InReserveAmmo = -1)
	{
		Speed = InSpeed;
		Reload = InReload;
		Ammo = InAmmo;
		ReserveAmmo = InReserveAmmo;
	}
}
