# Kinematic Skeleton Controller.gd
# Procedural Walking Demo
# Jessie Hildebrandt

# This script assumes that the node that it is attached to is facing forward (-Z)
# relative to movement direction.

extends KinematicBody

##########
# SkeletonFoot class
# Stores essential information for each foot of the skeleton

class SkeletonFoot:
	var origin_point_node: Spatial = null
	var ik_controller_node: SkeletonIK = null
	var target_visualizer_node: MeshInstance = null
	var ray_cast_node: RayCast = null
	var target_vec: Vector3 = Vector3()
	var moving: bool = false

##########
# Exported variables

# Character Controller Parameters

# destination_point_path: The node toward which the character will move
export(NodePath) var destination_point_path: NodePath = NodePath()

# walking_speed: The speed at which the character will move forwards
export(float) var walking_speed: float = 3

# character_height: The distance above the ground at which the character will rest
export(float) var character_height: float = 1.25

# height_adjust_speed: The speed at which the character's body will adjust its vertical position
export(float) var height_adjust_speed: float = 0.2

# Skeletal Walking System Parameters

# stagger_factor: How many groups the feet should be organized into for staggering steps
export(int) var stagger_factor: int = 2

# stagger_time: The amount of time that should pass before attempting to process the next foot group's step
export(float) var stagger_time: float = 0.2

# target_visuals_enabled: Whether or not to draw visualizations for the target points
export(bool) var target_visuals_enabled: bool = false

# ragdolling_enabled: Whether or not the skeleton should ragdoll when footing is lost
export(bool) var ragdolling_enabled: bool = false

# ragdoll_fall_threshold: How many footing positions should be lost to trigger ragdolling
export(int) var ragdoll_fall_threshold: int = 2

# step_speed: The speed at which the feet are moved to their targets
export(float) var step_speed: float = 0.2

# step_distance: The minimum distance required to take a step is taken
export(float) var step_distance: float = 2

# step_up_height: The height below which the skeleton will look for a steppable surface
export(float) var step_up_height: float = 2

# step_down_depth: The depth above which the skeleton will look for a steppable surface
export(float) var step_down_depth: float = 2

# skeleton_path: The skeleton of the rig that this script will be influencing
export(NodePath) var skeleton_path: NodePath = NodePath()

# foot_point_paths: The nodes that represent where the skeleton's feet should be
#                   (The nodes should begin at the initial resting position of each foot)
#                   (The nodes should go from left to right, front to back of the skeleton)
export(Array, NodePath) var foot_point_paths: Array = []

# foot_ik_controller_paths: The IK nodes that control the IK status of the skeleton's feet
export(Array, NodePath) var foot_ik_controller_paths: Array = []

##########
# Global variables

# Foot data
var stagger_timer: float = 0
var current_foot_group_index: int = 0
var foot_groups: Array = []

# Exported nodes
var destination_point: Spatial = null
var skeleton: Skeleton = null

# Locally created nodes
var ground_ray_cast: RayCast = null

# Ragdoll state
var ragdolled: bool = false

##########
# flatten_vec3
# Neutralizes the 'y' component of a Vector3

func flatten_vec3(vec: Vector3) -> Vector3:
	vec.y = 0
	return vec

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready() -> void:

	# Sanity check time!
	if !destination_point_path:
		push_error("Destination point NodePath not set!")
		get_tree().quit()
	if !skeleton_path:
		push_error("Skeleton NodePath not set!")
		get_tree().quit()
	if foot_point_paths.size() == 0 or foot_ik_controller_paths.size() == 0:
		push_error("Feet NodePaths not set!")
		get_tree().quit()
	if foot_point_paths.size() != foot_ik_controller_paths.size():
		push_error("Mismatched number of IK controllers and feet for skeleton!")
		get_tree().quit()

	# Fetch nodes from node paths
	destination_point = get_node(destination_point_path)
	skeleton = get_node(skeleton_path)

	# Create a foot group for each group of feet
	for i in range(stagger_factor):
		foot_groups.append([])

	# Construct a SkeletonFoot entry for each foot on the skeleton
	var group_index = 0
	var num_feet = foot_point_paths.size()
	for i in range(num_feet):

		# Set up the foot and its origin and SkeletonIK nodes
		var new_foot: SkeletonFoot = SkeletonFoot.new()
		new_foot.origin_point_node = get_node(foot_point_paths[i])
		new_foot.ik_controller_node = get_node(foot_ik_controller_paths[i])

		# Create a RayCast node above the origin point for the foot
		var new_ray_cast: RayCast = RayCast.new()
		add_child(new_ray_cast)
		new_ray_cast.cast_to = Vector3(0, -(character_height + step_up_height + step_down_depth), 0)
		new_ray_cast.enabled = true
		new_ray_cast.global_transform.origin = new_foot.origin_point_node.global_transform.origin + Vector3(0, step_up_height, 0)
		new_foot.ray_cast_node = new_ray_cast

		# Generate a target vector visualizer for the node (if visualization is enabled)
		if target_visuals_enabled:
			var new_mesh_instance: MeshInstance = MeshInstance.new()
			add_child(new_mesh_instance)
			new_mesh_instance.mesh = SphereMesh.new()
			new_mesh_instance.mesh.radius = 0.25
			new_mesh_instance.mesh.height = 0.25
			new_foot.target_visualizer_node = new_mesh_instance

		# Set the target vector and start the IK simulation for the foot
		new_foot.target_vec = new_foot.origin_point_node.global_transform.origin
		new_foot.ik_controller_node.start()

		# Place this foot in the appropriate group and advance the group index
		foot_groups[group_index].append(new_foot)
		group_index += 1
		if group_index >= foot_groups.size():
			group_index = 0

	# Create a RayCast node in the center of the character for ground detection
	ground_ray_cast = RayCast.new()
	add_child(ground_ray_cast)
	ground_ray_cast.cast_to = Vector3(0, -(step_up_height + step_down_depth + character_height), 0)
	ground_ray_cast.enabled = true
	ground_ray_cast.global_transform.origin = global_transform.origin + Vector3(0, step_up_height, 0)

##########
# process_stepping
# Handles the logic of processing the skeletal model's stepping motion

func process_stepping(delta) -> void:

	# Advance the stagger timer
	stagger_timer += delta

	# Update every foot in the model
	var num_feet_dangling: int = 0
	for group in foot_groups:
		for foot in group:

			# Check that the ray cast node isn't finding a valid collision point
			if not foot.ray_cast_node.is_colliding():
				num_feet_dangling += 1

			# Update where the ray cast node is located (it should be moved out toward the walking direction)
			foot.ray_cast_node.transform.origin = foot.origin_point_node.transform.origin + Vector3(0, (step_up_height + character_height), 0) + flatten_vec3(global_transform.origin.direction_to(destination_point.global_transform.origin)) * step_distance / 2

			# Move each foot toward its current target
			var new_target_transform: Transform = foot.ik_controller_node.get_target_transform()
			new_target_transform.origin += (foot.target_vec - new_target_transform.origin) * step_speed
			foot.ik_controller_node.set_target_transform(new_target_transform)

			# Update the position of the target visualizer (if enabled)
			if target_visuals_enabled:
				foot.target_visualizer_node.global_transform.origin = foot.target_vec

	# If it's not time to process the next step yet, return
	if stagger_timer < stagger_time:
		return
	stagger_timer = 0

	# If it's time to step but too many feet are dangling and the ground isn't here, go ragdoll
	if num_feet_dangling >= ragdoll_fall_threshold and not ground_ray_cast.is_colliding():
		for group in foot_groups:
			for foot in group:
				foot.ik_controller_node.stop()
		skeleton.physical_bones_start_simulation()
		ragdolled = true

	# Process target vector changes for each foot in the current foot group
	for foot in foot_groups[current_foot_group_index]:

		# Calculate new target vector if step distance is large enough or if we're standing still (close to destination)
		var potential_step_distance: float = foot.target_vec.distance_to(foot.ray_cast_node.get_collision_point())
		var distance_to_destination: float = global_transform.origin.distance_to(destination_point.global_transform.origin)
		if potential_step_distance > step_distance or distance_to_destination < character_height:
			foot.target_vec = foot.ray_cast_node.get_collision_point()

	# Advance the current foot group index
	current_foot_group_index += 1
	if current_foot_group_index >= foot_groups.size():
		current_foot_group_index = 0

##########
# process_character_movement
# Handles the logic of processing the character controller's movement

func process_character_movement(delta) -> void:

	# Calculate average height between all leg points (and ground point)
	var avg_ground_height: float = 0
	var num_feet: int = 0
	for group in foot_groups:
		num_feet += group.size()
		for foot in group:
			avg_ground_height += foot.ik_controller_node.get_target_transform().origin.y
	avg_ground_height += ground_ray_cast.get_collision_point().y
	avg_ground_height /= num_feet + 1

	# Calculate what the current height of the character's body should be
	var new_height = max(avg_ground_height, ground_ray_cast.get_collision_point().y) + character_height

	# Linearly interpolate the character body towards its new height
	global_transform.origin.y += (new_height - global_transform.origin.y) * height_adjust_speed

	# Move the character toward the destination point
	move_and_slide(global_transform.origin.direction_to(destination_point.global_transform.origin) * walking_speed)

##########
# _physics_process
# Called every physics frame

func _physics_process(delta) -> void:
	if ragdolled:
		return
	process_stepping(delta)
	process_character_movement(delta)
