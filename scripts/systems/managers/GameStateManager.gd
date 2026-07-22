# File: scripts/systems/managers/GameStateManager.gd
# DOCU: Coordinates multiple player state instances for multi-instance support
# Provides per-player game state tracking with signal routing
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
extends Node

# ==================== SIGNALS ====================
signal board_created(player_id: int, board_state: PlayerBoardState)
signal board_switched(from_player_id: int, to_player_id: int)
signal score_changed(player_id: int, new_score: int)
signal health_changed(player_id: int, new_health: int)

# ==================== STATE ====================
var player_boards: Dictionary = {}  # player_id -> PlayerBoardState
var local_player_id: int = 1  # Current player ID
var active_player_id: int = 1  # Active board for split-screen

# ==================== INITIALIZATION ====================
func _ready() -> void:
	# Create default player board
	createPlayerBoard(1, "Player 1")
	print("GameStateManager: Initialized with player 1")

# ==================== BOARD MANAGEMENT ====================
# DOCU: Create a new player board instance
# @param player_id: The player ID (1, 2, 3, etc.)
# @param player_name: Optional player name
# @return: PlayerBoardState - The created board state
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func createPlayerBoard(player_id: int, player_name: String = "") -> PlayerBoardState:
	if player_boards.has(player_id):
		push_warning("GameStateManager: Board already exists for player %d" % player_id)
		return player_boards[player_id]

	var board_state = PlayerBoardState.new(player_id, player_name)
	player_boards[player_id] = board_state

	# Forward signals with player_id
	board_state.score_changed.connect(
		func(pid: int, score: int):
			score_changed.emit(pid, score)
	)
	board_state.health_changed.connect(
		func(pid: int, health: int):
			health_changed.emit(pid, health)
	)

	board_created.emit(player_id, board_state)
	print("GameStateManager: Created board for player %d (%s)" % [player_id, player_name])
	return board_state

# DOCU: Get board state for a specific player
# @param player_id: The player ID to query
# @return: PlayerBoardState - The board state, or null if not found
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getBoardState(player_id: int) -> PlayerBoardState:
	return player_boards.get(player_id, null)

# DOCU: Get the local player's board state
# @return: PlayerBoardState - The local player's board
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getLocalPlayerBoardState() -> PlayerBoardState:
	return getBoardState(local_player_id)

# DOCU: Switch active board (for split-screen tab switching)
# @param player_id: The player ID to switch to
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func switchActiveBoard(player_id: int) -> void:
	if not player_boards.has(player_id):
		push_error("GameStateManager: Cannot switch to non-existent board: %d" % player_id)
		return

	var previous_id = active_player_id
	active_player_id = player_id
	board_switched.emit(previous_id, player_id)
	print("GameStateManager: Switched from player %d to %d" % [previous_id, player_id])

# ==================== QUERY METHODS ====================
# DOCU: Get all player IDs
# @return: Array[int] - All registered player IDs
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getAllPlayerIds() -> Array:
	return player_boards.keys()

# DOCU: Check if a player exists
# @param player_id: The player ID to check
# @return: bool - True if player exists
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func hasPlayer(player_id: int) -> bool:
	return player_boards.has(player_id)

# Note: PlayerBoardState class is now in PlayerBoardState.gd for proper class_name support
