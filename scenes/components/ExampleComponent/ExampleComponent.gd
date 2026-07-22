# File: scenes/components/ExampleComponent/ExampleComponent.gd
# DOCU: Example component demonstrating full lifecycle pattern
# Shows proper initialization order, virtual hooks, and signal-driven communication
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
class_name ExampleComponent
extends LifecycleEntity

# ==================== SIGNALS ====================
signal component_clicked(component: ExampleComponent)
signal value_changed(old_value: int, new_value: int)

# ==================== ENUMS ====================
enum ComponentMode { MODE_A, MODE_B, MODE_C }

# ==================== EXPORTED VARIABLES ====================
@export var component_data: Resource = null:
	set(value):
		component_data = value
		if is_node_ready():
			_updateFromData()

@export var mode: ComponentMode = ComponentMode.MODE_A
@export var auto_activate: bool = true

# ==================== PRIVATE VARIABLES ====================
var _value: int = 0
var _timer: float = 0.0
var _is_processing: bool = false

# ==================== NODE REFERENCES ====================
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _label: Label = $Label
@onready var _area: Area2D = $Area2D

# ==================== LIFECYCLE OVERRIDE: INITIALIZATION ====================
# Override: Custom initialization with data
func onInitialize(data: Resource = null) -> void:
	if data:
		component_data = data
	print("ExampleComponent: Initialized with data: %s" % str(component_data))

# Override: Setup visual representation
func _setupVisuals() -> void:
	if component_data:
		_updateFromData()
	_label.text = "Component %d" % get_instance_id()
	_sprite.modulate = Constants.COLOR_PRIMARY

# Override: Connect internal signals
func _connectSignals() -> void:
	if _area:
		_area.input_event.connect(_onAreaInputEvent)
	EventBus.game_paused.connect(_onGamePaused)

# Override: Register timers
func _registerTimers() -> void:
	var timer_id = "example_component_%d" % get_instance_id()
	var adapter = DeltaTimerAdapter.new(
		self,
		"_timer",
		"_is_processing",
		timer_id,
		"gameplay"
	)
	TimerManager.registerTimer(adapter)
	print("ExampleComponent: Timer registered with ID: %s" % timer_id)

# Override: Spawn hook
func onSpawn() -> void:
	add_to_group("ExampleComponent")
	EventBus.notification_shown.emit(
		GameStateManager.local_player_id,
		"Component spawned!",
		2.0
	)

	if auto_activate:
		call_deferred("activate")  # Deferred to ensure full initialization

# ==================== LIFECYCLE OVERRIDE: ACTIVATION ====================
# Override: Activation logic
func onActivate() -> void:
	_is_processing = true
	_sprite.modulate = Constants.COLOR_SUCCESS
	print("ExampleComponent: Activated")

# Override: Deactivation logic
func onDeactivate() -> void:
	_is_processing = false
	_sprite.modulate = Constants.COLOR_INFO
	print("ExampleComponent: Deactivated")

# ==================== LIFECYCLE OVERRIDE: CLEANUP ====================
# Override: Cleanup before deletion
func onDestroy() -> void:
	var timer_id = "example_component_%d" % get_instance_id()
	TimerManager.unregisterTimer(timer_id)
	print("ExampleComponent: Destroyed, timer unregistered")

# Override: Factory reset for pooling
func onReset() -> void:
	_value = 0
	_timer = 0.0
	_is_processing = false
	_label.text = ""
	print("ExampleComponent: Reset to factory state")

# ==================== FRAME PROCESSING ====================
func _process(delta: float) -> void:
	if not _is_processing:
		return

	# Get scaled delta from TimerManager
	var timer_id = "example_component_%d" % get_instance_id()
	var scaled_delta = delta
	if TimerManager.hasTimer(timer_id):
		var adapter = TimerManager.registered_timers[timer_id]
		scaled_delta = adapter.getScaledDelta(delta)

	_timer += scaled_delta

	# Update label with timer value
	_label.text = "Timer: %.1f" % _timer

	# Example periodic event
	if int(_timer) % 5 == 0 and int(_timer) > 0:
		_onTimerMilestone()

# ==================== PUBLIC API ====================
# DOCU: Set component value
# @param new_value: The new value to set
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setValue(new_value: int) -> void:
	var old_value = _value
	_value = new_value
	value_changed.emit(old_value, new_value)
	print("ExampleComponent: Value changed from %d to %d" % [old_value, new_value])

# DOCU: Get current value
# @return: int - Current value
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getValue() -> int:
	return _value

# DOCU: Set component mode
# @param new_mode: The mode to switch to
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setMode(new_mode: ComponentMode) -> void:
	mode = new_mode
	_updateVisualForMode()

# ==================== PRIVATE HELPERS ====================
func _updateFromData() -> void:
	if not component_data:
		return
	# Update component from resource data
	print("ExampleComponent: Updated from data")

func _updateVisualForMode() -> void:
	match mode:
		ComponentMode.MODE_A:
			_sprite.modulate = Constants.COLOR_PRIMARY
		ComponentMode.MODE_B:
			_sprite.modulate = Constants.COLOR_SECONDARY
		ComponentMode.MODE_C:
			_sprite.modulate = Constants.COLOR_WARNING

func _onTimerMilestone() -> void:
	EventBus.notification_shown.emit(
		GameStateManager.local_player_id,
		"Timer milestone: %d seconds" % int(_timer),
		2.0
	)

# ==================== INPUT HANDLING ====================
func _onAreaInputEvent(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_onClick()

func _onClick() -> void:
	component_clicked.emit(self)

	# Toggle activation on click
	if isActive():
		deactivate()
	else:
		activate()

# ==================== SIGNAL HANDLERS ====================
func _onGamePaused(player_id: int, is_paused: bool) -> void:
	if player_id != GameStateManager.local_player_id:
		return

	if is_paused:
		# Pause handled automatically by TimerManager
		print("ExampleComponent: Game paused")
	else:
		print("ExampleComponent: Game resumed")
