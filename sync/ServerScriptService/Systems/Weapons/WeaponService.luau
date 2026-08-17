local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local WeaponService = Knit.CreateService {
	Name = "WeaponService";
	Client = {
		FireBullet = Knit.CreateSignal(),
	};
}


function WeaponService:KnitStart()
	
end


function WeaponService:KnitInit()
	
end

function WeaponService:FireBullet(shooter: Player?, startPos: Vector3, endPos: Vector3)
	if shooter then
		self.Client.FireBullet:FireExcept(shooter, startPos, endPos)
		return
	end

	self.Client.FireBullet:FireAll(startPos, endPos)
end


return WeaponService
