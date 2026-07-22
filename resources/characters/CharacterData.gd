# File: resources/characters/CharacterData.gd
# DOCU: Data resource for game characters (players, NPCs, enemies)
# Defines character properties for data-driven design
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
class_name CharacterData
extends Resource

# ==================== ENUMS ====================
enum CharacterType { PLAYER, ALLY, NEUTRAL, ENEMY, BOSS }
enum CharacterClass { WARRIOR, MAGE, ROGUE, RANGER }

# ==================== CORE PROPERTIES ====================
@export var character_id: String = ""
@export var display_name: String = ""
@export var character_type: CharacterType = CharacterType.NEUTRAL
@export var character_class: CharacterClass = CharacterClass.WARRIOR
@export_multiline var description: String = ""

# ==================== VISUAL PROPERTIES ====================
@export var sprite_texture: Texture2D = preload("res://icon.svg")
@export var portrait: Texture2D
@export var sprite_scale: Vector2 = Vector2.ONE
@export var color_tint: Color = Color.WHITE

# ==================== STATS ====================
@export_group("Base Stats")
@export var max_health: int = 100
@export var max_mana: int = 50
@export var move_speed: float = 200.0
@export var attack_damage: int = 10
@export var defense: int = 5

# ==================== GAMEPLAY PROPERTIES ====================
@export_group("Gameplay")
@export var level: int = 1
@export var experience_value: int = 10  # XP granted when defeated
@export var ai_behavior: String = "aggressive"  # For enemies/NPCs
@export var tags: Array[String] = []

# ==================== DIALOGUE (for NPCs) ====================
@export_group("Dialogue")
@export var has_dialogue: bool = false
@export var dialogue_id: String = ""

# ==================== VALIDATION ====================
# DOCU: Validate resource data for required fields
# @return: bool - True if all required fields are valid
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isValid() -> bool:
	if character_id.is_empty():
		push_error("CharacterData: character_id is empty")
		return false

	if display_name.is_empty():
		push_error("CharacterData: display_name is empty for %s" % character_id)
		return false

	if sprite_texture == null:
		push_warning("CharacterData: sprite_texture is null for %s" % character_id)

	return true

# ==================== HELPER METHODS ====================
# DOCU: Check if character has a specific tag
# @param tag: The tag to check for
# @return: bool - True if tag exists
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func hasTag(tag: String) -> bool:
	return tag in tags

# DOCU: Get character type as string
# @return: String - Character type name
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getTypeString() -> String:
	return CharacterType.keys()[character_type]

# DOCU: Get character class as string
# @return: String - Character class name
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getClassString() -> String:
	return CharacterClass.keys()[character_class]

# DOCU: Check if character is hostile
# @return: bool - True if enemy or boss
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isHostile() -> bool:
	return character_type == CharacterType.ENEMY or character_type == CharacterType.BOSS

# DOCU: Check if character is friendly
# @return: bool - True if player or ally
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isFriendly() -> bool:
	return character_type == CharacterType.PLAYER or character_type == CharacterType.ALLY
