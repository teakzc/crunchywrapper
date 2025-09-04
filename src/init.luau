--!optimize 2
--!native
--!strict

local crunchyroll = require("./roblox_packages/crunchyroll")

local R6Rig = crunchyroll.create_rig({
	name = "Torso",

	c0 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
	c1 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),

	children = {
		{
			name = "Neck",
			c0 = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
			c1 = CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
		},
		{
			name = "Left Hip",
			c0 = CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
			c1 = CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		},
		{
			name = "Right Hip",
			c0 = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
			c1 = CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
		},
		{
			name = "Left Shoulder",
			c0 = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
			c1 = CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		},
		{
			name = "Right Shoulder",
			c0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
			c1 = CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
		},
	},
})

local function ExpLerp(a: number, b: number, t: number, k: number): number
	if k == 0 then -- Math limits workaround
		return a + (b - a) * t -- return to linear.........
	end

	local Curve = 1 - math.exp(-k * t)
	local Max = 1 - math.exp(-k)

	Curve = Curve / Max

	return a + (b - a) * Curve
end

export type IncompleteAnimationTrack = {
	-- 0-1
	alpha: number,

	-- 0-1
	start_fade_time: number?,
	stop_fade_time: number?,
	weight: number,

	-- arbitrary number
	priority: number,
}

export type CustomData = {
	Looped: boolean,
	ExponentCurve: number,
	End: boolean?,
	Speed: number?,
	FadeIn: number?,
	FadeOut: number?,
	FadeInElapsed: number?,
	FadeOutElapsed: number?,
	FadeOutForce: number?,
	OriginalWeight: number?,
}

export type AnimationData = IncompleteAnimationTrack & CustomData

export type CompleteAnimationData = crunchyroll.AnimationTrack & CustomData & { OriginalWeight: number }

export type selfprops = {
	Character: Model,
	Animations: { [crunchyroll.AnimationAsset]: CompleteAnimationData },
	Rig: crunchyroll.Rig,
	Motor6D: { [string]: Motor6D },
}

local animation = {}
animation.__index = animation

export type animation = typeof(animation)

function animation.new(Character: Model, Rig: crunchyroll.Rig): self
	local NameExchange = {
		["Left Shoulder"] = "Left Arm",
		["Left Hip"] = "Left Leg",
		["Right Shoulder"] = "Right Arm",
		["Right Hip"] = "Right Leg",
		["Neck"] = "Head",
		["RootJoint"] = "Torso",
	}

	local self = setmetatable(
		{
			Character = Character,
			Animations = {},
			Rig = Rig,
			Motor6D = {},
		} :: selfprops,
		animation
	)

	local Torso = Character:FindFirstChild("Torso")
	local HRP = Character:FindFirstChild("HumanoidRootPart")

	if Torso ~= nil and HRP ~= nil then
		for _, v: Instance in Torso:GetChildren() do
			if v:IsA("Motor6D") then
				self.Motor6D[NameExchange[v.Name]] = v
			end
		end

		self.Motor6D["Torso"] = (HRP :: any).RootJoint
	else
		error("HumanoidRootPart and Torso not found!")
	end

	return self
end

export type self = typeof(animation.new(Instance.new("Model"), R6Rig))

function animation.AddTrack(
	self: self,
	AnimationAsset: crunchyroll.AnimationAsset,
	Data: AnimationData,
	Fade: number?,
	FadeOut: number?
)
	Data.start_fade_time = 0
	Data.stop_fade_time = 0
	Data.OriginalWeight = Data.weight
	Data.End = nil

	if self.Animations[AnimationAsset] == nil then
		if Fade then
			Data.FadeIn = Fade
			Data.FadeInElapsed = 0
			Data.weight = 0
		end

		if FadeOut then
			Data.FadeOut = FadeOut
			Data.FadeOutElapsed = 0
		end

		self.Animations[AnimationAsset] = Data :: CompleteAnimationData
	end
end

--[=[
	Note that removing a track with a fade out time will only work if there is remaning track or if the track is looped.
]=]
function animation.RemoveTrack(self: self, AnimationAsset: crunchyroll.AnimationAsset, Fade: number)
	if self.Animations[AnimationAsset] then
		local Track = self.Animations[AnimationAsset]

		local LengthS = AnimationAsset.length --Length Seconds

		local FadeAlpha = Fade / LengthS -- Fade sec over length sec is fade alpha
		local RemainingAlpha = 1 - Track.alpha

		if RemainingAlpha <= FadeAlpha then -- There is enough time
			Track.FadeOut = Fade
		else
			Track.FadeOut = LengthS - (LengthS * Track.alpha)
		end

		Track.End = true
		Track.FadeOutElapsed = 0
		Track.weight = Track.OriginalWeight
	end
end

function animation.ForceRemoveTrack(self: self, AnimationAsset: crunchyroll.AnimationAsset)
	if self.Animations[AnimationAsset] then
		self.Animations[AnimationAsset] = nil
	end
end

function animation.UpdateMotor(self: self)
	local Motors = self.Motor6D
	for Name: string, CF: CFrame in self.Rig.result_coordinate_frames do
		if Name == "root" then
			continue
		end

		local Motor = Motors[Name]
		Motor.Transform = CF --NewCF
	end
end

function animation.Stepped(self: self, dT: number, UpdateMotor6: boolean?)
	for Asset, Track in self.Animations do
		local Length = Asset.length -- in seconds
		local dT2 = dT * (Track.Speed or 1)

		local NewAlpha = Track.alpha + (dT2 / Length)

		if NewAlpha >= 1 and not Track.Looped then
			--Remove track
			self.Animations[Asset] = nil
			continue
		end

		Track.alpha = NewAlpha % 1

		-- Configure weight

		if Track.FadeIn and Track.FadeInElapsed then
			Track.weight = ExpLerp(0, Track.OriginalWeight, Track.FadeInElapsed / Track.FadeIn, -Track.ExponentCurve)
			Track.FadeInElapsed += dT2

			if Track.FadeInElapsed >= Track.FadeIn then --Stop
				Track.FadeIn = nil
				Track.FadeInElapsed = nil
			end
		end

		if Track.FadeOut and Track.FadeOutElapsed and Track.End ~= true then --:AddTrack()
			local RemainingAlpha = 1 - NewAlpha
			local FadeAlpha = Track.FadeOut / Length

			if FadeAlpha >= RemainingAlpha then --Starting!
				Track.weight =
					ExpLerp(Track.OriginalWeight, 0, Track.FadeOutElapsed / Track.FadeOut, Track.ExponentCurve) --Lerp(Track.OriginalWeight, 0, Track.FadeOutElapsed / Track.FadeOut)
				Track.FadeOutElapsed += dT2

				if Track.FadeOutElapsed >= Track.FadeOut then --Stop
					Track.FadeOut = nil
					Track.FadeOutElapsed = nil

					self.Animations[Asset] = nil
				end
			end
		elseif Track.FadeOut ~= nil and Track.FadeOutElapsed ~= nil and Track.End == true then --force ended
			Track.weight = ExpLerp(Track.OriginalWeight, 0, Track.FadeOutElapsed / Track.FadeOut, Track.ExponentCurve) --Lerp(Track.OriginalWeight, 0, Track.FadeOutElapsed / Track.FadeOut)
			Track.FadeOutElapsed += dT2

			if Track.FadeOutElapsed >= Track.FadeOut then --Stop
				Track.FadeOut = nil
				Track.FadeOutElapsed = nil

				self.Animations[Asset] = nil
			end
		end
	end

	crunchyroll.solve_animation(self.Rig, self.Animations)

	if UpdateMotor6 == true then
		self:UpdateMotor()
	end
end

return animation
