# File: scripts/systems/managers/Constants.gd
# DOCU: Game constants and configuration values
# Single source of truth for game balance and settings
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
extends Node

# ==================== VERSION ====================
const VERSION: String = "1.0.0"
const DEBUG_MODE: bool = false

# ==================== CORE GAMEPLAY ====================
const MAX_HEALTH: int = 100
const MAX_SPEED: float = 300.0
const GRAVITY: float = 980.0
const JUMP_FORCE: float = 400.0

# ==================== GRID SYSTEM ====================
const GRID_CELL_WIDTH: int = 64
const GRID_CELL_HEIGHT: int = 64
const GRID_SNAP_ENABLED: bool = false

# ==================== TIMING ====================
const GAME_START_DELAY: float = 1.0
const RESPAWN_TIME: float = 3.0
const INVINCIBILITY_DURATION: float = 2.0

# ==================== UI ====================
const NOTIFICATION_DURATION: float = 3.0
const FADE_IN_DURATION: float = 0.5
const FADE_OUT_DURATION: float = 0.5

# ==================== COLOR PALETTE ====================
const COLOR_PRIMARY: Color = Color(0.2, 0.6, 1.0)
const COLOR_SECONDARY: Color = Color(1.0, 0.4, 0.2)
const COLOR_SUCCESS: Color = Color(0.2, 0.8, 0.3)
const COLOR_WARNING: Color = Color(1.0, 0.8, 0.0)
const COLOR_DANGER: Color = Color(0.9, 0.2, 0.2)
const COLOR_INFO: Color = Color(0.5, 0.7, 1.0)

# ==================== LAYERS (Physics & Render) ====================
const LAYER_PLAYER: int = 1
const LAYER_ENEMY: int = 2
const LAYER_COLLECTIBLE: int = 4
const LAYER_TERRAIN: int = 8
const LAYER_PROJECTILE: int = 16

# ==================== DIFFICULTY SETTINGS ====================
const DIFFICULTY_SETTINGS: Dictionary = {
	"EASY": {
		"health_multiplier": 1.5,
		"damage_multiplier": 0.75,
		"enemy_speed_multiplier": 0.8
	},
	"NORMAL": {
		"health_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"enemy_speed_multiplier": 1.0
	},
	"HARD": {
		"health_multiplier": 0.75,
		"damage_multiplier": 1.5,
		"enemy_speed_multiplier": 1.2
	}
}

# ==================== SAVE/LOAD ====================
const SAVE_FILE_PATH: String = "user://savegame.dat"
const AUTO_SAVE_INTERVAL: float = 60.0  # seconds

# ==================== INITIALIZATION ====================
func _ready() -> void:
	print("Constants: Initialized (Version %s)" % VERSION)

# ==================== HELPER METHODS ====================
# DOCU: Get difficulty multiplier
# @param difficulty: The difficulty level ("EASY", "NORMAL", "HARD")
# @param multiplier_type: The type of multiplier to get
# @return: float - The multiplier value
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getDifficultyMultiplier(difficulty: String, multiplier_type: String) -> float:
	if not DIFFICULTY_SETTINGS.has(difficulty):
		push_warning("Constants: Unknown difficulty '%s', using NORMAL" % difficulty)
		difficulty = "NORMAL"

	var settings = DIFFICULTY_SETTINGS[difficulty]
	if not settings.has(multiplier_type):
		push_error("Constants: Unknown multiplier type '%s'" % multiplier_type)
		return 1.0

	return settings[multiplier_type]
