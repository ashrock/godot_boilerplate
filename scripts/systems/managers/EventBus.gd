# File: scripts/systems/managers/EventBus.gd
# DOCU: Central signal hub for cross-component communication
# Provides decoupled event broadcasting between game systems
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
extends Node

# ==================== LIFECYCLE SIGNALS ====================
signal game_started(player_id: int)
signal game_paused(player_id: int, is_paused: bool)
signal game_over(player_id: int, result: Dictionary)
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_complete(scene_name: String)

# ==================== GAMEPLAY SIGNALS ====================
signal score_changed(player_id: int, new_score: int)
signal health_changed(player_id: int, new_health: int)
signal item_collected(player_id: int, item: Node)
signal item_used(player_id: int, item: Node)
signal enemy_defeated(player_id: int, enemy: Node)
signal player_died(player_id: int)

# ==================== UI SIGNALS ====================
signal modal_opened(player_id: int, modal_type: String)
signal modal_closed(player_id: int, modal_type: String)
signal notification_shown(player_id: int, message: String, duration: float)
signal hud_updated(player_id: int, hud_data: Dictionary)

# ==================== OPTIMIZATION FLAGS ====================
var is_scene_transitioning: bool = false

# ==================== INITIALIZATION ====================
func _ready() -> void:
	print("EventBus: Initialized")

# ==================== HELPER METHODS ====================
# DOCU: Emit game started event with logging
# @param player_id: The player ID who started the game
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func emitGameStarted(player_id: int) -> void:
	game_started.emit(player_id)
	print("EventBus: game_started emitted for player %d" % player_id)

# DOCU: Emit score change with validation
# @param player_id: The player whose score changed
# @param new_score: The new score value
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func emitScoreChanged(player_id: int, new_score: int) -> void:
	if new_score < 0:
		push_warning("EventBus: Negative score emitted (%d)" % new_score)
	score_changed.emit(player_id, new_score)

# DOCU: Emit notification with default duration
# @param player_id: The player to show notification to
# @param message: The notification message
# @param duration: How long to show (default: 3.0s)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func showNotification(player_id: int, message: String, duration: float = 3.0) -> void:
	notification_shown.emit(player_id, message, duration)
