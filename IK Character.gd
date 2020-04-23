# IK Character.gd
# Procedural Walking Demo
# Jessie Hildebrandt

# TODO: Genericize this, work on better ragdolling solution
# TODO: Clean up foot + foot target code, remove hard node path references

extends Spatial

##########
# Exported variables

export(NodePath) var FLFootTargetPath: NodePath
export(NodePath) var FRFootTargetPath: NodePath
export(NodePath) var BRFootTargetPath: NodePath
export(NodePath) var BLFootTargetPath: NodePath

##########
# Global variables

var FLFoot: Position3D = null
var FRFoot: Position3D = null
var BRFoot: Position3D = null
var BLFoot: Position3D = null

var FLFootTarget: Spatial = null
var FRFootTarget: Spatial = null
var BRFootTarget: Spatial = null
var BLFootTarget: Spatial = null

var ready: bool = false
var ragdoll: bool = false

##########
# enable_ragdoll
# Disables IK calculation and enables ragdoll physics

func enable_ragdoll():
	
	# Stop if already ragdolled
	if (ragdoll):
		return
	
	# Set flag to stop physics processing
	ragdoll = true
	
	# Stop IK calculations
	get_node("Armature/Skeleton/BL Leg IK").stop()
	get_node("Armature/Skeleton/FL Leg IK").stop()
	get_node("Armature/Skeleton/BR Leg IK").stop()
	get_node("Armature/Skeleton/FR Leg IK").stop()
	
	# Start ragdoll calculations
	get_node("Armature/Skeleton").physical_bones_start_simulation()

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():
	
	# Fetch nodes from node paths
	FLFoot = get_node("Armature/Skeleton/FL Foot Target")
	FRFoot = get_node("Armature/Skeleton/FR Foot Target")
	BRFoot = get_node("Armature/Skeleton/BR Foot Target")
	BLFoot = get_node("Armature/Skeleton/BL Foot Target")
	FLFootTarget = get_node(FLFootTargetPath)
	FRFootTarget = get_node(FRFootTargetPath)
	BRFootTarget = get_node(BRFootTargetPath)
	BLFootTarget = get_node(BLFootTargetPath)
	
	# Start IK calculations
	get_node("Armature/Skeleton/BL Leg IK").start()
	get_node("Armature/Skeleton/FL Leg IK").start()
	get_node("Armature/Skeleton/BR Leg IK").start()
	get_node("Armature/Skeleton/FR Leg IK").start()
	
	# Set ready flag to begin physics processing
	ready = true

##########
# _physics_process
# Called every physics frame

func _physics_process(delta):
	
	# Stop if not ready (or if we're ragdolled)
	if (!ready || ragdoll):
		return
	
	# Move every foot control node to the position of the foot target nodes
	FLFoot.global_transform.origin = FLFootTarget.global_transform.origin
	FRFoot.global_transform.origin = FRFootTarget.global_transform.origin
	BRFoot.global_transform.origin = BRFootTarget.global_transform.origin
	BLFoot.global_transform.origin = BLFootTarget.global_transform.origin
