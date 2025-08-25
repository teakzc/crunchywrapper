local ReplicatedStorage = game:GetService("ReplicatedStorage")

local create_bench = require(ReplicatedStorage.benches.create_bench)
local rig_template = require(ReplicatedStorage.client.rig) :: any

local SAMPLES = 500
local ANIMATION_TEMPLATE = ReplicatedStorage.benches.assets.orange_justice

type Rig = { __symbol: "RigSymbol" }
type Animation = { __symbol: "AnimationSymbol" }
type Profiler = create_bench.Profiler

export type Crunchyroll = {
	create_rig: (root: typeof(rig_template)) -> Rig,
	solve_animation: (
		rig: Rig,
		animations: {
			[Animation]: {
				start_fade_time: number,
				stop_fade_time: number,

				weight: number,
				priority: number,
				alpha: number,
			},
		},
		root: CFrame
	) -> (),
	load_keyframe_sequence: (keyframe_sequence: KeyframeSequence, rig: Rig?) -> Animation,
}

local function create_entry<T...>(library: Crunchyroll): (Profiler, T...) -> ()
	local rig = library.create_rig(rig_template)
	local animation = library.load_keyframe_sequence(ANIMATION_TEMPLATE, rig)
	return function(Profiler: Profiler, ...)
		for index = 1, SAMPLES do
			library.solve_animation(rig, {
				[animation] = {
					priority = 1,

					start_fade_time = 0,
					stop_fade_time = 0,
					weight = 1,

					alpha = (index / SAMPLES),
				},
			}, CFrame.identity)
		end
	end
end

return create_entry
