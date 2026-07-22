# File: resources/items/ItemData.gd
# DOCU: Data resource for game items
# Defines item properties for data-driven design
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
class_name ItemData
extends Resource

# ==================== ENUMS ====================
enum ItemType { CONSUMABLE, EQUIPMENT, QUEST_ITEM, MATERIAL }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# ==================== CORE PROPERTIES ====================
@export var item_id: String = ""
@export var display_name: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export_multiline var description: String = ""

# ==================== VISUAL PROPERTIES ====================
@export var icon: Texture2D = preload("res://icon.svg")
@export var color: Color = Color.WHITE

# ==================== GAMEPLAY PROPERTIES ====================
@export var rarity: Rarity = Rarity.COMMON
@export_range(1, 999) var stack_limit: int = 99
@export var value: int = 10  # Buy/sell price
@export var weight: float = 1.0
@export var tags: Array[String] = []

# ==================== CONSUMABLE PROPERTIES ====================
@export_group("Consumable Settings")
@export var health_restore: int = 0
@export var mana_restore: int = 0
@export var buff_duration: float = 0.0

# ==================== VALIDATION ====================
# DOCU: Validate resource data for required fields
# @return: bool - True if all required fields are valid
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func isValid() -> bool:
	if item_id.is_empty():
		push_error("ItemData: item_id is empty")
		return false

	if display_name.is_empty():
		push_error("ItemData: display_name is empty for %s" % item_id)
		return false

	if icon == null:
		push_warning("ItemData: icon is null for %s" % item_id)

	return true

# ==================== HELPER METHODS ====================
# DOCU: Check if item has a specific tag
# @param tag: The tag to check for
# @return: bool - True if tag exists
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func hasTag(tag: String) -> bool:
	return tag in tags

# DOCU: Check if item can stack with another
# @param other: The ItemData to compare with
# @return: bool - True if items can stack
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func canStackWith(other: ItemData) -> bool:
	return other != null and item_id == other.item_id

# DOCU: Get rarity as string
# @return: String - Rarity name
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getRarityString() -> String:
	return Rarity.keys()[rarity]

# DOCU: Get color for rarity
# @return: Color - Color associated with rarity
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func getRarityColor() -> Color:
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color(0.3, 1.0, 0.3)  # Green
		Rarity.RARE:
			return Color(0.3, 0.5, 1.0)  # Blue
		Rarity.EPIC:
			return Color(0.7, 0.3, 1.0)  # Purple
		Rarity.LEGENDARY:
			return Color(1.0, 0.7, 0.0)  # Gold
	return Color.WHITE
