# Demo Select Button.gd
# Procedural Walking Demo
# Jessie Hildebrandt

extends Button

##########
# Exported variables

# target_demo_file: The filepath of the demo environment that this button will load
export(String, FILE) var target_demo_file

# target_rig_file: The filepath of the character rig that this button will load
export(String, FILE) var target_rig_file

##########
# _on_Button_pressed
# Called when the user activates the Button node

func _pressed() -> void:
	DemoController.load_demo_with_rig(target_demo_file, target_rig_file)
