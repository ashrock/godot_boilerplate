# File: scripts/systems/managers/TimerManager.gd
# DOCU: Centralized timer management with pause/scale control
# Enables global pause, time scaling, and debug visualization
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
extends Node

signal timer_registered(timer_id: String, category: String)
signal timer_unregistered(timer_id: String)
signal category_paused(category: String)
signal category_resumed(category: String)

# ==================== TIMER STORAGE ====================
var registered_timers: Dictionary = {}  # timer_id -> DeltaTimerAdapter
var paused_categories: Array[String] = []
var time_scale: float = 1.0

# ==================== INITIALIZATION ====================
func _ready() -> void:
	print("TimerManager: Initialized")

# ==================== TIMER REGISTRATION ====================
# DOCU: Register a delta-based timer for management
# @param adapter: The DeltaTimerAdapter instance
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func registerTimer(adapter: DeltaTimerAdapter) -> void:
	if registered_timers.has(adapter.timer_id):
		push_warning("TimerManager: Timer already registered: %s" % adapter.timer_id)
		return

	registered_timers[adapter.timer_id] = adapter
	timer_registered.emit(adapter.timer_id, adapter.category)

# DOCU: Unregister a timer (call in _exit_tree())
# @param timer_id: The unique timer ID
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func unregisterTimer(timer_id: String) -> void:
	if registered_timers.erase(timer_id):
		timer_unregistered.emit(timer_id)

# ==================== PAUSE CONTROL ====================
# DOCU: Pause all timers in a category
# @param category: The category to pause ("gameplay", "ui", etc.)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func pauseCategory(category: String) -> void:
	if category in paused_categories:
		return
	paused_categories.append(category)
	category_paused.emit(category)
	print("TimerManager: Paused category '%s'" % category)

# DOCU: Resume all timers in a category
# @param category: The category to resume
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func resumeCategory(category: String) -> void:
	if category not in paused_categories:
		return
	paused_categories.erase(category)
	category_resumed.emit(category)
	print("TimerManager: Resumed category '%s'" % category)

# DOCU: Pause all timers
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func pauseAll() -> void:
	var categories = _getAllCategories()
	for category in categories:
		pauseCategory(category)

# DOCU: Resume all timers
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func resumeAll() -> void:
	var categories_to_resume = paused_categories.duplicate()
	for category in categories_to_resume:
		resumeCategory(category)

# DOCU: Check if a category is paused
# @param category: The category to check
# @return: bool - True if paused
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isCategoryPaused(category: String) -> bool:
	return category in paused_categories

# ==================== TIME SCALING ====================
# DOCU: Set global time scale (for slow-motion, fast-forward)
# @param scale: The time scale multiplier (0.5 = half speed, 2.0 = double speed)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setTimeScale(scale: float) -> void:
	time_scale = clamp(scale, 0.0, 10.0)
	print("TimerManager: Time scale set to %.2f" % time_scale)

# DOCU: Get current time scale
# @return: float - Current time scale
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getTimeScale() -> float:
	return time_scale

# ==================== QUERY METHODS ====================
# DOCU: Get all timers in a category
# @param category: The category to query
# @return: Array[DeltaTimerAdapter] - All timers in category
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getTimersByCategory(category: String) -> Array:
	var result: Array = []
	for adapter in registered_timers.values():
		if adapter.category == category:
			result.append(adapter)
	return result

# DOCU: Check if a timer is registered
# @param timer_id: The timer ID to check
# @return: bool - True if registered
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func hasTimer(timer_id: String) -> bool:
	return registered_timers.has(timer_id)

# DOCU: Get count of active timers
# @return: int - Number of registered timers
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getActiveTimerCount() -> int:
	return registered_timers.size()

func _getAllCategories() -> Array[String]:
	var categories: Array[String] = []
	for adapter in registered_timers.values():
		if adapter.category not in categories:
			categories.append(adapter.category)
	return categories

# Note: DeltaTimerAdapter class is now in DeltaTimerAdapter.gd for proper class_name support
