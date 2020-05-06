# Destination Beacon.gd
# Procedural Walking Demo
# Jessie Hildebrandt

extends Spatial

##########
# Constants

# CLICK_RAY_LENGTH: Length of the ray cast from the camera when the mouse is clicked
const CLICK_RAY_LENGTH: float = 1000.0

##########
# Exported variables

# visual_indicator_path: Some sort of visual indicator node (MeshInstance) for the beacon to animate
export(NodePath) var visual_indicator_path: NodePath = NodePath()

# indicator_spin_speed: The speed at which the visual indicator spins
export(float) var indicator_spin_speed: float = 0.025

# indicator_visible_seconds: The amount of time for which the visual indicator is visible
export(float) var indicator_visible_seconds: float = 1

##########
# Global variables

var display_timer: float = 0
var visual_indicator: Spatial = null

##########
# _ready
# Called when the node enters the scene tree for the first time

func _ready():

	# Sanity check time!
	if !visual_indicator_path:
		push_error("Visual indicator NodePath not set!")
		get_tree().quit()

	# Fetch nodes from node paths
	visual_indicator = get_node(visual_indicator_path)

##########
# _input
# Captures user input

func _input(event):

	# Only capture mouse clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:

		# Calculate 'from' and 'to' points for casting the ray
		var camera = get_viewport().get_camera()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * CLICK_RAY_LENGTH

		# Cast the ray and make the visual indicator visible
		var intersection = get_world().direct_space_state.intersect_ray(from, to)
		if intersection.has("position"):
			global_transform.origin = intersection.position
			display_timer = indicator_visible_seconds

##########
# _process
# Called every frame

func _process(delta):

	# Check if the indicator should be visible
	if display_timer <= 0:
		visual_indicator.hide()
		return
	visual_indicator.show()

	# Run down the display timer
	display_timer -= delta

	# Animate the visual indicator by spinning it
	visual_indicator.rotate(Vector3(0, 1, 0), indicator_spin_speed)
