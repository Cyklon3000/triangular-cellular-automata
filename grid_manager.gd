class_name GridManager

extends Node2D

@onready var initial_cell: TriangleCell = $TriangleCell


static var current_grid_manager: GridManager = null

func _enter_tree() -> void:
    current_grid_manager = self

func _exit_tree() -> void:
    current_grid_manager = null


static func next_generation() -> void:
    TriangleCell.next_generation()


static func randomize_alife() -> void:
    TriangleCell.randomize_alife(0.5)

static func clear() -> void:
    TriangleCell.set_alife(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # initial_cell.populate_neighbors(true, Rect2i(Vector2i(-30, -10), Vector2i(60, 20)))
    TriangleCell.populate_grid(Rect2i(Vector2i(0, 0), Vector2i(67, 22)))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
