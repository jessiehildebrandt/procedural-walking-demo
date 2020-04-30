# Kinematic Skeleton Controller.gd
# Procedural Walking Demo
# Jessie Hildebrandt

# This script assumes that the node that it is attached to is facing forward (-Z)
# relative to movement direction.

extends KinematicBody

##########
# Exported variables

# Character Controller Parameters

# destination_point_path: The node toward which the character will move
export(NodePath) var destination_point_path: NodePath = NodePath()

# walking_speed: The speed at which the character will move forwards
export(float) var walking_speed: float = 3

# turning_speed: The speed at which the character will turn
export(float) var turning_speed: float = 0.025

# character_height: The distance above the ground at which the character will rest
export(float) var character_height: float = 1.25

# height_adjust_speed: The speed at which the character's body will adjust its vertical position
export(float) var height_adjust_speed: float = 0.2

# Skeletal Walking System Parameters

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
export(Array, NodePath) var foot_point_paths: Array = []

# foot_ik_controller_paths: The IK nodes that control the IK status of the skeleton's feet
export(Array, NodePath) var foot_ik_controller_paths: Array = []

##########
# Global variables

# Exported nodes
var destination_point: Spatial = null
var skeleton: Skeleton = null
var foot_points: Array = []
var foot_ik_controllers: Array = []

# Locally created nodes
var ground_ray_cast: RayCast = null
var foot_ray_casts: Array = []
var foot_target_visualizers: Array = []

# Target vectors
var foot_target_vecs: Array = []

# Ragdoll state
var ragdolled: bool = false

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():

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
	for node_path in foot_point_paths:
		foot_points.append(get_node(node_path))
	for node_path in foot_ik_controller_paths:
		foot_ik_controllers.append(get_node(node_path))

	# Start up IK controllers
	for ik_controller in foot_ik_controllers:
		ik_controller.start()

	# Create a RayCast node above each foot point on the skeleton
	for foot_point in foot_points:
		var new_ray_cast: RayCast = RayCast.new()
		add_child(new_ray_cast)
		new_ray_cast.cast_to = Vector3(0, -(step_up_height + step_down_depth), -step_distance / 2)
		new_ray_cast.enabled = true
		new_ray_cast.global_transform.origin = foot_point.global_transform.origin + Vector3(0, step_up_height, 0)
		foot_ray_casts.append(new_ray_cast)

	# Set the initial target vector for each foot
	for index in range(foot_points.size()):
		foot_target_vecs.append(foot_points[index].global_transform.origin)

	# Create a RayCast node in the center of the character for ground detection
	ground_ray_cast = RayCast.new()
	add_child(ground_ray_cast)
	ground_ray_cast.cast_to = Vector3(0, -(step_up_height + step_down_depth), 0)
	ground_ray_cast.enabled = true
	ground_ray_cast.global_transform.origin = global_transform.origin + Vector3(0, step_up_height, 0)

	# Generate the target point visualizers (if visualization is enabled)
	if target_visuals_enabled:
		for foot_point in foot_points:
			var new_mesh_instance: MeshInstance = MeshInstance.new()
			foot_point.add_child(new_mesh_instance)
			new_mesh_instance.mesh = SphereMesh.new()
			new_mesh_instance.mesh.radius = 0.25
			new_mesh_instance.mesh.height = 0.25
			foot_target_visualizers.append(new_mesh_instance)

##########
# _physics_process
# Called every physics frame

func _physics_process(delta):

	# Calculate current distance of each potential step and move the target vector if the distance is large enough
	var moved_foot: bool = false
	for index in range(foot_target_vecs.size()):
		var potential_step_distance: float = foot_target_vecs[index].distance_to(foot_ray_casts[index].get_collision_point())
		if !moved_foot and potential_step_distance > step_distance:
			foot_target_vecs[index] = foot_ray_casts[index].get_collision_point()
			moved_foot = true

	# Linearly interpolate each foot point over towards its target point
	for index in range(foot_points.size()):
		foot_points[index].global_transform.origin += (foot_target_vecs[index] - foot_points[index].global_transform.origin) * step_speed

	# Point the IK controller nodes towards their respective foot points
	for index in range(foot_ik_controllers.size()):
		foot_ik_controllers[index].set_target_transform(foot_points[index].global_transform)

	# Calculate average height between all leg points (and ground point)
	var avg_ground_height: float = 0
	for foot_point in foot_points:
		avg_ground_height += foot_point.global_transform.origin.y
	avg_ground_height += ground_ray_cast.get_collision_point().y
	avg_ground_height /= foot_points.size() + 1

	# Calculate what the current height of the character's body should be
	var new_height = max(avg_ground_height, ground_ray_cast.get_collision_point().y) + character_height

	# Linearly interpolate the character body towards its new height
	global_transform.origin.y += (new_height - global_transform.origin.y) * height_adjust_speed

	# Move the character toward the destination point
	move_and_slide(global_transform.origin.direction_to(destination_point.global_transform.origin) * walking_speed)
#	global_transform.origin.x += (destination_point.global_transform.origin.x - global_transform.origin.x) * walking_speed
#	global_transform.origin.z += (destination_point.global_transform.origin.z - global_transform.origin.z) * walking_speed

	# Always draw "current point" at collision point of ray_cast
#	current_point.global_transform.origin = ray_cast.get_collision_point()

	# Calculate current size of step and move "target point" if step size is large enough
	# var step_distance: float = current_point.global_transform.origin.distance_to(target_point_vec);
	# if step_distance > step_size:
	# 	target_point_vec = current_point.global_transform.origin

	# Linearly interpolate "target point" over towards where it should be (target point vector)
#	target_point.global_transform.origin += (target_point_vec - target_point.global_transform.origin) * snap_speed
