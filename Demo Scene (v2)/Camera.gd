# Camera.gd
# Procedural Walking Demo
# Jessie Hildebrandt

extends Camera

##########
# Exported variables

export(NodePath) var look_at_target_path: NodePath

##########
# Global variables

var look_at_target: Spatial = null

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():

	# Fetch nodes from node paths
	look_at_target = get_node(look_at_target_path)

##########
# _process
# Called every frame

func _process(delta):

	# Make the camera look at the target node
	look_at(look_at_target.global_transform.origin, Vector3(0, 1, 0))
