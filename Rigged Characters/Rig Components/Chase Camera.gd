# Camera.gd
# Procedural Walking Demo
# Jessie Hildebrandt

extends Camera

##########
# Exported variables

# look_at_target_path: The target Spatial node to look at and follow
export(NodePath) var look_at_target_path: NodePath = NodePath()

# follow_distance: How far back the camera can get before moving toward the target
export(float) var follow_distance: float = 15

# follow_speed: How fast the camera should approach the target
export(float) var follow_speed: float = 0.005

##########
# Global variables

var look_at_target: Spatial = null

##########
# vec3_at_y
# Modifies the 'y' component of a Vector3

func vec3_at_y(vec: Vector3, y: float) -> Vector3:
	vec.y = y
	return vec

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():

	# Fetch nodes from node paths
	# look_at_target = get_node(look_at_target_path)
	look_at_target = DemoController.current_rig

##########
# _process
# Called every frame

func _process(delta):

	# Make the camera look at the target node
	look_at(look_at_target.global_transform.origin, Vector3(0, 1, 0))

##########
# _physics_process
# Called every physics frame

func _physics_process(delta):

	# Calculate current distance to target
	var flattened_target_location = vec3_at_y(look_at_target.global_transform.origin, global_transform.origin.y)
	var distance_to_target: float = global_transform.origin.distance_to(flattened_target_location)

	# Move the camera toward the target if it's too far from it
	if distance_to_target > follow_distance:
		global_transform.origin += (flattened_target_location - global_transform.origin) * follow_speed
