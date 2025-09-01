--!optimize 2
local animation_asset = require("./roblox/animation_asset")
local create_rig = require("./rig")

export type AnimationTrack = {
	-- 0-1
	alpha: number,

	-- 0-1
	start_fade_time: number,
	stop_fade_time: number,
	weight: number,

	-- arbitrary number
	priority: number,
}

local function number_lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function vector_lerp(a: vector, b: vector, t: number): vector
	return a + (b - a) * t
end

local function quat_nlerp(
	a_vector: vector,
	a_scalar: number,
	b_vector: vector,
	b_scalar: number,
	t: number
): (vector, number)
	local quat_vector = vector_lerp(a_vector, b_vector, t)
	local quat_scalar = number_lerp(a_scalar, b_scalar, t)

	local magnitude =
		math.sqrt((vector.dot(quat_vector, quat_vector) + (quat_scalar * quat_scalar)))

	return quat_vector / magnitude, quat_scalar / magnitude
end

local function solve_fade_time_influence(
	real_time: number,
	animation_length: number,
	start_fade_time: number,
	stop_fade_time: number
): number
	if real_time <= start_fade_time then
		return math.min(1, 1 - ((start_fade_time - real_time) / start_fade_time))
	elseif real_time >= (animation_length + stop_fade_time) then
		return math.min(
			1,
			1 - ((real_time - (animation_length - stop_fade_time)) / stop_fade_time)
		)
	else
		return 1
	end
end

local function animation_solver(
	rig: create_rig.Identity,
	tracks: {
		[animation_asset.Identity]: AnimationTrack,
	} --,
	--root: CFrame
)
	local limb_transforms = rig._limb_transforms
	for _, limb in limb_transforms do
		limb.priority = -1
	end

	local total_weight = 0
	for _, track in tracks do
		total_weight += track.weight
	end

	for animation, playback in tracks do
		local priority = playback.priority
		local real_time = animation.length * playback.alpha
		local influence = (playback.weight / total_weight)
			* solve_fade_time_influence(
				real_time,
				animation.length,
				playback.start_fade_time,
				playback.stop_fade_time
			)

		-- Figure out which keyframes to interpolate between
		local time_after: number?
		local time_before: number?
		local poses_after: animation_asset.Poses?
		local poses_before: animation_asset.Poses?
		local keyframe_times = animation.keyframe_times

		local high: number = #keyframe_times
		local low: number = 1

		while high > low do
			local index: number = bit32.rshift(low + high, 1)

			if keyframe_times[index + 1] >= real_time then
				high = index
			else
				low = index + 1
			end
		end

		time_after = keyframe_times[high]
		time_before = keyframe_times[high - 1]
		poses_after = animation.keyframe_poses[high]
		poses_before = animation.keyframe_poses[high - 1]

		-- Solve limb transforms
		for index, node in limb_transforms do
			if node.priority > priority then
				continue
			end

			local left_pose: animation_asset.PoseNode? = poses_before and poses_before[index]
			local right_pose: animation_asset.PoseNode? = poses_after and poses_after[index]
			local left_or_right = left_pose or right_pose

			--stylua: ignore start
			if left_pose and right_pose then
				local alpha = left_pose.easing_function((real_time - (time_before :: number)) / ((time_after :: number) - (time_before :: number)))
				local position = vector_lerp(left_pose.position, right_pose.position, alpha)
				
				local quat_vector, quat_scalar = quat_nlerp(
					left_pose.quat_vector, left_pose.quat_scalar,
					right_pose.quat_vector, right_pose.quat_scalar,
					alpha
				)
				
				node.position = vector_lerp(node.position, position, influence)
				node.quat_vector, node.quat_scalar = quat_nlerp(
					node.quat_vector, node.quat_scalar, 
					quat_vector, quat_scalar, 
					influence
				)

				node.priority = priority
			elseif left_or_right then
				node.position = vector_lerp(node.position, left_or_right.position, influence)
				node.quat_vector, node.quat_scalar = quat_nlerp(
					node.quat_vector, node.quat_scalar, 
					left_or_right.quat_vector, left_or_right.quat_scalar, influence
				)
				node.priority = priority
			end
			--stylua: ignore end
		end
	end

	local result_coordinate_frames: { [string]: CFrame } = rig.result_coordinate_frames
	--result_coordinate_frames["root"] = root

	for index, limb in rig._limbs do
		local limb_transform = limb_transforms[index]

		local position = limb_transform.position
		local quat_vector = limb_transform.quat_vector
		local quat_scalar = limb_transform.quat_scalar

		--stylua: ignore
		local transform = CFrame.new(
			position.x, position.y, position.z,
			quat_vector.x, quat_vector.y, quat_vector.z, quat_scalar
		)

		result_coordinate_frames[limb.name] = transform -- this is for motor6ds --result_coordinate_frames[limb.depends_on]
		--* limb.c0
		--* transform
		--* limb.c1
	end
end

return {
	solve_fade_time_influence = solve_fade_time_influence,

	solver = animation_solver,
}
