# Godot 4.x Professional Game Architecture Boilerplate

A production-ready Godot 4.x project template featuring **singleton managers**, **lifecycle patterns**, **signal-driven architecture**, and **multi-instance support**. Extracted from the Mocha Kombat codebase (225+ resources, 53 managers, clean layered architecture).

## Features

- ✅ **Singleton Manager Pattern** - EventBus, GameStateManager, TimerManager, AudioManager, Constants
- ✅ **Component Lifecycle Events** - Multi-stage initialization with virtual hooks
- ✅ **Signal-Driven Communication** - Decoupled cross-component events
- ✅ **Drag & Drop System** - Reusable base class with bounds/overlap detection
- ✅ **Multi-Instance Architecture** - Per-player state for local multiplayer
- ✅ **Resource-Based Data Design** - Data-driven configuration via Inspector
- ✅ **Timer Management System** - Centralized pause/resume/time-scaling
- ✅ **Strict Naming Conventions** - PascalCase, snake_case, CONSTANT_CASE
- ✅ **Example Component** - Full lifecycle pattern demonstration

## Quick Start

### 1. Clone or Download

```bash
# Clone this repository
git clone https://github.com/your-username/godot-boilerplate.git
cd godot-boilerplate
```

Or download as ZIP and extract.

### 2. Open in Godot

1. Open Godot 4.4+ (4.5+ recommended)
2. Click **Import**
3. Navigate to the boilerplate folder
4. Select `project.godot`
5. Click **Import & Edit**

### 3. Verify Setup

The project should open with:
- **5 autoloaded managers** in Project Settings → Autoload
- **Example component scene** at `scenes/components/ExampleComponent/`
- **No errors** in the Output panel

### 4. Test Example Component

1. Open `scenes/components/ExampleComponent/ExampleComponent.tscn`
2. Press **F6** to run the current scene
3. Click the component to toggle activation
4. Watch console output for lifecycle events

## Project Structure

```
godot_boilerplate/
├── GODOT_BOILERPLATE_GUIDE.md    # Comprehensive architecture guide
├── README.md                      # This file
├── project.godot                  # Godot project config with autoloads
├── addons/                        # Third-party plugins
├── assets/
│   ├── images/                    # Textures, sprites
│   │   ├── ui/
│   │   ├── characters/
│   │   ├── items/
│   │   └── environment/
│   ├── sounds/                    # Audio files
│   │   ├── sfx/
│   │   └── music/
│   ├── fonts/
│   ├── shaders/
│   └── themes/
├── resources/                     # Custom resource files (.tres)
│   ├── items/
│   │   └── ItemData.gd           # Item resource template
│   └── characters/
│       └── CharacterData.gd      # Character resource template
├── scenes/
│   ├── components/
│   │   └── ExampleComponent/     # Example lifecycle component
│   ├── game/
│   ├── levels/
│   ├── menus/
│   └── ui/
└── scripts/
    ├── systems/
    │   └── managers/              # Singleton managers
    │       ├── EventBus.gd       # Central signal hub
    │       ├── GameStateManager.gd
    │       ├── TimerManager.gd
    │       ├── AudioManager.gd
    ├── entities/
    │   ├── Draggable.gd          # Base drag & drop class
    │   └── LifecycleEntity.gd    # Base lifecycle class
    └── game/
    └── Constants.gd
```

## Usage Examples

### Creating a New Component

1. **Create component folder**:
   ```
   scenes/components/MyComponent/
   ├── MyComponent.tscn
   └── MyComponent.gd
   ```

2. **Extend LifecycleEntity**:
   ```gdscript
   class_name MyComponent
   extends LifecycleEntity

   # Override lifecycle hooks
   func onInitialize(data: Resource = null) -> void:
       # Custom initialization

   func onSpawn() -> void:
       # Post-spawn events

   func onActivate() -> void:
       # Activation logic
   ```

### Using EventBus

```gdscript
# Emit event
EventBus.score_changed.emit(player_id, new_score)

# Listen to event
func _ready() -> void:
    EventBus.score_changed.connect(_onScoreChanged)

func _onScoreChanged(player_id: int, new_score: int) -> void:
    if player_id != GameStateManager.local_player_id:
        return
    score_label.text = "Score: %d" % new_score
```

### Creating Resources

1. **In Inspector**:
   - Right-click FileSystem → New Resource
   - Search for `ItemData` or `CharacterData`
   - Edit properties in Inspector
   - Save as `.tres` file

2. **In Code**:
   ```gdscript
   var item = ItemData.new()
   item.item_id = "health_potion"
   item.display_name = "Health Potion"
   item.rarity = ItemData.Rarity.COMMON
   ```

### Using TimerManager

```gdscript
var _timer: float = 0.0
var _is_running: bool = false

func _ready() -> void:
    # Register timer
    var timer_id = "my_timer_%d" % get_instance_id()
    var adapter = DeltaTimerAdapter.new(
        self, "_timer", "_is_running", timer_id, "gameplay"
    )
    TimerManager.registerTimer(adapter)

func _process(delta: float) -> void:
    if _is_running:
        var scaled_delta = TimerManager.registered_timers[timer_id].getScaledDelta(delta)
        _timer += scaled_delta

# Pause all gameplay timers
func _onPausePressed() -> void:
    TimerManager.pauseCategory("gameplay")
```

### Making Entities Draggable

```gdscript
class_name DraggableItem
extends Draggable

# Override validation
func _canStartDrag() -> bool:
    if is_equipped:
        return false
    return super._canStartDrag()

# Override drag end
func onDragEnd() -> void:
    # Grid snap
    global_position = _snapToGrid(global_position)
    # Save position
    SaveManager.saveItemPosition(item_id, global_position)
```

## Documentation

📖 **[GODOT_BOILERPLATE_GUIDE.md](GODOT_BOILERPLATE_GUIDE.md)** - Comprehensive guide covering:
- Project Structure & Naming Conventions
- Singleton Manager Pattern
- EventBus Signal Architecture
- Component & Entity Lifecycle Events
- Resource-Based Data Design
- Drag & Drop System
- Timer Management
- Multi-Instance Architecture
- Documentation Standards
- Additional Patterns

## Architecture Principles

1. **Separation of Concerns**: Scenes ≠ Scripts ≠ Resources ≠ Assets
2. **Signal-Driven Communication**: Components never reference each other directly
3. **Component-Based Organization**: Group related files in component folders
4. **Data-Driven Design**: Configuration in `.tres` files, not hardcoded
5. **Multi-Instance Ready**: All systems support local multiplayer via `player_id`
6. **Lifecycle Consistency**: Predictable initialization order across all entities

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files/Scenes | **PascalCase** | `PlayerController.gd` |
| Directories (code) | **PascalCase** | `ExampleComponent/` |
| Directories (assets) | **snake_case** | `assets/sounds/sfx/` |
| Assets | **snake_case** | `button_normal_bg.png` |
| Variables | **snake_case** | `player_health` |
| Constants | **CONSTANT_CASE** | `MAX_HEALTH` |
| Functions | **camelCase** | `getPlayerInput()` |
| Private Members | **_snake_case** | `_is_dragging` |
| Signals | **snake_case** (past tense) | `item_collected` |
| Class Names | **PascalCase** | `class_name LifecycleEntity` |

## Customization

### Adding New Managers

1. Create `scripts/systems/managers/YourManager.gd`
2. Add to autoload in `project.godot`:
   ```ini
   [autoload]
   YourManager="*res://scripts/systems/managers/YourManager.gd"
   ```

### Modifying Constants

Edit `scripts/systems/managers/Constants.gd`:
```gdscript
const MAX_HEALTH: int = 150  # Change game balance
const COLOR_PRIMARY: Color = Color(0.5, 0.8, 0.3)  # Change theme
```

### Adding Custom Resources

1. Create `resources/your_type/YourData.gd` extending `Resource`
2. Add `class_name YourData`
3. Define `@export` properties
4. Create `.tres` instances in Inspector

## FAQ

**Q: Do I need all the managers?**
A: No. Remove unused managers from `project.godot` autoload and delete the files.

**Q: Can I use this for 2D and 3D games?**
A: Yes. The architecture is game-type agnostic. For 3D, change base classes from `Node2D` to `Node3D`.

**Q: How do I add save/load?**
A: Create a `SaveManager` singleton. Use `serializeState()` methods on entities.

**Q: What about mobile/controller input?**
A: Extend `Draggable` with touch input. Add input mapping in Project Settings.

**Q: Can I use this commercially?**
A: Yes. This boilerplate is MIT licensed (or specify your license).

## Examples in the Wild

This architecture powers:
- **Mocha Kombat** - Real-time card strategy game (225+ resources, 53 managers)

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Follow the naming conventions
4. Add examples to the guide
5. Submit a pull request

## License

MIT License - Free to use in commercial and personal projects.

## Credits

Extracted from **Mocha Kombat** architecture by the Godot Boilerplate community.

## Support

- **Issues**: [GitHub Issues](https://github.com/your-username/godot-boilerplate/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/godot-boilerplate/discussions)
- **Guide**: See `GODOT_BOILERPLATE_GUIDE.md` for detailed documentation

---

**Get started in 5 minutes. Build professional Godot games with proven architecture.**
