# File: scripts/entities/Draggable.gd
# DOCU: Base class for draggable entities with bounds enforcement and overlap detection
# Provides unified drag & drop behavior for game objects
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
class_name Draggable
extends Node2D

# ==================== SIGNALS ====================
signal drag_started(entity: Draggable)
signal drag_ended(entity: Draggable, start_pos: Vector2, end_pos: Vector2)
signal drag_cancelled(entity: Draggable)
signal repositioned(entity: Draggable, start_pos: Vector2, end_pos: Vector2, distance: float)
signal overlapping_changed(entity: Draggable, is_overlapping: bool)

# ==================== EXPORTED PROPERTIES ====================
@export var is_draggable: bool = true
@export var prevent_overlap: bool = true
@export var drag_area: Area2D  # Area2D for input detection & overlap
@export var enable_rotation_on_drag: bool = false
@export var min_reposition_distance: float = 5.0  # Minimum distance to emit repositioned

# ==================== BOARD BOUNDS ====================
var board_bounds: Rect2 = Rect2()
var board_polygon: PackedVector2Array = PackedVector2Array()

# ==================== DRAG STATE ====================
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_start_position: Vector2 = Vector2.ZERO
var _original_z_index: int = 0
var _previous_position: Vector2 = Vector2.ZERO
var _original_modulate: Color = Color.WHITE

# ==================== OVERLAP DETECTION ====================
var _overlap_areas: Array[Area2D] = []
var _is_overlapping: bool = false

# ==================== COLORS ====================
const NORMAL_COLOR: Color = Color.WHITE
const OVERLAP_ERROR_COLOR: Color = Color(1.0, 0.5, 0.5, 1.0)

# ==================== LIFECYCLE ====================
func _ready() -> void:
	_initializeDraggable()

func _initializeDraggable() -> void:
	if drag_area and is_draggable:
		drag_area.input_event.connect(_onDragAreaInputEvent)
		drag_area.area_entered.connect(_onAreaEntered)
		drag_area.area_exited.connect(_onAreaExited)
	_original_z_index = z_index
	_original_modulate = modulate

func _process(delta: float) -> void:
	if _is_dragging:
		_processDragMovement(delta)

# ==================== DRAG LIFECYCLE ====================
# DOCU: Start dragging the entity
# Virtual method - override to add custom validation
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _startDrag() -> void:
	if not is_draggable:
		return

	if not _canStartDrag():
		return

	_is_dragging = true
	_drag_start_position = global_position
	_drag_offset = global_position - get_global_mouse_position()
	_original_z_index = z_index
	_original_modulate = modulate
	z_index = 1000  # Bring to front

	onDragStart()  # Virtual hook
	drag_started.emit(self)

# DOCU: Process drag movement during _process()
# @param delta: Frame delta time
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _processDragMovement(delta: float) -> void:
	_previous_position = global_position
	var target_position = get_global_mouse_position() + _drag_offset

	# Enforce bounds
	target_position = _clampToBounds(target_position)

	global_position = target_position

	# Optional rotation based on velocity
	if enable_rotation_on_drag:
		var velocity = global_position - _previous_position
		if velocity.length() > 1.0:
			rotation = lerp_angle(rotation, velocity.angle(), 0.1)

	onDragUpdate(delta)  # Virtual hook

# DOCU: End dragging and validate placement
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _endDrag() -> void:
	if not _canEndDrag():
		_cancelDrag()
		return

	_is_dragging = false
	z_index = _original_z_index
	modulate = _original_modulate

	onDragEnd()  # Virtual hook
	drag_ended.emit(self, _drag_start_position, global_position)

	# Emit repositioned if moved significantly
	var distance = _drag_start_position.distance_to(global_position)
	if distance >= min_reposition_distance:
		repositioned.emit(self, _drag_start_position, global_position, distance)

# DOCU: Cancel drag and return to start position
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _cancelDrag() -> void:
	global_position = _drag_start_position
	_is_dragging = false
	z_index = _original_z_index
	modulate = _original_modulate

	onDragCancel()  # Virtual hook
	drag_cancelled.emit(self)

# ==================== BOUNDS ENFORCEMENT ====================
# DOCU: Clamp position to board bounds
# @param pos: The position to clamp
# @return: Vector2 - Clamped position
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _clampToBounds(pos: Vector2) -> Vector2:
	if board_polygon.size() > 0:
		return _clampToPolygon(pos)
	elif board_bounds.size != Vector2.ZERO:
		return Vector2(
			clamp(pos.x, board_bounds.position.x, board_bounds.end.x),
			clamp(pos.y, board_bounds.position.y, board_bounds.end.y)
		)
	return pos

func _clampToPolygon(pos: Vector2) -> Vector2:
	# Check if point is inside polygon
	if Geometry2D.is_point_in_polygon(pos, board_polygon):
		return pos

	# Find nearest point on polygon edge
	var nearest_point = pos
	var min_distance = INF

	for i in range(board_polygon.size()):
		var p1 = board_polygon[i]
		var p2 = board_polygon[(i + 1) % board_polygon.size()]
		var closest = Geometry2D.get_closest_point_to_segment(pos, p1, p2)
		var distance = pos.distance_to(closest)

		if distance < min_distance:
			min_distance = distance
			nearest_point = closest

	return nearest_point

# ==================== OVERLAP DETECTION ====================
# DOCU: Check if entity overlaps with others
# @return: bool - True if overlapping
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _hasOverlapping() -> bool:
	if not drag_area:
		return false

	for area in _overlap_areas:
		if is_instance_valid(area) and area.get_parent() != self and area.get_parent() is Draggable:
			return true
	return false

func _updateOverlapState() -> void:
	var was_overlapping = _is_overlapping
	_is_overlapping = _hasOverlapping()

	# Visual feedback during drag
	if _is_dragging and prevent_overlap:
		modulate = OVERLAP_ERROR_COLOR if _is_overlapping else NORMAL_COLOR

	if was_overlapping != _is_overlapping:
		overlapping_changed.emit(self, _is_overlapping)

# ==================== INPUT HANDLING ====================
func _onDragAreaInputEvent(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_startDrag()
			else:
				if _is_dragging:
					_endDrag()

func _onAreaEntered(area: Area2D) -> void:
	if area not in _overlap_areas:
		_overlap_areas.append(area)
	_updateOverlapState()

func _onAreaExited(area: Area2D) -> void:
	_overlap_areas.erase(area)
	_updateOverlapState()

# ==================== VIRTUAL HOOKS ====================
# Override these in subclasses for custom behavior

func _canStartDrag() -> bool:
	return true  # Override to add validation

func onDragStart() -> void:
	pass  # Override: Pause timers, lock camera

func onDragUpdate(delta: float) -> void:
	pass  # Override: Rotation, VFX trails

func _canEndDrag() -> bool:
	if prevent_overlap and _hasOverlapping():
		return false
	return true  # Override to add validation

func onDragEnd() -> void:
	pass  # Override: Grid snap, save position

func onDragCancel() -> void:
	pass  # Override: Play error sound

# ==================== PUBLIC API ====================
# DOCU: Set rectangular bounds for dragging
# @param bounds: The Rect2 boundary
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setBoardBounds(bounds: Rect2) -> void:
	board_bounds = bounds

# DOCU: Set polygon bounds for dragging
# @param polygon: The polygon boundary points
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setBoardPolygon(polygon: PackedVector2Array) -> void:
	board_polygon = polygon

# DOCU: Check if currently dragging
# @return: bool - True if dragging
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isDragging() -> bool:
	return _is_dragging

# DOCU: Check if currently overlapping
# @return: bool - True if overlapping
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isOverlapping() -> bool:
	return _is_overlapping

# ==================== SERIALIZATION ====================
# DOCU: Serialize entity state for saving
# @return: Dictionary - Serialized state
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func serializeState() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"rotation": rotation,
		"z_index": z_index
	}

# DOCU: Restore entity state from save data
# @param data: Dictionary with serialized state
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func deserializeState(data: Dictionary) -> void:
	if data.has("position"):
		global_position = Vector2(data.position.x, data.position.y)
	if data.has("rotation"):
		rotation = data.rotation
	if data.has("z_index"):
		z_index = data.z_index
