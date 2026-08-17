local Scale = {}

Scale.STUDS_TO_CM = 28
Scale.CM_PER_NAUTICAL_MILE = 185_200
Scale.ARCADE_SCALE = 40 -- adjust the value so it feels fun

function Scale.studsToNauticalMiles(studs: number): number
	return (studs * Scale.STUDS_TO_CM / Scale.CM_PER_NAUTICAL_MILE) * Scale.ARCADE_SCALE
end

return Scale
