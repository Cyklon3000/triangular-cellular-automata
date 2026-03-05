extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass


func _on_next_button_pressed() -> void:
    GridManager.next_generation()

func _on_play_5_button_pressed() -> void:
    pass # Replace with function body.

func _on_play_button_pressed() -> void:
    pass # Replace with function body.

func _on_pause_button_pressed() -> void:
    pass # Replace with function body.

func _on_randomize_button_pressed() -> void:
    GridManager.randomize_alife()

func _on_clear_button_pressed() -> void:
    GridManager.clear()

func _on_toggle_debug_button_pressed() -> void:
    TriangleCell.toggle_debug()
