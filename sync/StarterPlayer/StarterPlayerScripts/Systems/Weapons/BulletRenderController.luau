local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PartCache = require(ReplicatedStorage.Utils.PartCache)

local cache = PartCache.new(ReplicatedStorage.Assets.Bullet, 20)

local activeBullets = {}

local BulletRenderController = Knit.CreateController({ Name = "BulletRenderController" })

function BulletRenderController:KnitStart()
	RunService.RenderStepped:Connect(function()
		for bullet, bulletInfo in activeBullets do
			local startPos = bulletInfo.StartPosition
			local endPos = bulletInfo.EndPosition

			local distance = (endPos - startPos).Magnitude

			bullet.Size = Vector3.new(bullet.Size.X, bullet.Size.Y, distance)
			bullet:PivotTo(CFrame.new(startPos, endPos) * CFrame.new(0, 0, -distance * 0.5))
		end
	end)

	Knit.GetService("WeaponService").FireBullet:Connect(function(startPos: Vector3, endPos: Vector3)
		self:RenderBullet(startPos, endPos)
	end)
end

function BulletRenderController:KnitInit() end

function BulletRenderController:RenderBullet(startPos: Vector3, endPos: Vector3)
	local bullet = cache:GetPart()

	activeBullets[bullet] = {
		StartPosition = startPos,
		EndPosition = endPos,
	}

	task.delay(0.1, function()
		activeBullets[bullet] = nil
		cache:ReturnPart(bullet)
	end)
end

return BulletRenderController
