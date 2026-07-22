# File: scripts/systems/managers/PlayerBoardState.gd
# DOCU: Per-player game state instance
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
class_name PlayerBoardState
extends RefCounted

# ==================== SIGNALS ====================
signal score_changed(player_id: int, new_score: int)
signal health_changed(player_id: int, new_health: int)
signal item_collected(player_id: int, item: Node)

# ==================== IDENTITY ====================
var player_id: int
var player_name: String

# ==================== GAME STATE ====================
var score: int = 0
var health: int = 100
var max_health: int = 100
var items: Array[Node] = []
var board_node: Node = null  # Reference to scene instance

# ==================== CONSTRUCTOR ====================
func _init(pid: int, pname: String = "") -> void:
	player_id = pid
	player_name = pname if not pname.is_empty() else "Player %d" % pid

# ==================== PUBLIC API ====================
# DOCU: Add score to player
# @param amount: Score to add
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func addScore(amount: int) -> void:
	score += amount
	score_changed.emit(player_id, score)

# DOCU: Set score directly
# @param value: New score value
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setScore(value: int) -> void:
	score = value
	score_changed.emit(player_id, score)

# DOCU: Set health with clamping
# @param value: New health value
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setHealth(value: int) -> void:
	health = clampi(value, 0, max_health)
	health_changed.emit(player_id, health)

# DOCU: Damage player
# @param amount: Damage amount
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func takeDamage(amount: int) -> void:
	setHealth(health - amount)

# DOCU: Heal player
# @param amount: Heal amount
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func heal(amount: int) -> void:
	setHealth(health + amount)

# DOCU: Register an item with this player
# @param item: The item node to register
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func registerItem(item: Node) -> void:
	if item in items:
		return
	items.append(item)
	item_collected.emit(player_id, item)

# DOCU: Serialize state for saving
# @return: Dictionary - Serialized state
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func serializeState() -> Dictionary:
	return {
		"player_id": player_id,
		"player_name": player_name,
		"score": score,
		"health": health,
		"max_health": max_health,
		"items": items.map(func(i): return i.get_path() if i else "")
	}

# DOCU: Restore state from save data
# @param data: Dictionary with serialized state
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func deserializeState(data: Dictionary) -> void:
	if data.has("score"):
		score = data.score
	if data.has("health"):
		health = data.health
	if data.has("max_health"):
		max_health = data.max_health
