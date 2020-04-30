# Leg Kinematic.gd
# Procedural Walking Demo
# Jessie Hildebrandt

extends Spatial

##########
# Exported variables

export(float) var snap_speed: float = 0.2
export(float) var step_size: float = 2

export(NodePath) var target_point_path: NodePath
export(NodePath) var current_point_path: NodePath
export(NodePath) var ray_cast_path: NodePath

##########
# Global variables

var target_point: MeshInstance = null
var current_point: MeshInstance = null
var ray_cast: RayCast = null
var target_point_vec: Vector3 = Vector3(0,0,0)

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():
	
	# Fetch nodes from node paths
	target_point = get_node(target_point_path)
	current_point = get_node(current_point_path)
	ray_cast = get_node(ray_cast_path)
	
	# Get inital target point vector
	target_point_vec = target_point.global_transform.origin

##########
# _physics_process
# Called every physics frame

func _physics_process(delta):
	
	# Always draw "current point" at collision point of ray_cast
	current_point.global_transform.origin = ray_cast.get_collision_point()
	
	# Calculate current size of step and move "target point" if step size is large enough
	var step_distance: float = current_point.global_transform.origin.distance_to(target_point_vec);
	if step_distance > step_size:
		target_point_vec = current_point.global_transform.origin
	
	# Linearly interpolate "target point" over towards where it should be (target point vector)
	target_point.global_transform.origin += (target_point_vec - target_point.global_transform.origin) * snap_speed
