# File: scripts/entities/LifecycleEntity.gd
# DOCU: Base class for entities with multi-stage lifecycle and virtual hooks
# Provides predictable initialization order and extensible lifecycle events
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
class_name LifecycleEntity
extends Node2D

# ==================== SIGNALS ====================
signal spawned(entity: LifecycleEntity)
signal activated(entity: LifecycleEntity)
signal deactivated(entity: LifecycleEntity)
signal destroyed(entity: LifecycleEntity)

# ==================== STATE ====================
enum State { INACTIVE, ACTIVATING, ACTIVE, DEACTIVATING }

var _current_state: State = State.INACTIVE
var _is_initialized: bool = false

# ==================== LIFECYCLE ====================
func _ready() -> void:
	initialize()
	_setupVisuals()
	_connectSignals()
	_registerTimers()
	_postInitialize()

# ==================== MULTI-STAGE INITIALIZATION ====================
# DOCU: Initialize entity with data
# Override this in subclasses for custom initialization
# @param data: Optional resource data
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func initialize(data: Resource = null) -> void:
	if _is_initialized:
		return
	_is_initialized = true
	onInitialize(data)  # Virtual hook

# DOCU: Virtual hook for subclass initialization
# @param data: Optional resource data
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func onInitialize(data: Resource = null) -> void:
	pass  # Override in subclass

# DOCU: Setup visual representation from data
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _setupVisuals() -> void:
	# Apply textures, colors, labels from entity_data
	pass  # Override in subclass

# DOCU: Connect internal signals
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _connectSignals() -> void:
	# Connect node signals
	pass  # Override in subclass

# DOCU: Register timers with TimerManager
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _registerTimers() -> void:
	# Register with TimerManager
	pass  # Override in subclass

# DOCU: Post-initialization hook
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func _postInitialize() -> void:
	onSpawn()  # Virtual hook
	spawned.emit(self)

# DOCU: Virtual hook called after full initialization
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func onSpawn() -> void:
	pass  # Override for spawn animations, event emission

# ==================== ACTIVATION/DEACTIVATION ====================
# DOCU: Activate the entity
# @return: bool - True if activation successful
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func activate() -> bool:
	if _current_state != State.INACTIVE:
		return false

	_current_state = State.ACTIVATING
	onActivate()  # Virtual hook
	_current_state = State.ACTIVE
	activated.emit(self)
	return true

# DOCU: Virtual hook for activation
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func onActivate() -> void:
	pass  # Override: Start timers, play animations

# DOCU: Deactivate the entity
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func deactivate() -> void:
	if _current_state != State.ACTIVE:
		return

	_current_state = State.DEACTIVATING
	onDeactivate()  # Virtual hook
	_current_state = State.INACTIVE
	deactivated.emit(self)

# DOCU: Virtual hook for deactivation
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func onDeactivate() -> void:
	pass  # Override: Pause timers, grey out visuals

# ==================== CLEANUP ====================
func _exit_tree() -> void:
	onDestroy()  # Virtual hook
	destroyed.emit(self)

# DOCU: Virtual hook for cleanup before deletion
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func onDestroy() -> void:
	pass  # Override: Unregister timers, disconnect signals

# ==================== FACTORY RESET (Object Pooling) ====================
# DOCU: Reset entity to factory state for pooling
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func resetState() -> void:
	_is_initialized = false
	_current_state = State.INACTIVE

	# Reset visual state
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = 0.0

	onReset()  # Virtual hook

# DOCU: Virtual hook for custom reset logic
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func onReset() -> void:
	pass  # Override for custom reset

# ==================== STATE QUERIES ====================
# DOCU: Check if entity is active
# @return: bool - True if in ACTIVE state
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isActive() -> bool:
	return _current_state == State.ACTIVE

# DOCU: Check if entity is initialized
# @return: bool - True if initialized
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isInitialized() -> bool:
	return _is_initialized

# DOCU: Get current state
# @return: State - Current state enum value
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getCurrentState() -> State:
	return _current_state
