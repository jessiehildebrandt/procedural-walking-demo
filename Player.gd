# Player.gd
# Procedural Walking Demo
# Jessie Hildebrandt

# TODO: Remove hard node path references, clean up code

extends KinematicBody

##########
# Exported variables

export(float) var walking_speed: float = 2
export(float) var turning_speed: float = 0.025
export(float) var height_snap_speed: float = 0.2

export(NodePath) var ground_ray_cast_path: NodePath
export(Array, NodePath) var leg_point_paths: Array = []
export(Array, NodePath) var leg_ray_cast_paths: Array = []

##########
# Global variables

var ground_ray_cast: RayCast = null
var leg_points: Array = []
var leg_ray_casts: Array = []

var ready = false

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():
	
	# Fetch nodes from node paths
	ground_ray_cast = get_node(ground_ray_cast_path)
	for node_path in leg_point_paths:
		leg_points.append(get_node(node_path))
	for node_path in leg_ray_cast_paths:
		leg_ray_casts.append(get_node(node_path))
	
	# Set ready flag to begin physics processing
	ready = true

##########
# _physics_process
# Called every physics frame

func _physics_process(delta):
	
	# Stop if not ready
	if (!ready):
		return
	
	# If we've moved off of solid ground, become a ragdoll
	var num_legs_dangling = 0
	for leg_ray_cast in leg_ray_casts:
		if !leg_ray_cast.is_colliding():
			num_legs_dangling += 1
	if num_legs_dangling >= leg_ray_casts.size() * 0.5:
		get_node("Rig").enable_ragdoll()
		return
	
	# Handle keypresses and movement
	if (Input.is_key_pressed(KEY_W)):
		move_and_slide(-global_transform.basis.z * walking_speed)
	if (Input.is_key_pressed(KEY_A)):
		set_rotation(get_rotation() + Vector3(0, turning_speed, 0))
	if (Input.is_key_pressed(KEY_D)):
		set_rotation(get_rotation() + Vector3(0, -turning_speed, 0))
	
	# Calculate average height between all leg points (and ground point)
	var avg_ground_height = 0
	for leg_point in leg_points:
		avg_ground_height += leg_point.global_transform.origin.y
	avg_ground_height += ground_ray_cast.get_collision_point().y + 0.75
	avg_ground_height /= leg_points.size() + 1
	
	# Calculate what our new height should be
	var new_height = max(avg_ground_height + 1.25, ground_ray_cast.get_collision_point().y + 0.75)
	
	# Linearly interpolate our current height towards the desired new height
	global_transform.origin.y += (new_height - global_transform.origin.y) * height_snap_speed
