local easing_enum_map = require("./easing_enum_map")
local rig = require("../rig")

export type PoseNode = {
	position: vector,
	quat_vector: vector,
	quat_scalar: number,
	easing_function: (alpha: number) -> number,
}

export type Poses = { PoseNode }

type KeyframeNode = {
	time: number,
	poses: { [string]: PoseNode },
}

export type Identity = {
	keyframe_times: { number },
	keyframe_poses: { Poses },
	length: number,
}

local function recursive_tree_from_pose(
	keyframe: Keyframe,
	poses: { [string]: PoseNode },
	root_pose: Pose
)
	local sub_poses = root_pose:GetSubPoses() :: { Pose }

	for _, sub_pose in sub_poses do
		recursive_tree_from_pose(keyframe, poses, sub_pose)
	end

	local cframe = root_pose.CFrame
	local axis, angle = cframe:ToAxisAngle()

	local half_angle = angle / 2
	local position = cframe.Position :: any
	local quat_vector = axis * math.sin(half_angle)
	local quat_scalar = math.cos(half_angle)

	-- TODO weird type error
	poses[root_pose.Name] = {
		position = position,
		quat_vector = quat_vector,
		quat_scalar = quat_scalar,
		easing_function = easing_enum_map[root_pose.EasingStyle][root_pose.EasingDirection],
	} :: any
end

local animation_asset = {}

function animation_asset.load_keyframe_sequence(
	keyframe_sequence: KeyframeSequence,
	rig: rig.Identity
): Identity
	local keyframes = keyframe_sequence:GetKeyframes() :: { Keyframe }

	local markers = {}
	local keyframe_nodes: { KeyframeNode } = {}

	for keyframe_index, keyframe in keyframes do
		for _, marker in keyframe:GetMarkers() :: { KeyframeMarker } do
			markers[marker.Name] = keyframe_index
		end

		local poses: { [string]: PoseNode } = {}
		for _, pose_instance in keyframe:GetPoses() do
			recursive_tree_from_pose(keyframe, poses, pose_instance :: Pose)
		end

		table.insert(keyframe_nodes, {
			time = keyframe.Time,
			poses = poses,
		})
	end

	table.sort(keyframe_nodes, function(left, right)
		return left.time < right.time
	end)

	local length = keyframe_nodes[#keyframe_nodes].time
	local keyframe_times = {}
	local keyframe_poses = {}

	local limb_name_to_index = rig._limb_name_to_index
	for index, keyframe_node in keyframe_nodes do
		local mapped_poses: Poses = {}
		for name, pose in keyframe_node.poses do
			local limb_index = limb_name_to_index[name]
			if limb_index ~= nil then
				mapped_poses[limb_index] = pose
			end
		end

		keyframe_poses[index] = mapped_poses
		keyframe_times[index] = keyframe_node.time
	end

	return {
		keyframe_times = keyframe_times,
		keyframe_poses = keyframe_poses,
		length = length,
	}
end

return animation_asset
