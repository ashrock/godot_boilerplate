# File: scripts/systems/managers/DeltaTimerAdapter.gd
# DOCU: Adapter for delta-based timers to enable pause/scale control
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
class_name DeltaTimerAdapter
extends RefCounted

var target_object: Object
var timer_property: String  # e.g., "_preparation_timer"
var flag_property: String   # e.g., "_is_preparing" (optional)
var timer_id: String        # Unique identifier
var category: String        # "gameplay", "ui", "card", etc.

func _init(obj: Object, prop: String, flag: String, id: String, cat: String) -> void:
	target_object = obj
	timer_property = prop
	flag_property = flag
	timer_id = id
	category = cat

# DOCU: Get scaled delta for this timer
# @param delta: Raw delta time
# @return: float - Scaled delta (0 if paused)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getScaledDelta(delta: float) -> float:
	if TimerManager.isCategoryPaused(category):
		return 0.0
	return delta * TimerManager.getTimeScale()

# DOCU: Check if timer is currently active
# @return: bool - True if flag property is true
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isActive() -> bool:
	if flag_property.is_empty():
		return false
	if not target_object.has(flag_property):
		return false
	return target_object.get(flag_property)

# DOCU: Get current timer value
# @return: float - Current timer value
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getCurrentValue() -> float:
	if not target_object.has(timer_property):
		return 0.0
	return target_object.get(timer_property)
