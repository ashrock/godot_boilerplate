# Godot 4.x Game Development Boilerplate Guide

**Extracted from Mocha Kombat Architecture**
A comprehensive guide to professional game architecture patterns for Godot 4.x projects.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Naming Conventions](#naming-conventions)
4. [Singleton Manager Pattern](#singleton-manager-pattern)
5. [EventBus Signal Architecture](#eventbus-signal-architecture)
6. [Component Architecture](#component-architecture)
7. [Component & Entity Lifecycle Events](#component--entity-lifecycle-events)
8. [Resource-Based Data Design](#resource-based-data-design)
9. [Drag & Drop System](#drag--drop-system)
10. [Timer Management System](#timer-management-system)
11. [Multi-Instance Architecture](#multi-instance-architecture)
12. [Documentation Standards](#documentation-standards)
13. [Additional Patterns](#additional-patterns)

---

## Introduction

This guide extracts **generic, reusable patterns** from the Mocha Kombat codebase—a production Godot 4.5 game with 225+ resource files, 53 singleton managers, and a clean layered architecture. These patterns are applicable to any Godot 4.x project, from small prototypes to large production games.

### Key Benefits

- **Loose coupling** through signal-driven architecture
- **Data-driven design** via custom resources
- **Type safety** with strict naming conventions
- **Scalability** with multi-instance support
- **Maintainability** through consistent structure

### What This Guide Is NOT

This is not a tutorial on Mocha Kombat-specific mechanics (card stacking, recipes, customer management). It focuses on **architectural patterns** that work for any game genre.

---

## Project Structure

### Core Directory Organization

```plaintext
project_root/
├── addons/              # Third-party plugins and extensions
├── assets/              # All game assets (NOT in scenes/)
│   ├── images/          # Textures, sprites, UI elements
│   │   ├── ui/          # UI-specific images
│   │   ├── characters/  # Character sprites
│   │   ├── items/       # Item textures
│   │   └── environment/ # Background, tiles, etc.
│   ├── sounds/          # Audio files (SFX, music)
│   ├── fonts/           # Font files
│   ├── shaders/         # Shader files (.gdshader, .tres)
│   └── themes/          # UI theme resources
├── resources/           # Custom resource files (.tres)
│   ├── items/           # Item data resources
│   ├── characters/      # Character data resources
│   ├── levels/          # Level configuration resources
│   └── *.gd             # Resource script definitions
├── scenes/              # All scene files (.tscn)
│   ├── components/      # Reusable components
│   ├── game/            # Game-specific scenes
│   ├── levels/          # Level scenes
│   ├── menus/           # Menu scenes
│   └── ui/              # UI components
└── scripts/             # All GDScript files (.gd)
    ├── systems/         # Core game systems
    │   └── managers/    # Singleton managers (autoloads)
    ├── entities/        # Entity base classes
    └── game/            # Game-specific logic
```

### Design Principles

1. **Separation of Concerns**: Scenes (visual hierarchy) ≠ Scripts (logic) ≠ Resources (data)
2. **Assets Live in `assets/`**: Never embed textures/sounds in scene folders
3. **Component-Based Organization**: Group related scene + script + assets in component folders
4. **Resources Are Data**: Configuration lives in `.tres` files, editable in Inspector

### Example: Mocha Kombat Structure

```
kopi_kombat/
├── assets/images/cards/ingredients/coffee_beans.svg
├── resources/cards/ingredients/CoffeeBeans.tres  # References coffee_beans.svg
├── scenes/components/Card/Card.tscn              # Card visual component
├── scripts/systems/managers/CardManager.gd       # Singleton for card logic
└── scripts/entities/Card.gd                      # Card instance script
```

**Benefit**: Clear boundaries prevent "where does this file go?" confusion.

---

## Naming Conventions

Strict naming standards improve codebase navigability and prevent errors.

### File & Directory Naming

| Element | Convention | Example | Rationale |
|---------|-----------|---------|-----------|
| Directories (code) | **PascalCase** | `PlayerController/`, `MainMenu/` | Matches class names |
| Directories (assets) | **snake_case** | `ui/icons/`, `sounds/sfx/` | Lowercase for web compatibility |
| Scripts | **PascalCase** | `PlayerController.gd` | Matches `class_name` declaration |
| Scenes | **PascalCase** | `MainMenu.tscn`, `Player.tscn` | Consistency with scripts |
| Assets | **snake_case** | `player_sprite.png`, `button_click.wav` | Lowercase for cross-platform |
| Resources | **PascalCase** | `HealthPotion.tres` | Matches resource type name |

### Code Naming

| Element | Convention | Example | Notes |
|---------|-----------|---------|-------|
| Variables | **snake_case** | `player_health`, `max_speed` | |
| Constants | **CONSTANT_CASE** | `MAX_HEALTH`, `GRID_SIZE` | |
| Functions | **camelCase** | `getPlayerInput()`, `updateHealth()` | Public API |
| Private Members | **_snake_case** | `_internal_state`, `_is_dragging` | Prefix with `_` |
| Signals | **snake_case** (past tense) | `item_collected`, `health_changed` | Describe completed action |
| Enums | **PascalCase** | `enum State { IDLE, RUNNING }` | |
| Enum Values | **CONSTANT_CASE** | `State.IDLE`, `ItemType.CONSUMABLE` | |
| Class Names | **PascalCase** | `class_name PlayerController` | Exported for type hints |

### Asset Naming Patterns

```
Textures:     component_state_purpose.png      # button_normal_bg.png
Icons:        icon_component_purpose.png       # icon_inventory_bag.png
Sounds:       sfx_component_action.wav         # sfx_button_click.wav
Animations:   anim_component_action.anim       # anim_player_walk.anim
```

### Example from Mocha Kombat

```gdscript
# File: scripts/systems/managers/CardManager.gd
class_name CardManager
extends Node

const MAX_CARDS_PER_STACK: int = 5  # CONSTANT_CASE
var active_cards: Array[Card] = []  # snake_case

signal card_spawned(card: Card)     # snake_case, past tense

func spawnCard(card_data: CardData) -> Card:  # camelCase function
    var _spawn_position: Vector2 = Vector2.ZERO  # _snake_case for private
    # ...
```

---

## Singleton Manager Pattern

Managers are **autoloaded singletons** that handle cross-cutting concerns (audio, state, timers, etc.). They live in `scripts/systems/managers/` and are registered in `project.godot`.

### Why Use Managers?

- **Global access**: `AudioManager.playSfx("click")` from anywhere
- **Single responsibility**: Each manager owns one concern
- **Lifecycle control**: Initialize once in `_ready()`
- **Signal coordination**: Centralized event emission

### Manager Template

```gdscript
# File: scripts/systems/managers/ExampleManager.gd
# DOCU: Manages [specific concern] across the game
# Last Updated At: 2026-07-22
# @author YourName
extends Node

# Signals (past tense, snake_case)
signal item_registered(item: Node)
signal state_changed(old_state: int, new_state: int)

# Constants
const MAX_ITEMS: int = 100

# Private state (prefix with _)
var _items: Array[Node] = []
var _is_initialized: bool = false

# DOCU: Initialize manager on autoload
# Last Updated At: 2026-07-22
# @author YourName
func _ready() -> void:
    _initialize()
    print("%s: Initialized" % name)

func _initialize() -> void:
    if _is_initialized:
        return
    _is_initialized = true
    # Setup code here

# DOCU: Register an item with the manager
# @param item: The item node to register
# @return: bool - True if successfully registered
# Last Updated At: 2026-07-22
# @author YourName
func registerItem(item: Node) -> bool:
    if item in _items:
        push_warning("Item already registered: %s" % item.name)
        return false

    if _items.size() >= MAX_ITEMS:
        push_error("Cannot register item: MAX_ITEMS reached")
        return false

    _items.append(item)
    item_registered.emit(item)
    return true

# DOCU: Unregister an item (cleanup)
# @param item: The item to remove
# Last Updated At: 2026-07-22
# @author YourName
func unregisterItem(item: Node) -> void:
    if item not in _items:
        return
    _items.erase(item)

# DOCU: Get all registered items
# @return: Array[Node] - Copy of items array
# Last Updated At: 2026-07-22
# @author YourName
func getItems() -> Array[Node]:
    return _items.duplicate()
```

### Registering Managers in `project.godot`

```ini
[autoload]

EventBus="*res://scripts/systems/managers/EventBus.gd"
GameStateManager="*res://scripts/systems/managers/GameStateManager.gd"
AudioManager="*res://scripts/systems/managers/AudioManager.gd"
TimerManager="*res://scripts/systems/managers/TimerManager.gd"
Constants="*res://scripts/systems/managers/Constants.gd"
```

**Note**: The `*` prefix makes the node globally accessible.

### Common Manager Types

| Manager | Responsibility | Example Usage |
|---------|---------------|---------------|
| `EventBus` | Central signal hub | `EventBus.game_started.emit()` |
| `GameStateManager` | Game state coordination | `GameStateManager.local_player_id` |
| `AudioManager` | Sound playback | `AudioManager.playSfx("explosion")` |
| `TimerManager` | Centralized timers | `TimerManager.pauseCategory("gameplay")` |
| `SaveManager` | Persistence | `SaveManager.saveGame(save_data)` |
| `SettingsManager` | Configuration | `SettingsManager.getVolume()` |
| `CameraManager` | Camera control | `CameraManager.lockCamera()` |
| `Constants` | Game constants | `Constants.MAX_HEALTH` |

### Example from Mocha Kombat

```gdscript
# File: scripts/systems/managers/SfxManager.gd (simplified)
extends Node

var _sfx_player_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
    _initializePool()

func playSfx(sfx_name: String, volume_db: float = 0.0) -> void:
    var player = _getAvailablePlayer()
    if not player:
        return

    var stream = _loadSfxStream(sfx_name)
    if stream:
        player.stream = stream
        player.volume_db = volume_db
        player.play()

func _getAvailablePlayer() -> AudioStreamPlayer:
    for player in _sfx_player_pool:
        if not player.playing:
            return player
    return null
```

---

## EventBus Signal Architecture

The **EventBus** is a central singleton for **signal-driven communication** between decoupled components. It prevents tight coupling from direct node references.

### Why EventBus?

**Without EventBus** (tight coupling):
```gdscript
# Player.gd
var hud_node: HUD = null  # Direct reference = fragile

func _ready() -> void:
    hud_node = get_node("/root/Game/HUD")  # Hardcoded path!

func takeDamage(amount: int) -> void:
    health -= amount
    hud_node.updateHealthBar(health)  # Direct call
```

**With EventBus** (loose coupling):
```gdscript
# Player.gd
func takeDamage(amount: int) -> void:
    health -= amount
    EventBus.health_changed.emit(player_id, health)  # Fire and forget

# HUD.gd
func _ready() -> void:
    EventBus.health_changed.connect(_onHealthChanged)

func _onHealthChanged(player_id: int, new_health: int) -> void:
    if player_id != my_player_id:
        return
    health_bar.value = new_health
```

**Benefits**:
- Player doesn't know HUD exists
- HUD can be removed without breaking Player
- Easy to add observers (damage VFX, sound, analytics)
- Multi-instance support via `player_id` parameter

### EventBus Template

```gdscript
# File: scripts/systems/managers/EventBus.gd
# DOCU: Central signal hub for cross-component communication
# Last Updated At: 2026-07-22
# @author YourName
extends Node

# ==================== LIFECYCLE SIGNALS ====================
signal game_started(player_id: int)
signal game_paused(player_id: int, is_paused: bool)
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_complete(scene_name: String)

# ==================== GAMEPLAY SIGNALS ====================
signal score_changed(player_id: int, new_score: int)
signal health_changed(player_id: int, new_health: int)
signal item_collected(player_id: int, item: Node)
signal enemy_defeated(player_id: int, enemy: Node)

# ==================== UI SIGNALS ====================
signal modal_opened(player_id: int, modal_type: String)
signal modal_closed(player_id: int, modal_type: String)
signal notification_shown(player_id: int, message: String, duration: float)

# ==================== OPTIMIZATION FLAGS ====================
var is_scene_transitioning: bool = false  # Suppress cleanup signals

# ==================== HELPER METHODS ====================
# DOCU: Emit game started event with logging
# @param player_id: The player ID who started the game
# Last Updated At: 2026-07-22
# @author YourName
func emitGameStarted(player_id: int) -> void:
    game_started.emit(player_id)
    print("EventBus: game_started emitted for player %d" % player_id)

# DOCU: Emit score change with validation
# @param player_id: The player whose score changed
# @param new_score: The new score value
# Last Updated At: 2026-07-22
# @author YourName
func emitScoreChanged(player_id: int, new_score: int) -> void:
    if new_score < 0:
        push_warning("EventBus: Negative score emitted (%d)" % new_score)
    score_changed.emit(player_id, new_score)
```

### Signal Naming Conventions

1. **Past tense**: `item_collected` (not `collect_item`)
2. **Include `player_id`**: For multi-instance routing
3. **Descriptive**: `health_changed` is clearer than `health_update`

### Usage Pattern

```gdscript
# Component A (emits event)
class_name ScorePickup
extends Area2D

func _onBodyEntered(body: Node2D) -> void:
    if body is Player:
        EventBus.item_collected.emit(body.player_id, self)
        queue_free()

# Component B (listens to event)
class_name ScoreManager
extends Node

func _ready() -> void:
    EventBus.item_collected.connect(_onItemCollected)

func _onItemCollected(player_id: int, item: Node) -> void:
    var points = 10
    EventBus.score_changed.emit(player_id, _scores[player_id] + points)
```

### Multi-Instance Routing Pattern

All EventBus signals include `player_id` to support local multiplayer:

```gdscript
# HUD.gd (player-specific UI)
class_name HUD
extends Control

var my_player_id: int = 1  # Set externally

func _ready() -> void:
    EventBus.score_changed.connect(_onScoreChanged)

func _onScoreChanged(player_id: int, new_score: int) -> void:
    if player_id != my_player_id:
        return  # Ignore other players
    score_label.text = "Score: %d" % new_score
```

### Example from Mocha Kombat

```gdscript
# EventBus.gd (excerpt)
signal card_spawned(player_id: int, card: Card)
signal recipe_completed(player_id: int, recipe: RecipeData, cards: Array)
signal combo_changed(player_id: int, combo: int, rank: String)

# Card.gd
func _onTreeExiting() -> void:
    if EventBus and not EventBus.is_scene_transitioning:
        EventBus.card_deleted.emit(player_id, self)  # Suppress during scene change

# HUD.gd
func _ready() -> void:
    EventBus.combo_changed.connect(_onComboChanged)

func _onComboChanged(player_id: int, combo: int, rank: String) -> void:
    if player_id != GameStateManager.local_player_id:
        return
    combo_label.text = "Combo: %s" % rank
```

---

## Component Architecture

Components are **self-contained, reusable scene + script pairs** that follow a consistent structure.

### Directory Structure

```
scenes/
└── components/
    └── ComponentName/          # PascalCase folder
        ├── ComponentName.tscn  # Scene file
        └── ComponentName.gd    # Script file (optional, can be in scripts/)
```

**Alternative Pattern** (Mocha Kombat uses this):
```
scenes/components/Card/Card.tscn
scripts/entities/Card.gd  # Script separated from scene
```

### Component Script Template

```gdscript
# DOCU: Brief description of component's purpose
# Last Updated At: 2026-07-22
# @author YourName
class_name ComponentName
extends Node2D  # or Control for UI elements

# ==================== SIGNALS ====================
signal component_ready
signal action_completed(data: Dictionary)

# ==================== ENUMS ====================
enum State { IDLE, ACTIVE, DISABLED }

# ==================== EXPORTED VARIABLES ====================
@export var is_enabled: bool = true
@export_range(0, 100) var max_value: int = 100:
    set(value):
        max_value = clamp(value, 0, 100)
        _onMaxValueChanged()

@export_group("Visual Settings")
@export var sprite_color: Color = Color.WHITE

# ==================== PRIVATE VARIABLES ====================
var _current_state: State = State.IDLE
var _is_initialized: bool = false

# ==================== NODE REFERENCES ====================
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

# ==================== LIFECYCLE METHODS ====================
# DOCU: Initialize component when entering scene tree
# Last Updated At: 2026-07-22
# @author YourName
func _ready() -> void:
    _initialize()
    _connectSignals()
    _changeState(State.IDLE)

func _initialize() -> void:
    if _is_initialized:
        return
    _is_initialized = true
    add_to_group("ComponentName")  # For global queries
    component_ready.emit()

# DOCU: Connect internal signals
# Last Updated At: 2026-07-22
# @author YourName
func _connectSignals() -> void:
    if _animation_player:
        _animation_player.animation_finished.connect(_onAnimationFinished)

# ==================== STATE MANAGEMENT ====================
# DOCU: Change component state with validation
# @param new_state: The state to transition to
# Last Updated At: 2026-07-22
# @author YourName
func _changeState(new_state: State) -> void:
    if _current_state == new_state:
        return

    var previous_state = _current_state
    _current_state = new_state

    match _current_state:
        State.IDLE:
            _handleIdleState(previous_state)
        State.ACTIVE:
            _handleActiveState(previous_state)
        State.DISABLED:
            _handleDisabledState(previous_state)

func _handleIdleState(previous_state: State) -> void:
    _animation_player.play("idle")

func _handleActiveState(previous_state: State) -> void:
    _animation_player.play("active")

func _handleDisabledState(previous_state: State) -> void:
    modulate.a = 0.5

# ==================== PUBLIC API ====================
# DOCU: Activate the component
# @return: bool - True if activation was successful
# Last Updated At: 2026-07-22
# @author YourName
func activate() -> bool:
    if not is_enabled or _current_state == State.DISABLED:
        push_warning("Cannot activate: component disabled")
        return false

    _changeState(State.ACTIVE)
    return true

# DOCU: Deactivate the component
# Last Updated At: 2026-07-22
# @author YourName
func deactivate() -> void:
    _changeState(State.IDLE)

# ==================== PRIVATE HELPERS ====================
func _onMaxValueChanged() -> void:
    # React to exported variable change
    pass

func _onAnimationFinished(anim_name: String) -> void:
    if anim_name == "active":
        _changeState(State.IDLE)
```

### Key Patterns

1. **`class_name` Declaration**: Enables type hints (`var card: Card`)
2. **`@onready` for Node References**: Defers node queries until `_ready()`
3. **Setters for Exported Variables**: Validate and react to Inspector changes
4. **State Machine Pattern**: `enum State` + `match` statement
5. **Private Prefix**: `_` for internal methods and variables
6. **Signal Emissions**: Notify external systems of state changes

### Example from Mocha Kombat

```gdscript
# File: scripts/entities/Card.gd (simplified)
class_name Card
extends Node2D

signal drag_started(card: Card)
signal drag_ended(card: Card)
signal stacked_on(bottom_card: Card)

enum CardState { IDLE, DRAGGING, STACKED, ANIMATING }

@export var card_data: CardData = null:
    set(value):
        card_data = value
        if is_node_ready():
            _updateVisuals()

var _current_state: CardState = CardState.IDLE
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _drag_area: Area2D = $DragArea

func _ready() -> void:
    add_to_group("Card")
    _connectSignals()
    _updateVisuals()

func _connectSignals() -> void:
    _drag_area.input_event.connect(_onDragAreaInputEvent)

func startDrag() -> void:
    if _current_state != CardState.IDLE:
        return
    _current_state = CardState.DRAGGING
    z_index = 1000
    drag_started.emit(self)

func _updateVisuals() -> void:
    if card_data and card_data.card_texture:
        _sprite.texture = card_data.card_texture
```

---

## Component & Entity Lifecycle Events

Understanding **component lifecycle patterns** is crucial for building extensible game systems. Mocha Kombat uses a multi-stage initialization pattern with virtual methods that subclasses can override.

### Why Lifecycle Events?

**Without lifecycle hooks**, extending components requires copy-pasting entire methods:
```gdscript
# Bad: Override entire _ready()
func _ready() -> void:
    # Copy-paste 50 lines from parent
    # Add 2 lines of custom logic
```

**With lifecycle hooks**, subclasses extend specific stages:
```gdscript
# Good: Override targeted hook
func onInitialize() -> void:
    # 2 lines of custom initialization
    # Parent handles the rest
```

---

### Base Godot Lifecycle

All nodes follow Godot's standard lifecycle:

```gdscript
func _enter_tree() -> void:
    # Node added to tree (early stage, before _ready)
    # Children may not be ready yet

func _ready() -> void:
    # Node fully initialized (all children ready)
    # Safe to access child nodes

func _process(delta: float) -> void:
    # Called every frame
    # Use for continuous updates

func _physics_process(delta: float) -> void:
    # Called every physics frame (fixed timestep)
    # Use for physics calculations

func _exit_tree() -> void:
    # Node removed from tree
    # Cleanup signals, timers, references
```

**Order**: `_enter_tree()` → `_ready()` → `_process()`/`_physics_process()` (loop) → `_exit_tree()`

---

### Multi-Stage Initialization Pattern

Break `_ready()` into focused stages for clarity and extensibility:

```gdscript
class_name GameEntity
extends Node2D

func _ready() -> void:
    initialize()           # 1. Data assignment
    _setupVisuals()        # 2. Visual representation
    _connectSignals()      # 3. Signal wiring
    _registerTimers()      # 4. Timer registration
    _postInitialize()      # 5. Post-setup hooks

# DOCU: Initialize entity with data
# Override this in subclasses for custom initialization
# Last Updated At: 2026-07-22
# @author YourName
func initialize(data: Resource = null) -> void:
    if _is_initialized:
        return
    _is_initialized = true
    entity_data = data
    onInitialize()         # Virtual hook

# DOCU: Virtual hook for subclass initialization
# Last Updated At: 2026-07-22
# @author YourName
func onInitialize() -> void:
    pass  # Override in subclass

func _setupVisuals() -> void:
    # Apply textures, colors, labels from entity_data
    pass

func _connectSignals() -> void:
    # Connect internal signals
    pass

func _registerTimers() -> void:
    # Register with TimerManager
    pass

func _postInitialize() -> void:
    # Trigger spawn events, play animations
    onSpawn()              # Virtual hook

# DOCU: Virtual hook called after full initialization
# Last Updated At: 2026-07-22
# @author YourName
func onSpawn() -> void:
    pass  # Override in subclass
```

**Benefits**:
- **Predictable order**: Always same sequence
- **Extensible**: Subclasses override specific stages
- **Debuggable**: Breakpoint each stage independently

---

### Lifecycle Stages Table

| **Stage** | **When** | **Purpose** | **Override Pattern** |
|-----------|----------|-------------|---------------------|
| `_enter_tree()` | Node added to tree | Early setup (before children ready) | Rarely override |
| `_ready()` | All children ready | Trigger initialization sequence | Call substages |
| `initialize(data)` | Called from `_ready()` | Data assignment | Override `onInitialize()` |
| `_setupVisuals()` | After `initialize()` | Apply visual properties | Override if custom visuals |
| `_connectSignals()` | After visuals | Wire up signals | Override to add signals |
| `_registerTimers()` | After signals | Register with TimerManager | Override for custom timers |
| `onSpawn()` | After full init | Post-spawn events (animations, signals) | Override for spawn behavior |
| `_process(delta)` | Every frame | Continuous updates | Override for frame logic |
| `onActivate()` | User-triggered | Transition to active state | Override for activation |
| `onDeactivate()` | User-triggered | Transition to inactive state | Override for deactivation |
| `_exit_tree()` | Node removed | Cleanup | Call `onDestroy()` hook |
| `onDestroy()` | Before deletion | Unregister timers, disconnect signals | Override for cleanup |

---

### Virtual Method Pattern

**Base class provides hooks, subclasses extend without replacing core logic:**

```gdscript
# Base class (CardAction.gd from Mocha Kombat)
class_name CardAction
extends RefCounted

var card: Card
var action_data: CardActionData

# DOCU: Initialize action with card reference and data
# @param _card: The card this action belongs to
# @param _action_data: Configuration data for this action
# Last Updated At: 2026-07-22
# @author YourName
func initialize(_card: Card, _action_data: CardActionData) -> void:
    card = _card
    action_data = _action_data
    onInitialize()         # Virtual hook

# DOCU: Virtual hook for subclass initialization
# Override to setup timers, connect signals, etc.
# Last Updated At: 2026-07-22
# @author YourName
func onInitialize() -> void:
    pass  # Override in subclass

# DOCU: Frame processing
# @param delta: Frame delta time
# Last Updated At: 2026-07-22
# @author YourName
func process(delta: float) -> void:
    pass  # Override for time-based behavior

# DOCU: Cleanup before deletion
# Last Updated At: 2026-07-22
# @author YourName
func onDestroy() -> void:
    pass  # Override to unregister timers, disconnect signals
```

**Subclass Example** (SpoilageAction):

```gdscript
class_name SpoilageAction
extends CardAction

var spoilage_timer: float = 0.0
var spoil_time: float = 10.0
var is_paused: bool = false
var timer_adapter: DeltaTimerAdapter

# Override: Setup timer on initialization
func onInitialize() -> void:
    var spoil_data = action_data as SpoilageActionData
    spoil_time = spoil_data.spoil_time

    # Register timer with TimerManager
    var timer_id = "card_%d_spoilage" % card.get_instance_id()
    timer_adapter = DeltaTimerAdapter.new(
        self, "spoilage_timer", "", timer_id, "card_spoilage"
    )
    TimerManager.registerTimer(timer_adapter)

# Override: Update spoilage countdown
func process(delta: float) -> void:
    if is_paused:
        return

    var scaled_delta = timer_adapter.getScaledDelta(delta)
    spoilage_timer += scaled_delta

    # Update progress bar
    var progress = (spoilage_timer / spoil_time) * 100.0
    card.action_progress.value = 100.0 - progress

    # Trigger spoilage when timer expires
    if spoilage_timer >= spoil_time:
        _triggerSpoilage()

# Override: Cleanup timer
func onDestroy() -> void:
    var timer_id = "card_%d_spoilage" % card.get_instance_id()
    TimerManager.unregisterTimer(timer_id)

# Public API (not virtual)
func pauseSpoilage() -> void:
    is_paused = true

func resumeSpoilage() -> void:
    is_paused = false
```

**Key Pattern**: Base class defines **when** hooks are called, subclasses define **what** happens.

---

### Drag Lifecycle Events

Draggable entities (cards, furniture, items) follow a drag lifecycle:

```gdscript
class_name Draggable
extends Node2D

signal drag_started(entity: Draggable)
signal drag_ended(entity: Draggable, start_pos: Vector2, end_pos: Vector2)
signal drag_cancelled(entity: Draggable)

var _is_dragging: bool = false
var _drag_start_position: Vector2

# ==================== DRAG LIFECYCLE ====================

# 1. Drag Start
func _startDrag() -> void:
    if not _canStartDrag():  # Virtual validation
        return

    _is_dragging = true
    _drag_start_position = global_position
    z_index = 1000  # Bring to front

    onDragStart()  # Virtual hook
    drag_started.emit(self)

# 2. Drag Update (every frame while dragging)
func _process(delta: float) -> void:
    if _is_dragging:
        _processDragMovement(delta)
        onDragUpdate(delta)  # Virtual hook

func _processDragMovement(delta: float) -> void:
    var target_pos = get_global_mouse_position() + _drag_offset
    target_pos = _clampToBounds(target_pos)
    global_position = target_pos

# 3. Drag End
func _endDrag() -> void:
    if not _canEndDrag():  # Virtual validation
        _cancelDrag()
        return

    _is_dragging = false
    z_index = _original_z_index

    onDragEnd()  # Virtual hook
    drag_ended.emit(self, _drag_start_position, global_position)

# 4. Drag Cancel
func _cancelDrag() -> void:
    global_position = _drag_start_position  # Revert position
    _is_dragging = false

    onDragCancel()  # Virtual hook
    drag_cancelled.emit(self)

# ==================== VIRTUAL HOOKS ====================

func _canStartDrag() -> bool:
    return true  # Override to add validation

func onDragStart() -> void:
    pass  # Override: Pause timers, lock camera

func onDragUpdate(delta: float) -> void:
    pass  # Override: Rotation, VFX trails

func _canEndDrag() -> bool:
    return true  # Override: Check for overlaps

func onDragEnd() -> void:
    pass  # Override: Grid snap, save position

func onDragCancel() -> void:
    pass  # Override: Play error sound
```

**Subclass Example** (DisplayStand blocks drag when cards on top):

```gdscript
class_name DisplayStand
extends Draggable

# Override: Block drag if cards are slotted
func _canStartDrag() -> bool:
    if _hasOverlappingCards():
        return false  # Can't drag furniture with cards on it
    return super._canStartDrag()

# Override: Play placement sound
func onDragEnd() -> void:
    SfxManager.playSfx("furniture_place")
    super.onDragEnd()
```

---

### Activation/Deactivation Pattern

Entities can transition between active/inactive states:

```gdscript
class_name ActivatableEntity
extends Node2D

enum State { INACTIVE, ACTIVATING, ACTIVE, DEACTIVATING }

var _current_state: State = State.INACTIVE

# DOCU: Activate the entity
# @return: bool - True if activation successful
# Last Updated At: 2026-07-22
# @author YourName
func activate() -> bool:
    if _current_state != State.INACTIVE:
        return false

    _current_state = State.ACTIVATING
    onActivate()  # Virtual hook
    _current_state = State.ACTIVE
    return true

# DOCU: Deactivate the entity
# Last Updated At: 2026-07-22
# @author YourName
func deactivate() -> void:
    if _current_state != State.ACTIVE:
        return

    _current_state = State.DEACTIVATING
    onDeactivate()  # Virtual hook
    _current_state = State.INACTIVE

# ==================== VIRTUAL HOOKS ====================

func onActivate() -> void:
    pass  # Override: Start timers, play animations

func onDeactivate() -> void:
    pass  # Override: Pause timers, grey out visuals
```

**Example from Mocha Kombat** (Customer enters patience phase):

```gdscript
# Customer.gd
func _startPatience() -> void:  # Activation
    is_active = true
    _patience_timer = 0.0
    _patience_duration = _calculateWaitTime()
    onActivate()  # Virtual hook for CustomerActions

func _onPatienceTimeout() -> void:  # Deactivation
    is_active = false
    onDeactivate()  # Virtual hook
    _abandonOrder()
```

---

### Deferred Initialization Pattern

Sometimes initialization must wait for scene tree to be ready:

```gdscript
# Pattern 1: call_deferred()
func _enter_tree() -> void:
    call_deferred("_connectSignals")  # Wait for Area2D children

func _connectSignals() -> void:
    # Now safe to access $Area2D child nodes
    $DragArea.input_event.connect(_onDragInput)

# Pattern 2: await get_tree().process_frame
func loadSavedCards(card_ids: Array) -> void:
    for card_id in card_ids:
        spawnCard(card_id)

    await get_tree().process_frame  # Wait for all cards to be added

    # Now safe to reference spawned cards
    _connectCardSignals()
```

**When to use**:
- **`call_deferred()`**: Waiting for children to be added to tree
- **`await process_frame`**: Waiting for multiple spawn operations to complete

---

### Factory Reset Pattern (Object Pooling)

Entities designed for pooling implement a `_resetState()` method:

```gdscript
class_name PoolableEntity
extends Node2D

var _is_initialized: bool = false

func initialize(data: Resource) -> void:
    entity_data = data
    _setupVisuals()
    _is_initialized = true

# DOCU: Reset entity to factory state for pooling
# Last Updated At: 2026-07-22
# @author YourName
func _resetState() -> void:
    entity_data = null
    _is_initialized = false

    # Reset visual state
    modulate = Color.WHITE
    scale = Vector2.ONE
    rotation = 0.0

    # Reset gameplay state
    _current_state = State.IDLE
    _timers.clear()

    # Reset signals (disconnect all)
    for connection in get_incoming_connections():
        connection.signal.disconnect(connection.callable)

    onReset()  # Virtual hook

func onReset() -> void:
    pass  # Override for custom reset logic

# Usage in object pool
func returnToPool() -> void:
    _resetState()
    get_parent().remove_child(self)
    EntityPool.returnEntity(self)
```

**Example from Mocha Kombat** (Customer pooling):

```gdscript
# Customer.gd
func customerLeave() -> void:
    # Unregister timers
    for timer_id in _registered_timers:
        TimerManager.unregisterTimer(timer_id)

    customer_left.emit(self)
    _resetState()  # Factory reset
    queue_free()

func _resetState() -> void:
    customer_data = null
    _collected_items.clear()
    _served_cards.clear()
    _active_actions.clear()
    _patience_timer = 0.0
    _ordering_timer = 0.0
    _standby_timer = 0.0
    is_active = false
    _resetTweens()
    _resetStatusLabels()
```

---

### Signal-Based Lifecycle Coordination

Components emit signals at lifecycle stages for external observers:

```gdscript
class_name LifecycleEntity
extends Node2D

signal spawned(entity: LifecycleEntity)
signal activated(entity: LifecycleEntity)
signal deactivated(entity: LifecycleEntity)
signal destroyed(entity: LifecycleEntity)

func _ready() -> void:
    initialize()
    spawned.emit(self)

func activate() -> void:
    _current_state = State.ACTIVE
    activated.emit(self)

func deactivate() -> void:
    _current_state = State.INACTIVE
    deactivated.emit(self)

func _exit_tree() -> void:
    destroyed.emit(self)
```

**External observers** hook into lifecycle without coupling:

```gdscript
# EntityTracker.gd (manager)
func _ready() -> void:
    EventBus.entity_spawned.connect(_onEntitySpawned)

func _onEntitySpawned(entity: LifecycleEntity) -> void:
    entity.activated.connect(_onEntityActivated)
    entity.destroyed.connect(_onEntityDestroyed)
    _tracked_entities.append(entity)
```

---

### Complete Lifecycle Example (Card from Mocha Kombat)

**Initialization Flow**:
```gdscript
# Card.gd (simplified)
func _ready() -> void:
    initialize(card_data)      # 1. Data assignment
    _connectSignals()          # 2. Signal wiring
    _registerBackgroundTimers() # 3. Timer registration

func initialize(data: CardData, board_state: PlayerBoardState = null) -> void:
    card_data = data
    board_state = board_state if board_state else GameStateManager.getLocalPlayerBoardState()
    _setupVisuals()            # Visual setup
    _instantiateActions()      # Create CardAction instances
    onInitialize()             # Virtual hook

func _setupVisuals() -> void:
    $Sprite.texture = card_data.card_texture
    $NameLabel.text = card_data.display_name
    # ... color, progress bars, etc.

func _instantiateActions() -> void:
    for action_data in card_data.card_actions:
        var action = action_data.createAction(self)
        action.onInitialize()  # Lifecycle hook
        _active_actions.append(action)
```

**Drag Lifecycle**:
```gdscript
# User clicks card
func _onInputEvent(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        _startDrag()

func _startDrag() -> void:
    _is_dragging = true
    z_index = 1000

    # Notify actions (pause timers, hide UI)
    for action in _active_actions:
        action.onDragStart()

    drag_started.emit(self)

# User releases mouse
func _onInputEvent(event: InputEvent) -> void:
    if event is InputEventMouseButton and not event.pressed:
        _tryStackAtCurrentPosition()

func _tryStackAtCurrentPosition() -> void:
    var target_card = _getCardUnderMouse()
    if target_card:
        _stackOn(target_card)
    _endDrag()

func _endDrag() -> void:
    _is_dragging = false
    z_index = _original_z_index

    # Notify actions (resume timers)
    for action in _active_actions:
        action.onDragEnd()

    drag_ended.emit(self)
```

**Cleanup**:
```gdscript
func _exit_tree() -> void:
    # Notify actions to cleanup
    for action in _active_actions:
        action.onDestroy()

    # Unregister timers
    for timer_id in _registered_timers:
        TimerManager.unregisterTimer(timer_id)

    # Emit signal (unless scene transitioning)
    if EventBus and not EventBus.is_scene_transitioning:
        EventBus.card_deleted.emit(player_id, self)
```

---

### Key Takeaways

1. **Multi-stage initialization** prevents order-dependency bugs
2. **Virtual hooks** (`onInitialize`, `onSpawn`, `onActivate`) enable clean subclassing
3. **Drag lifecycle** (`onDragStart` → `onDragUpdate` → `onDragEnd/Cancel`) standardizes draggable entities
4. **Signal-based coordination** decouples lifecycle observers from entities
5. **Factory reset** (`_resetState()`) enables efficient object pooling
6. **Deferred initialization** (`call_deferred`, `await`) handles tree readiness safely

**Mocha Kombat Example**: Card system uses **all** these patterns—300+ lines of Card.gd orchestrate initialization, drag, stacking, recipes, and cleanup through virtual hooks that 15+ CardAction subclasses override.

---

## Resource-Based Data Design

Custom resources enable **data-driven game design** where game balance and content live in editable `.tres` files instead of hardcoded scripts.

### Why Resources?

**Without Resources** (hardcoded):
```gdscript
# Player.gd
var health: int = 100
var speed: float = 200.0
var sprite_texture = preload("res://player.png")
```
**Problem**: Changing values requires editing code, restarting editor.

**With Resources** (data-driven):
```gdscript
# PlayerData.gd (resource script)
class_name PlayerData
extends Resource

@export var health: int = 100
@export var speed: float = 200.0
@export var sprite_texture: Texture2D

# Player.gd (component script)
@export var player_data: PlayerData

func _ready() -> void:
    health = player_data.health
    $Sprite.texture = player_data.sprite_texture
```
**Benefit**: Designers edit values in Inspector, changes apply instantly.

### Resource Script Template

```gdscript
# File: resources/items/ItemData.gd
# DOCU: Data resource for game items
# Last Updated At: 2026-07-22
# @author YourName
class_name ItemData
extends Resource

# ==================== ENUMS ====================
enum ItemType { CONSUMABLE, EQUIPMENT, QUEST_ITEM }
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
@export var tags: Array[String] = []

# ==================== VALIDATION ====================
# DOCU: Validate resource data for required fields
# @return: bool - True if all required fields are valid
# Last Updated At: 2026-07-22
# @author YourName
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
# @author YourName
func hasTag(tag: String) -> bool:
    return tag in tags

# DOCU: Check if item can stack with another
# @param other: The ItemData to compare with
# @return: bool - True if items can stack
# Last Updated At: 2026-07-22
# @author YourName
func canStackWith(other: ItemData) -> bool:
    return other != null and item_id == other.item_id
```

### Creating Resource Instances

**Method 1: In Godot Inspector**
1. Create new resource file: Right-click in FileSystem → New Resource
2. Search for `ItemData` → Create
3. Edit properties in Inspector
4. Save as `HealthPotion.tres`

**Method 2: Via Script**
```gdscript
# Create resource at runtime
var item = ItemData.new()
item.item_id = "health_potion"
item.display_name = "Health Potion"
item.description = "Restores 50 HP"
item.rarity = ItemData.Rarity.COMMON
```

### Resource File Format (`.tres`)

```tres
[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/items/ItemData.gd" id="1_abc123"]

[resource]
script = ExtResource("1_abc123")
item_id = "health_potion"
display_name = "Health Potion"
item_type = 0  # CONSUMABLE
description = "Restores 50 HP when consumed"
rarity = 0  # COMMON
stack_limit = 20
tags = PackedStringArray("healing", "consumable")
```

### Example from Mocha Kombat

```gdscript
# File: resources/cards/CardData.gd (simplified)
class_name CardData
extends Resource

enum CardType { INGREDIENT, MACHINE, PROBLEM, UPGRADE }

@export var card_id: String = ""
@export var display_name: String = ""
@export var card_type: CardType = CardType.INGREDIENT
@export var card_texture: Texture2D
@export var stack_limit: int = 5

func canStackWith(other_card: CardData) -> bool:
    if other_card == null:
        return false
    return card_id == other_card.card_id
```

**Usage in Card.gd**:
```gdscript
@export var card_data: CardData

func _ready() -> void:
    if card_data:
        $NameLabel.text = card_data.display_name
        $Sprite.texture = card_data.card_texture
```

**225+ CardData resources** in Mocha Kombat enable rapid content creation without touching code.

---

## Drag & Drop System

A **reusable base class** for draggable entities (cards, furniture, inventory items). Eliminates duplicate drag logic across components.

### Base Class Template

```gdscript
# File: scripts/entities/Draggable.gd
# DOCU: Base class for draggable entities with bounds enforcement
# Last Updated At: 2026-07-22
# @author YourName
class_name Draggable
extends Node2D

# ==================== SIGNALS ====================
signal drag_started(entity: Draggable)
signal drag_ended(entity: Draggable, start_pos: Vector2, end_pos: Vector2)
signal drag_cancelled(entity: Draggable)
signal repositioned(entity: Draggable, start_pos: Vector2, end_pos: Vector2, distance: float)

# ==================== EXPORTED PROPERTIES ====================
@export var is_draggable: bool = true
@export var prevent_overlap: bool = true
@export var drag_area: Area2D  # Area2D for input detection
@export var enable_rotation_on_drag: bool = false

# ==================== BOARD BOUNDS ====================
var board_bounds: Rect2 = Rect2()
var board_polygon: PackedVector2Array = PackedVector2Array()

# ==================== DRAG STATE ====================
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_start_position: Vector2 = Vector2.ZERO
var _original_z_index: int = 0
var _previous_position: Vector2 = Vector2.ZERO

# ==================== LIFECYCLE ====================
func _ready() -> void:
    if drag_area and is_draggable:
        drag_area.input_event.connect(_onDragAreaInputEvent)
        drag_area.area_entered.connect(_onAreaEntered)

func _process(delta: float) -> void:
    if _is_dragging:
        _processDragMovement(delta)

# ==================== DRAG LIFECYCLE ====================
# DOCU: Start dragging the entity
# Last Updated At: 2026-07-22
# @author YourName
func _startDrag() -> void:
    if not is_draggable:
        return

    _is_dragging = true
    _drag_start_position = global_position
    _drag_offset = global_position - get_global_mouse_position()
    _original_z_index = z_index
    z_index = 1000  # Bring to front

    # Lock camera during drag (if using camera manager)
    if has_node("/root/CameraManager"):
        get_node("/root/CameraManager").lockCamera()

    drag_started.emit(self)

# DOCU: Process drag movement during _process()
# @param delta: Frame delta time
# Last Updated At: 2026-07-22
# @author YourName
func _processDragMovement(delta: float) -> void:
    _previous_position = global_position
    var target_position = get_global_mouse_position() + _drag_offset

    # Enforce bounds
    target_position = _clampToBounds(target_position)

    global_position = target_position

    # Optional rotation based on velocity
    if enable_rotation_on_drag:
        var velocity = global_position - _previous_position
        if velocity.length() > 1.0:
            rotation = lerp_angle(rotation, velocity.angle(), 0.1)

# DOCU: End dragging and validate placement
# Last Updated At: 2026-07-22
# @author YourName
func _endDrag() -> void:
    if prevent_overlap and _hasOverlapping():
        _cancelDrag()
        return

    _is_dragging = false
    z_index = _original_z_index

    # Unlock camera
    if has_node("/root/CameraManager"):
        get_node("/root/CameraManager").unlockCamera()

    drag_ended.emit(self, _drag_start_position, global_position)

    # Emit repositioned if moved significantly
    var distance = _drag_start_position.distance_to(global_position)
    if distance >= 10.0:
        repositioned.emit(self, _drag_start_position, global_position, distance)

# DOCU: Cancel drag and return to start position
# Last Updated At: 2026-07-22
# @author YourName
func _cancelDrag() -> void:
    global_position = _drag_start_position
    _is_dragging = false
    z_index = _original_z_index

    if has_node("/root/CameraManager"):
        get_node("/root/CameraManager").unlockCamera()

    drag_cancelled.emit(self)

# ==================== BOUNDS ENFORCEMENT ====================
# DOCU: Clamp position to board bounds
# @param pos: The position to clamp
# @return: Vector2 - Clamped position
# Last Updated At: 2026-07-22
# @author YourName
func _clampToBounds(pos: Vector2) -> Vector2:
    if board_polygon.size() > 0:
        # Polygon bounds (more complex)
        return _clampToPolygon(pos)
    elif board_bounds.size != Vector2.ZERO:
        # Rect2 bounds (simple)
        return Vector2(
            clamp(pos.x, board_bounds.position.x, board_bounds.end.x),
            clamp(pos.y, board_bounds.position.y, board_bounds.end.y)
        )
    return pos

func _clampToPolygon(pos: Vector2) -> Vector2:
    # Check if point is inside polygon
    if Geometry2D.is_point_in_polygon(pos, board_polygon):
        return pos

    # Find nearest point on polygon edge
    var nearest_point = pos
    var min_distance = INF

    for i in range(board_polygon.size()):
        var p1 = board_polygon[i]
        var p2 = board_polygon[(i + 1) % board_polygon.size()]
        var closest = Geometry2D.get_closest_point_to_segment(pos, p1, p2)
        var distance = pos.distance_to(closest)

        if distance < min_distance:
            min_distance = distance
            nearest_point = closest

    return nearest_point

# ==================== OVERLAP DETECTION ====================
# DOCU: Check if entity overlaps with others
# @return: bool - True if overlapping
# Last Updated At: 2026-07-22
# @author YourName
func _hasOverlapping() -> bool:
    if not drag_area:
        return false

    var overlapping_areas = drag_area.get_overlapping_areas()
    for area in overlapping_areas:
        if area.get_parent() != self and area.get_parent() is Draggable:
            return true
    return false

# ==================== INPUT HANDLING ====================
func _onDragAreaInputEvent(viewport: Node, event: InputEvent, shape_idx: int) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _startDrag()
            else:
                if _is_dragging:
                    _endDrag()

func _onAreaEntered(area: Area2D) -> void:
    # Optional: visual feedback on overlap
    pass

# ==================== PUBLIC API ====================
# DOCU: Set rectangular bounds for dragging
# @param bounds: The Rect2 boundary
# Last Updated At: 2026-07-22
# @author YourName
func setBoardBounds(bounds: Rect2) -> void:
    board_bounds = bounds

# DOCU: Set polygon bounds for dragging
# @param polygon: The polygon boundary points
# Last Updated At: 2026-07-22
# @author YourName
func setBoardPolygon(polygon: PackedVector2Array) -> void:
    board_polygon = polygon

# DOCU: Check if currently dragging
# @return: bool - True if dragging
# Last Updated At: 2026-07-22
# @author YourName
func isDragging() -> bool:
    return _is_dragging

# ==================== SERIALIZATION ====================
# DOCU: Serialize entity state for saving
# @return: Dictionary - Serialized state
# Last Updated At: 2026-07-22
# @author YourName
func serializeState() -> Dictionary:
    return {
        "position": {"x": global_position.x, "y": global_position.y},
        "rotation": rotation,
        "z_index": z_index
    }

# DOCU: Restore entity state from save data
# @param data: Dictionary with serialized state
# Last Updated At: 2026-07-22
# @author YourName
func deserializeState(data: Dictionary) -> void:
    if data.has("position"):
        global_position = Vector2(data.position.x, data.position.y)
    if data.has("rotation"):
        rotation = data.rotation
    if data.has("z_index"):
        z_index = data.z_index
```

### Subclass Example

```gdscript
# File: scripts/entities/InventoryItem.gd
class_name InventoryItem
extends Draggable

@export var item_data: ItemData

func _ready() -> void:
    super._ready()  # Call parent _ready()
    _updateVisuals()

# Override drag validation
func _startDrag() -> void:
    if _isEquipped():
        push_warning("Cannot drag equipped item")
        return
    super._startDrag()

# Override drag end for grid snapping
func _endDrag() -> void:
    if SettingsManager.getGridEnabled():
        global_position = _snapToGrid(global_position)
    super._endDrag()

func _snapToGrid(pos: Vector2) -> Vector2:
    var grid_size = 64.0
    return Vector2(
        round(pos.x / grid_size) * grid_size,
        round(pos.y / grid_size) * grid_size
    )
```

### Example from Mocha Kombat

**Mocha Kombat's `Permanent.gd` base class** (443 lines) powers:
- `DisplayStand` — Furniture with card slotting
- `Pack` — Draggable card packs
- `CustomerTable` — Repositionable customer spawn points

**Before**: Each entity had 150+ lines of duplicate drag code.
**After**: Inherit from `Permanent`, override 2-3 methods.

---

## Timer Management System

Centralized timer control for **pause/resume**, **time scaling**, and **debugging** across all game timers.

### Why Centralized Timers?

**Without Timer Manager**:
- Pausing game requires finding all `Timer` nodes
- Time scaling needs manual `delta` adjustment everywhere
- Hard to debug timer states

**With Timer Manager**:
- **Global pause**: `TimerManager.pauseCategory("gameplay")`
- **Time scaling**: `TimerManager.setTimeScale(0.5)` for slow-motion
- **Debug view**: See all active timers in one place

### Timer Adapter Pattern

```gdscript
# File: scripts/systems/managers/TimerManager.gd
# DOCU: Centralized timer management with pause/scale control
# Last Updated At: 2026-07-22
# @author YourName
extends Node

signal timer_registered(timer_id: String, category: String)
signal timer_unregistered(timer_id: String)
signal category_paused(category: String)
signal category_resumed(category: String)

# ==================== TIMER STORAGE ====================
var registered_timers: Dictionary = {}  # timer_id -> DeltaTimerAdapter
var paused_categories: Array[String] = []
var time_scale: float = 1.0

# ==================== TIMER REGISTRATION ====================
# DOCU: Register a delta-based timer for management
# @param adapter: The DeltaTimerAdapter instance
# Last Updated At: 2026-07-22
# @author YourName
func registerTimer(adapter: DeltaTimerAdapter) -> void:
    if registered_timers.has(adapter.timer_id):
        push_warning("Timer already registered: %s" % adapter.timer_id)
        return

    registered_timers[adapter.timer_id] = adapter
    timer_registered.emit(adapter.timer_id, adapter.category)

# DOCU: Unregister a timer (call in _exit_tree())
# @param timer_id: The unique timer ID
# Last Updated At: 2026-07-22
# @author YourName
func unregisterTimer(timer_id: String) -> void:
    if registered_timers.erase(timer_id):
        timer_unregistered.emit(timer_id)

# ==================== PAUSE CONTROL ====================
# DOCU: Pause all timers in a category
# @param category: The category to pause ("gameplay", "ui", etc.)
# Last Updated At: 2026-07-22
# @author YourName
func pauseCategory(category: String) -> void:
    if category in paused_categories:
        return
    paused_categories.append(category)
    category_paused.emit(category)
    print("TimerManager: Paused category '%s'" % category)

# DOCU: Resume all timers in a category
# @param category: The category to resume
# Last Updated At: 2026-07-22
# @author YourName
func resumeCategory(category: String) -> void:
    if category not in paused_categories:
        return
    paused_categories.erase(category)
    category_resumed.emit(category)
    print("TimerManager: Resumed category '%s'" % category)

# DOCU: Check if a category is paused
# @param category: The category to check
# @return: bool - True if paused
# Last Updated At: 2026-07-22
# @author YourName
func isCategoryPaused(category: String) -> bool:
    return category in paused_categories

# ==================== TIME SCALING ====================
# DOCU: Set global time scale (for slow-motion, fast-forward)
# @param scale: The time scale multiplier (0.5 = half speed, 2.0 = double speed)
# Last Updated At: 2026-07-22
# @author YourName
func setTimeScale(scale: float) -> void:
    time_scale = clamp(scale, 0.0, 10.0)
    print("TimerManager: Time scale set to %.2f" % time_scale)

# DOCU: Get current time scale
# @return: float - Current time scale
# Last Updated At: 2026-07-22
# @author YourName
func getTimeScale() -> float:
    return time_scale

# ==================== QUERY METHODS ====================
# DOCU: Get all timers in a category
# @param category: The category to query
# @return: Array[DeltaTimerAdapter] - All timers in category
# Last Updated At: 2026-07-22
# @author YourName
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
# @author YourName
func hasTimer(timer_id: String) -> bool:
    return registered_timers.has(timer_id)
```

### Delta Timer Adapter Class

```gdscript
# DOCU: Adapter for delta-based timers to enable pause/scale control
# Last Updated At: 2026-07-22
# @author YourName
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
# @author YourName
func getScaledDelta(delta: float) -> float:
    if TimerManager.isCategoryPaused(category):
        return 0.0
    return delta * TimerManager.getTimeScale()

# DOCU: Check if timer is currently active
# @return: bool - True if flag property is true
# Last Updated At: 2026-07-22
# @author YourName
func isActive() -> bool:
    if flag_property.is_empty():
        return false
    if not target_object.has(flag_property):
        return false
    return target_object.get(flag_property)

# DOCU: Get current timer value
# @return: float - Current timer value
# Last Updated At: 2026-07-22
# @author YourName
func getCurrentValue() -> float:
    if not target_object.has(timer_property):
        return 0.0
    return target_object.get(timer_property)
```

### Usage in Components

```gdscript
# Component with timer
class_name CraftingStation
extends Node2D

var _crafting_timer: float = 0.0
var _is_crafting: bool = false
const CRAFTING_DURATION: float = 3.0

func _ready() -> void:
    # Register timer with TimerManager
    var timer_id = "crafting_station_%d" % get_instance_id()
    var adapter = DeltaTimerAdapter.new(
        self,
        "_crafting_timer",
        "_is_crafting",
        timer_id,
        "gameplay"  # Category for pause control
    )
    TimerManager.registerTimer(adapter)

func _exit_tree() -> void:
    var timer_id = "crafting_station_%d" % get_instance_id()
    TimerManager.unregisterTimer(timer_id)

func _process(delta: float) -> void:
    if _is_crafting:
        var scaled_delta = _getScaledDelta(delta)
        _crafting_timer += scaled_delta

        if _crafting_timer >= CRAFTING_DURATION:
            _finishCrafting()

func _getScaledDelta(delta: float) -> float:
    var timer_id = "crafting_station_%d" % get_instance_id()
    if TimerManager.hasTimer(timer_id):
        var adapter = TimerManager.registered_timers[timer_id]
        return adapter.getScaledDelta(delta)
    return delta  # Fallback

func startCrafting() -> void:
    _is_crafting = true
    _crafting_timer = 0.0
```

### Pausing Gameplay

```gdscript
# PauseMenu.gd
func _onPauseButtonPressed() -> void:
    get_tree().paused = true  # Pause physics
    TimerManager.pauseCategory("gameplay")  # Pause custom timers
    EventBus.game_paused.emit(player_id, true)

func _onResumeButtonPressed() -> void:
    get_tree().paused = false
    TimerManager.resumeCategory("gameplay")
    EventBus.game_paused.emit(player_id, false)
```

---

## Multi-Instance Architecture

Support **local multiplayer** or **split-screen** by managing per-player state instances.

### Why Multi-Instance?

Single-instance games hardcode global state:
```gdscript
var player_health: int = 100  # Works for 1 player only
```

Multi-instance games track per-player state:
```gdscript
var player_health: Dictionary = {1: 100, 2: 100}  # Supports 2 players
```

### Coordinator Singleton Pattern

```gdscript
# File: scripts/systems/managers/GameStateManager.gd
# DOCU: Coordinates multiple player board instances
# Last Updated At: 2026-07-22
# @author YourName
extends Node

# ==================== SIGNALS ====================
signal board_created(player_id: int, board_state: PlayerBoardState)
signal board_switched(from_player_id: int, to_player_id: int)
signal score_changed(player_id: int, new_score: int)

# ==================== STATE ====================
var player_boards: Dictionary = {}  # player_id -> PlayerBoardState
var local_player_id: int = 1  # Current player ID
var active_player_id: int = 1  # Active board for split-screen

# ==================== BOARD MANAGEMENT ====================
# DOCU: Create a new player board instance
# @param player_id: The player ID (1, 2, 3, etc.)
# @param player_name: Optional player name
# @return: PlayerBoardState - The created board state
# Last Updated At: 2026-07-22
# @author YourName
func createPlayerBoard(player_id: int, player_name: String = "") -> PlayerBoardState:
    if player_boards.has(player_id):
        push_warning("Board already exists for player %d" % player_id)
        return player_boards[player_id]

    var board_state = PlayerBoardState.new(player_id, player_name)
    player_boards[player_id] = board_state

    # Forward signals with player_id
    board_state.score_changed.connect(
        func(pid: int, score: int):
            score_changed.emit(pid, score)
    )

    board_created.emit(player_id, board_state)
    print("GameStateManager: Created board for player %d" % player_id)
    return board_state

# DOCU: Get board state for a specific player
# @param player_id: The player ID to query
# @return: PlayerBoardState - The board state, or null if not found
# Last Updated At: 2026-07-22
# @author YourName
func getBoardState(player_id: int) -> PlayerBoardState:
    return player_boards.get(player_id, null)

# DOCU: Get the local player's board state
# @return: PlayerBoardState - The local player's board
# Last Updated At: 2026-07-22
# @author YourName
func getLocalPlayerBoardState() -> PlayerBoardState:
    return getBoardState(local_player_id)

# DOCU: Switch active board (for split-screen tab switching)
# @param player_id: The player ID to switch to
# Last Updated At: 2026-07-22
# @author YourName
func switchActiveBoard(player_id: int) -> void:
    if not player_boards.has(player_id):
        push_error("Cannot switch to non-existent board: %d" % player_id)
        return

    var previous_id = active_player_id
    active_player_id = player_id
    board_switched.emit(previous_id, player_id)
```

### Per-Instance State Class

```gdscript
# File: scripts/systems/managers/PlayerBoardState.gd
# DOCU: Per-player game state instance
# Last Updated At: 2026-07-22
# @author YourName
class_name PlayerBoardState
extends RefCounted

# ==================== SIGNALS ====================
signal score_changed(player_id: int, new_score: int)
signal item_collected(player_id: int, item: Node)
signal health_changed(player_id: int, new_health: int)

# ==================== IDENTITY ====================
var player_id: int
var player_name: String

# ==================== GAME STATE ====================
var score: int = 0
var health: int = 100
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
# @author YourName
func addScore(amount: int) -> void:
    score += amount
    score_changed.emit(player_id, score)

# DOCU: Set score directly
# @param value: New score value
# Last Updated At: 2026-07-22
# @author YourName
func setScore(value: int) -> void:
    score = value
    score_changed.emit(player_id, score)

# DOCU: Register an item with this player
# @param item: The item node to register
# Last Updated At: 2026-07-22
# @author YourName
func registerItem(item: Node) -> void:
    if item in items:
        return
    items.append(item)
    item_collected.emit(player_id, item)

# DOCU: Serialize state for saving
# @return: Dictionary - Serialized state
# Last Updated At: 2026-07-22
# @author YourName
func serializeState() -> Dictionary:
    return {
        "player_id": player_id,
        "player_name": player_name,
        "score": score,
        "health": health,
        "items": items.map(func(i): return i.get_path())
    }
```

### Component Usage Pattern

```gdscript
# ScorePickup.gd
class_name ScorePickup
extends Area2D

func _ready() -> void:
    body_entered.connect(_onBodyEntered)

func _onBodyEntered(body: Node2D) -> void:
    # Get player ID from player node (set externally)
    var player_id = body.player_id if body.has("player_id") else 1

    # Add score to correct player instance
    var board_state = GameStateManager.getBoardState(player_id)
    if board_state:
        board_state.addScore(10)

    queue_free()

# HUD.gd (player-specific UI)
class_name HUD
extends Control

var my_player_id: int = 1  # Set externally

func _ready() -> void:
    # Listen to global signals, filter by player_id
    EventBus.score_changed.connect(_onScoreChanged)

func _onScoreChanged(player_id: int, new_score: int) -> void:
    if player_id != my_player_id:
        return  # Ignore other players
    score_label.text = "Score: %d" % new_score
```

### Example from Mocha Kombat

Mocha Kombat uses this pattern for **local 2-player mode**:

```gdscript
# GameStateManager.gd
var player_boards: Dictionary = {}  # {1: BoardState, 2: BoardState}

# Card.gd (CRITICAL: Never use card.player_id)
func _onCardClicked() -> void:
    # ALWAYS use GameStateManager.local_player_id
    var player_id = GameStateManager.local_player_id
    EventBus.card_clicked.emit(player_id, self)

# HUD.gd (filters signals by player_id)
func _onComboChanged(player_id: int, combo: int) -> void:
    if player_id != GameStateManager.local_player_id:
        return
    combo_label.text = "Combo: %d" % combo
```

**Key Rule**: All EventBus signals include `player_id` for routing.

---

## Documentation Standards

Consistent documentation improves long-term maintainability.

### Comment Block Pattern

```gdscript
# DOCU: Method description explaining purpose and context
# Provides information beyond what the code reveals
# @param param_name: Description with type and constraints
# @param optional_param: Optional parameter (default: value)
# @return: Type - Description of return value
# Last Updated At: 2026-07-22
# @author YourName
func processData(input: Array, threshold: float = 1.0) -> Dictionary:
    var result: Dictionary = {}
    # Implementation...
    return result
```

### Documentation Principles

1. **DOCU Prefix**: Marks important documentation blocks
2. **What + Why**: Explain purpose, not just implementation
3. **Last Updated**: Track staleness (helps identify outdated code)
4. **Author**: Accountability and contact info
5. **Parameter Descriptions**: Include types and constraints
6. **Return Descriptions**: Clarify output format

### Inline Comments

```gdscript
# Good: Explains WHY
var timeout: float = 2.0  # Wait for server response timeout

# Bad: Explains WHAT (obvious from code)
var timeout: float = 2.0  # Set timeout to 2.0
```

### File Header Template

```gdscript
# File: scripts/systems/managers/AudioManager.gd
# DOCU: Manages game audio playback with pooling and spatial audio support
# Responsibilities:
# - Play SFX with automatic pooling
# - Play music with crossfade transitions
# - Manage audio bus volumes
# - Spatial audio for 3D sounds
# Last Updated At: 2026-07-22
# @author YourName
extends Node

# ... code
```

---

## Additional Patterns

### Global Groups Pattern

Use Godot's **global groups** for cross-scene queries without direct references.

```gdscript
# project.godot
[global_group]

Player=""
Enemy=""
Collectible=""
```

```gdscript
# Player.gd
func _ready() -> void:
    add_to_group("Player")

# EnemyAI.gd
func _findNearestPlayer() -> Node2D:
    var players = get_tree().get_nodes_in_group("Player")
    if players.is_empty():
        return null

    var nearest: Node2D = null
    var min_distance: float = INF

    for player in players:
        var distance = global_position.distance_to(player.global_position)
        if distance < min_distance:
            min_distance = distance
            nearest = player

    return nearest
```

**Benefits**:
- No hardcoded node paths
- Automatic cleanup when nodes deleted
- Type-agnostic queries

---

### Scene Transition Optimization

Suppress signal spam during bulk scene cleanup.

```gdscript
# EventBus.gd
var is_scene_transitioning: bool = false

signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_complete(scene_name: String)

# SceneTransitionManager.gd
func changeScene(scene_path: String) -> void:
    EventBus.is_scene_transitioning = true
    EventBus.scene_transition_started.emit(current_scene, scene_path)

    get_tree().change_scene_to_file(scene_path)

    await get_tree().process_frame
    EventBus.is_scene_transitioning = false
    EventBus.scene_transition_complete.emit(scene_path)

# Card.gd (suppress signals during cleanup)
func _exit_tree() -> void:
    if EventBus and not EventBus.is_scene_transitioning:
        EventBus.card_deleted.emit(player_id, self)
```

**Benefit**: Prevents 100+ unnecessary signal emissions during scene changes.

---

### Tween Management Pattern

```gdscript
var _spawn_tween: Tween = null

func playSpawnAnimation() -> void:
    # Kill existing tween to prevent overlap
    if _spawn_tween and _spawn_tween.is_valid():
        _spawn_tween.kill()

    _spawn_tween = create_tween()
    _spawn_tween.set_parallel(true)  # Simultaneous animations

    # Scale animation
    _spawn_tween.tween_property(self, "scale", Vector2.ONE, 0.3) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    # Fade animation
    _spawn_tween.tween_property(self, "modulate:a", 1.0, 0.3) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    # Chain sequential animations
    _spawn_tween.chain().tween_property(self, "scale", Vector2.ONE * 1.1, 0.1)
    _spawn_tween.tween_property(self, "scale", Vector2.ONE, 0.15) \
        .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

    # Callback on complete
    _spawn_tween.tween_callback(_onAnimationComplete)
```

**Key Practices**:
- Store tween references for cancellation
- Always kill before creating new tween
- Use `.set_parallel(true)` for simultaneous effects
- Use `.chain()` for sequential effects

---

### Constants Organization

```gdscript
# File: scripts/systems/managers/Constants.gd
extends Node

# ==================== VERSION ====================
const VERSION: String = "v1.0.0"
const DEBUG_MODE: bool = false

# ==================== CORE GAMEPLAY ====================
const MAX_HEALTH: int = 100
const MAX_SPEED: float = 300.0
const GRID_CELL_SIZE: int = 64

# ==================== TIMING ====================
const GAME_START_DELAY: float = 1.0
const RESPAWN_TIME: float = 3.0

# ==================== PRELOADED RESOURCES ====================
const EXPLOSION_VFX: PackedScene = preload("res://scenes/vfx/Explosion.tscn")
const GHOST_SHADER: Shader = preload("res://assets/shaders/ghost.gdshader")

# ==================== COLOR PALETTE ====================
const COLOR_PRIMARY: Color = Color(0.2, 0.6, 1.0)
const COLOR_SECONDARY: Color = Color(1.0, 0.4, 0.2)
const COLOR_SUCCESS: Color = Color(0.2, 0.8, 0.3)
const COLOR_DANGER: Color = Color(0.9, 0.2, 0.2)

# ==================== COMPLEX DATA ====================
const DIFFICULTY_SETTINGS: Dictionary = {
    "EASY": {"health_multiplier": 1.5, "damage_multiplier": 0.75},
    "NORMAL": {"health_multiplier": 1.0, "damage_multiplier": 1.0},
    "HARD": {"health_multiplier": 0.75, "damage_multiplier": 1.5}
}
```

**Benefits**:
- Single point of change
- Type safety (const prevents mutation)
- Autocompletion (`Constants.MAX_HEALTH`)
- Centralized preloading

---

### Asset Loading Pattern

```gdscript
# Preload for performance-critical assets
const PLAYER_SPRITE: Texture2D = preload("res://assets/player.png")
const UI_THEME: Theme = preload("res://assets/themes/main_theme.tres")

# Dynamic loading for situational assets
func loadVfxMaterial(vfx_type: String) -> ShaderMaterial:
    var path = "res://assets/shaders/vfx_%s.tres" % vfx_type.to_lower()
    if ResourceLoader.exists(path):
        return load(path) as ShaderMaterial
    return null
```

**Guidelines**:
- **Preload** for frequently-used resources (UI, player assets)
- **Load dynamically** for situational resources (VFX, cutscenes)
- **Use fallbacks** for required assets (prevent null errors)

---

## Conclusion

This boilerplate guide provides a **professional foundation** for Godot 4.x projects. The patterns scale from small prototypes to large production games (Mocha Kombat has 225+ resource files, 53 managers, and maintains clean architecture throughout).

### Key Takeaways

1. **EventBus Signal Architecture** — Decouples systems, enables clean communication
2. **Singleton Manager Pattern** — Centralized control for cross-cutting concerns
3. **Resource-Based Data Design** — Data-driven configuration via Inspector
4. **Component Base Classes** — DRY principle for common behavior (drag, timers)
5. **Multi-Instance State Pattern** — Supports local multiplayer/split-screen
6. **Strict Naming Conventions** — Improves codebase navigability
7. **Documentation Standards** — Maintains long-term code quality

### Next Steps

1. **Adapt to your project**: Copy relevant patterns, modify as needed
2. **Start with structure**: Set up directories and autoloads first
3. **Build incrementally**: Add managers as you need them
4. **Document early**: Write DOCU blocks from the start
5. **Refactor boldly**: Extract common patterns into base classes

### Additional Resources

- **Godot 4.x Docs**: https://docs.godotengine.org/en/stable/
- **GDScript Style Guide**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- **Mocha Kombat Repo**: (Reference implementation of these patterns)

---

**Last Updated**: 2026-07-22
**Extracted From**: Mocha Kombat v0.3.2
**Godot Version**: 4.5+
