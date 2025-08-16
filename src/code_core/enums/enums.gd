extends Node

class_name Enums

enum speed_level {
	Idle = 0,
	Slow = 100,
	Normal = 200,
	Fast = 300,
	VeryFast = 400
}

enum dragoon_type {
	Egg,
	Long,
	Regular,
	Chonky
}

enum distance_level {
	Close = 5,
	Near = 10,
	Mid = 15,
	Far = 20,
	Distant = 25,
}

enum hit_zone {
	Head,
	Body,
}

enum ground_levels {
	ForeGround = 1060,
	MidGround = 990,
	BackGround = 930,
}

enum fly_zone_lane {
	Hover = 800,
	Jump = 600,
	HighRise = 400,
	Fly = 250,
}

enum sfx_type {
	Shot,
	Hit,
	Reload,
	Spawn,
	Click,
	StartAlarm,
	EndAlarm,
}
