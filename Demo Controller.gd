# Demo Controller.gd
# Procedural Walking Demo
# Jessie Hildebrandt

extends Node

##########
# Constants

const MENU_SCENE_PATH: String = "res://Demo Menu/Demo Menu.tscn"

const CHASE_CAMERA_PATH: String = "res://Rigged Characters/Rig Components/Chase Camera.tscn"
const DESTINATION_BEACON_PATH: String = "res://Rigged Characters/Rig Components/Destination Beacon.tscn"

##########
# Global variables

var current_scene: Node = null
var current_rig: KinematicBody = null

##########
# load_demo_with_rig
# Load into a new demo scene with the provided character rig

func load_demo_with_rig(demo_path, rig_path) -> void:
	call_deferred("_deferred_load_demo_with_rig", demo_path, rig_path)

func _deferred_load_demo_with_rig(demo_path, rig_path) -> void:

	# Remove the current scene
	current_scene.free()

	# Load and instance new demo scene
	var new_scene = ResourceLoader.load(demo_path)
	current_scene = new_scene.instance()

	# Add instanced scene to the root of the current tree
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

	# Load and instance selected rig and rig components
	current_rig = ResourceLoader.load(rig_path).instance()
	var chase_camera = ResourceLoader.load(CHASE_CAMERA_PATH).instance()
	var destination_beacon = ResourceLoader.load(DESTINATION_BEACON_PATH).instance()
	current_rig.destination_point = destination_beacon

	# Set appropriate positions for each component
	current_rig.global_transform.origin = Vector3(0, 3, 0)
	chase_camera.global_transform.origin = Vector3(0, 13, 6)

	# Add instanced rig and components to the loaded demo scene
	current_scene.add_child(current_rig)
	current_scene.add_child(chase_camera)
	current_scene.add_child(destination_beacon)

##########
# load_menu
# Load the menu scene

func load_menu() -> void:
	call_deferred("_deferred_load_menu")

func _deferred_load_menu() -> void:

	# Remove the current scene
	current_scene.free()

	# Load and instance the menu scene
	var new_scene = ResourceLoader.load(MENU_SCENE_PATH)
	current_scene = new_scene.instance()

	# Add instanced scene to the root of the current tree
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

	# Remove reference to rig (removed with the last scene)
	current_rig = null

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

##########
# _input
# Captures user input

func _input(event):

	# Capture 'R' keypresses to reset the scene
	if event is InputEventKey and event.scancode == KEY_R:
		load_menu()
