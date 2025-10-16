enum EBodyPart
{
	Head,
	Body,
	Legs
};

enum EArmorType
{
	None,
	Light,
	Heavy
};

enum EGunType
{
	Sidearm,
	SMG,
	Rifle,
	Sniper,
	Shotgun,
	Heavy
};

enum EEquipSpeed
{
	Normal,
	Fast,
	Instant
};

enum EFireMode
{
	Semi = 0,
	Burst = 1,
	Auto = 2,
};

enum EWallPenetration
{
	None = 0,
	Low = 1,
	Medium = 2,
	High = 3
};

enum EAngelMovementState
{
	Still,
	Airborne,
	Crouch,
	Run,
	Walk,
	CrouchWalk
};

enum ETeam
{
	None,
	Attackers,
	Defenders
};

enum ECreditsGrantedReason
{
	None,
	// 800¤
	StartingCredits,
	// 200¤
	Kill,
	// 300¤, Attackers only
	PlantSpike,
	// 3000¤
	RoundWin,
	/* 1900¤*
	 * Players who survive a lost round receive 1000 credits instead.
	 */
	RoundLoss,
	/* 2400¤*
	 * Players who survive a lost round receive 1000 credits instead.
	 */
	RoundLoss_2x,
	/* 2900¤*
	 * Players who survive a lost round receive 1000 credits instead.
	 */
	RoundLoss_3x_Onwards
};

enum EWinCondition
{
	// Attackers
	DefendersEliminated,
	SpikeDetonated,

	// Defenders
	AttackersEliminated,
	TimeExpired,
	SpikeDefused
};
