class_name TriangleCell

extends Polygon2D


static var triangle_cells: Array[TriangleCell] = []

const TRIANGLE_CELL_SCENE: PackedScene = preload("res://triangle_cell.tscn")

func _enter_tree() -> void:
    triangle_cells.append(self)

func _exit_tree() -> void:
    triangle_cells.erase(self)

static func get_cell_at_coordinates(coordinates: Vector2i) -> TriangleCell:
    for cell in triangle_cells:
        if cell.coordinates == coordinates:
            return cell
    return null

static var frame: int = 0
const INTERLACE_DELAY: int = 5
static func triangle_cell_interlaced_process(delta: float) -> void:
    united_process()
    
    var i: int = frame % INTERLACE_DELAY

    while i < triangle_cells.size():
        triangle_cells[i].interlaced_process(delta)

        i += INTERLACE_DELAY
    
    frame += 1


static var is_cell_state_swap_queued: bool = false
static func united_process() -> void:
    if Input.is_action_just_pressed("rotate_cell_state") and not triangle_cells[0].get_viewport().gui_get_hovered_control():
        TriangleCell.is_cell_state_swap_queued = true


static func randomize_alife(alife_chance: float) -> void:
    for cell: TriangleCell in triangle_cells:
        var rand: float = randf()
        cell.data[DataKey.IS_ALIFE] = rand < alife_chance
        print(rand)


static func set_alife(new_alife: bool) -> void:
    for cell: TriangleCell in triangle_cells:
        cell.data[DataKey.IS_ALIFE] = new_alife


enum Neighbor {
    LEFT,
    RIGHT,
    BOTTOM,
    CORNER_TOP_LEFT,
    CORNER_TOP_CENTER,
    CORNER_TOP_RIGHT,
    CORNER_BOTTOM_LEFT_TOP,
    CORNER_BOTTOM_LEFT_CENTER,
    CORNER_BOTTOM_LEFT_BOTTOM,
    CORNER_BOTTOM_RIGHT_TOP,
    CORNER_BOTTOM_RIGHT_CENTER,
    CORNER_BOTTOM_RIGHT_BOTTOM,
}

const NEIGHBOR_OFFSETS: Dictionary[Neighbor, Vector2i] = {
    Neighbor.LEFT: Vector2i(-1, 0),
    Neighbor.RIGHT: Vector2i(1, 0),
    Neighbor.BOTTOM: Vector2i(0, 1),
    Neighbor.CORNER_TOP_LEFT: Vector2i(-1, -1),
    Neighbor.CORNER_TOP_CENTER: Vector2i(0, -1),
    Neighbor.CORNER_TOP_RIGHT: Vector2i(1, -1),
    Neighbor.CORNER_BOTTOM_LEFT_TOP: Vector2i(-2, 0),
    Neighbor.CORNER_BOTTOM_LEFT_CENTER: Vector2i(-2, 1),
    Neighbor.CORNER_BOTTOM_LEFT_BOTTOM: Vector2i(-1, 1),
    Neighbor.CORNER_BOTTOM_RIGHT_TOP: Vector2i(2, 0),
    Neighbor.CORNER_BOTTOM_RIGHT_CENTER: Vector2i(2, 1),
    Neighbor.CORNER_BOTTOM_RIGHT_BOTTOM: Vector2i(1, 1)
}

const NEIGHBOR_OFFSETS_INVERSE: Dictionary[Neighbor, Neighbor] = {
    Neighbor.LEFT: Neighbor.RIGHT,
    Neighbor.RIGHT: Neighbor.LEFT,
    Neighbor.BOTTOM: Neighbor.BOTTOM,
    Neighbor.CORNER_TOP_LEFT: Neighbor.CORNER_BOTTOM_RIGHT_BOTTOM,
    Neighbor.CORNER_TOP_CENTER: Neighbor.CORNER_TOP_CENTER,
    Neighbor.CORNER_TOP_RIGHT: Neighbor.CORNER_BOTTOM_LEFT_BOTTOM,
    Neighbor.CORNER_BOTTOM_LEFT_TOP: Neighbor.CORNER_BOTTOM_RIGHT_TOP,
    Neighbor.CORNER_BOTTOM_LEFT_CENTER: Neighbor.CORNER_BOTTOM_RIGHT_CENTER,
    Neighbor.CORNER_BOTTOM_LEFT_BOTTOM: Neighbor.CORNER_TOP_RIGHT,
    Neighbor.CORNER_BOTTOM_RIGHT_TOP: Neighbor.CORNER_BOTTOM_LEFT_TOP,
    Neighbor.CORNER_BOTTOM_RIGHT_CENTER: Neighbor.CORNER_BOTTOM_LEFT_CENTER,
    Neighbor.CORNER_BOTTOM_RIGHT_BOTTOM: Neighbor.CORNER_TOP_LEFT
}

var neighbors: Dictionary[Neighbor, TriangleCell] = {}
var coordinates: Vector2i = Vector2i.ZERO

static func populate_grid(coordinate_limit: Rect2i) -> void:
    var population_stack: Array[TriangleCell] = [GridManager.current_grid_manager.initial_cell]

    while population_stack:
        var cell: TriangleCell = population_stack.pop_back()

        if not coordinate_limit.has_point(cell.coordinates):
            continue
        
        var missing_neighbors: Array[Neighbor] = []
        for neighbor: Neighbor in Neighbor.values():
            if not cell.neighbors.has(neighbor):
                missing_neighbors.append(neighbor)
        
        if missing_neighbors.size() == 0:
            continue
        
        for neighbor: Neighbor in missing_neighbors:
            var neighbor_offset: Vector2i = NEIGHBOR_OFFSETS[neighbor]
            if cell.is_pointing_up():
                neighbor_offset = Vector2i(neighbor_offset.x, -neighbor_offset.y)
            var new_coordinates: Vector2i = cell.coordinates + neighbor_offset


            var neighbor_cell: TriangleCell = TriangleCell.get_cell_at_coordinates(new_coordinates)
            if neighbor_cell == null:
                neighbor_cell = TRIANGLE_CELL_SCENE.instantiate()
                neighbor_cell.coordinates = new_coordinates
                cell.get_parent().add_child(neighbor_cell)

                population_stack.append(neighbor_cell)

            cell.neighbors[neighbor] = neighbor_cell
            neighbor_cell.neighbors[NEIGHBOR_OFFSETS_INVERSE[neighbor]] = cell


func populate_neighbors(is_recursive: bool, coordinate_limit: Rect2i) -> void:
    if not coordinate_limit.has_point(coordinates):
        return

    var missing_neighbors: Array[Neighbor] = []
    for neighbor: Neighbor in Neighbor.values():
        if not neighbors.has(neighbor):
            missing_neighbors.append(neighbor)
    
    if missing_neighbors.size() == 0:
        return
    
    for neighbor: Neighbor in missing_neighbors:
        var neighbor_offset: Vector2i = NEIGHBOR_OFFSETS[neighbor]
        if is_pointing_up():
            neighbor_offset = Vector2i(neighbor_offset.x, -neighbor_offset.y)
        var new_coordinates: Vector2i = coordinates + neighbor_offset

        var neighbor_cell: TriangleCell = TriangleCell.get_cell_at_coordinates(new_coordinates)
        if neighbor_cell == null:
            neighbor_cell = TRIANGLE_CELL_SCENE.instantiate()
            neighbor_cell.coordinates = new_coordinates
            get_parent().add_child(neighbor_cell)

            if is_recursive:
                neighbor_cell.populate_neighbors(true, coordinate_limit)
        
        neighbors[neighbor] = neighbor_cell
        neighbor_cell.neighbors[NEIGHBOR_OFFSETS_INVERSE[neighbor]] = self


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    set_transform_from_coordinates()


# Only used for calling interlaced process from first Triangle Cell
func _process(delta: float) -> void:
    if TriangleCell.triangle_cells[0] == self:
        TriangleCell.triangle_cell_interlaced_process(delta)


func is_pointing_up() -> bool:
    return (coordinates.x + coordinates.y) % 2 == 0


const CELL_SIZE: Vector2 = Vector2(100, sqrt(3) * 50)
const GAP: float = 5.0
func set_transform_from_coordinates() -> void:
    if is_pointing_up():
        scale.y = -1
    
    position = Vector2(
        coordinates.x * CELL_SIZE.x * 0.5 + coordinates.x * (1 + GAP),
        coordinates.y * CELL_SIZE.y + coordinates.y * (1 + GAP)
)

var queued_connection_draws: Array[TriangleCell] = []

const COLOR_ALIFE: Color = Color.WHITE
const COLOR_DEAD: Color = Color(0.15, 0.15, 0.15)
const COLOR_HOVERED: Color = Color(0.5, 0.5, 0.5, 0.3)
const COLOR_CLICKED: Color = Color(0.5, 0.5, 0.5, 0.5)
func set_polygon_color() -> void:
    var flip_y_if_pointing_up: Vector2 = Vector2(1, -1) if is_pointing_up() else Vector2.ONE
    # var is_hovered: bool = Geometry2D.is_point_in_polygon((get_viewport().get_mouse_position() - get_viewport_rect().size / 2.0 + get_viewport().get_camera_2d().global_position - global_position) * flip_y_if_pointing_up, polygon)
    var is_hovered: bool = false
    if not get_viewport().gui_get_hovered_control():
        is_hovered = Geometry2D.is_point_in_polygon((get_viewport().get_mouse_position() - global_position) * flip_y_if_pointing_up / get_parent().global_scale, polygon)
    var new_color: Color = COLOR_ALIFE if data[DataKey.IS_ALIFE] else COLOR_DEAD
    
    if is_hovered:
        if not Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
            new_color = new_color.lerp(COLOR_HOVERED, COLOR_HOVERED.a)
        else:
            new_color = new_color.lerp(COLOR_CLICKED, COLOR_CLICKED.a)

        if TriangleCell.is_cell_state_swap_queued:
            data[DataKey.IS_ALIFE] = not data[DataKey.IS_ALIFE]
            TriangleCell.is_cell_state_swap_queued = false
        
        if queued_connection_draws.size() == 0 and show_debug:
            queued_connection_draws.append_array(neighbors.values())


    color = new_color


func interlaced_process(_delta: float) -> void:
    set_polygon_color()

enum DataKey {
    IS_ALIFE
}

var persistent_data: Dictionary[DataKey, Variant]
var data: Dictionary[DataKey, Variant] = \
{
    DataKey.IS_ALIFE: false
}
var queued_next_data: Dictionary[DataKey, Variant]

static func dequeue_next_data() -> void:
    for cell: TriangleCell in triangle_cells:
        cell.data = cell.queued_next_data
        cell.queued_next_data = {}


static func next_generation() -> void:
    for cell: TriangleCell in triangle_cells:
        cell.queue_next_data(cell.get_next_data())

    TriangleCell.dequeue_next_data()


func queue_next_data(next_data: Dictionary[DataKey, Variant]) -> void:
    queued_next_data = next_data


func get_next_data() -> Dictionary[DataKey, Variant]:
    return get_gol_data(1, 2, 3)


func get_gol_data(extinction_max: int, sustain_max: int, birth_max: int) -> Dictionary[DataKey, Variant]:
    var alife_neighbours: int = get_alife_neighbours()
    var new_data: Dictionary[DataKey, Variant] = data.duplicate_deep()

    if alife_neighbours <= extinction_max:
        new_data[DataKey.IS_ALIFE] = false
    elif alife_neighbours <= sustain_max:
        pass
    elif alife_neighbours <= birth_max:
        new_data[DataKey.IS_ALIFE] = true
    else:
        new_data[DataKey.IS_ALIFE] = false
    
    return new_data


func get_alife_neighbours() -> int:
    var alife_count: int = 0

    for neighbor: TriangleCell in neighbors.values():
        alife_count += int(neighbor.is_alife())
    
    return alife_count


func is_alife() -> bool:
    return data.get(DataKey.IS_ALIFE, false)


func _draw() -> void:
    while queued_connection_draws:
        var other: TriangleCell = queued_connection_draws.pop_back()
        var color: Color = Color.GREEN if other.is_alife() else Color.RED
        var thickness: float = 3 if other.is_alife() else -1
        draw_line(Vector2.ZERO, (other.position - position) * scale, color, thickness)


static var show_debug: bool = false
static func toggle_debug() -> void:
    TriangleCell.show_debug = not TriangleCell.show_debug 
