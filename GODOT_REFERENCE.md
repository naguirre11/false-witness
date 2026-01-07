# Godot Technical Reference for Codebreaker AI

**Purpose**: Essential Godot engine knowledge to prevent common development errors  
**Priority**: Read BEFORE implementing any Godot systems  

---

## Critical Knowledge Matrix

### Class Hierarchy Capabilities

| Class Type | Scene Tree Access | Autoload Access Method | Can Be Autoload | Key Methods Available |
|------------|------------------|------------------------|-----------------|----------------------|
| **Node** (and descendants) | ✅ Direct | `get_node("/root/Name")` | ✅ Yes | `has_node()`, `get_node()`, `get_tree()`, `add_child()` |
| **Resource** | ❌ None | Via Engine only | ❌ No | No scene methods |
| **RefCounted** | ❌ None | Via Engine only | ❌ No | No scene methods (⚠️ AVOID - Use proper types) |
| **Object** | ❌ None | Via Engine only | ❌ No | No scene methods |

### Quick Decision Tree

```
Q: Does this class need to access other nodes or the scene tree?
├─ Yes → extends Node (or Control, Node2D, etc.)
└─ No → Does it need to be saved/loaded as data?
    ├─ Yes → extends Resource
    └─ No → Use proper class types with preload/autoload (AVOID RefCounted)
```

---

## Autoload Access Patterns

### From Node-Based Classes
```gdscript
# Method 1: Direct path access
var manager = get_node("/root/ResourceManager")

# Method 2: Direct name (if autoload name matches)
ResourceManager.some_method()  # Works globally
```

### From Resource/RefCounted Classes
```gdscript
# MUST use Engine to access scene tree
func _get_resource_manager():
    var tree = Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        return tree.root.get_node("ResourceManager")
    return null
```

### From Static Methods
```gdscript
# Static methods can't use instance methods
static func get_manager():
    var tree = Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        return tree.root.get_node("ResourceManager")
    return null
```

---

## Common Error Patterns & Solutions

### Error: "Function has_node() not found in base self"
**Cause**: Using Node methods in Resource/RefCounted class  
**Solution**: Use Engine.get_main_loop() pattern or change base class

### Error: "Identifier not found: ClassName" (in static methods)
**Cause**: Using `ClassName.new()` within the same class  
**Solution**: Use `new()` instead
```gdscript
# ❌ WRONG
static func create() -> MyClass:
    return MyClass.new()  # Circular reference!

# ✅ CORRECT
static func create() -> MyClass:
    return new()
```

### Error: Signal parameter mismatch
**Cause**: Misunderstanding bind() parameter order  
**Solution**: Signal params come first, then bound params
```gdscript
# Signal definition
signal resource_changed(old_val: int, new_val: int)

# Binding with extra parameters
pool.resource_changed.connect(callback.bind(extra1, extra2))

# Callback signature (signal params FIRST)
func callback(old_val: int, new_val: int, extra1, extra2):
    pass
```

### Error: "Could not preload resource script" 
**Cause**: Attempting to preload scripts before proper class registration  
**Solution**: Ensure class_name declarations and project scanning
```gdscript
# ❌ FAILS - script not registered yet
const MyClass = preload("res://src/MyClass.gd")

# ✅ WORKS - after class_name declaration in MyClass.gd
class_name MyClass
extends Node  # Use Node for proper type system integration
```

### Error: "Could not resolve external class member"
**Cause**: Godot 4.4 stricter type resolution - methods called before type system resolves them  
**Solution**: Use proper initialization order or dynamic loading
```gdscript
# ❌ RISKY - may fail during project scan
func _init():
    var obj = MyClass.new()
    obj.some_method()  # Method may not be resolved yet

# ✅ SAFE - defer until after project ready
func _ready():
    var obj = MyClass.new() 
    obj.some_method()  # Type system fully loaded
```

### Error: "Expected function name after func"
**Cause**: Using reserved keywords as function names  
**Solution**: Avoid Godot built-in names like `assert`, `print`, `str`
```gdscript
# ❌ WRONG - 'assert' is reserved in Godot 4.4
func assert(condition: bool, message: String):
    pass

# ✅ CORRECT - use alternative name
func test_assert(condition: bool, message: String):
    pass
```

### Error: Standalone scripts can't access autoloads
**Cause**: Scripts run with --script bypass normal scene tree setup  
**Solution**: Use scene-based testing for autoload access
```gdscript
# ❌ FAILS - running script directly
# godot --script test_script.gd
extends SceneTree
func _init():
    EventBus.emit_event("test")  # ERROR: not available

# ✅ WORKS - scene-based testing  
# TestScene.gd attached to TestScene.tscn
extends Node
func _ready():
    EventBus.emit_event("test")  # SUCCESS: autoloads available
```

---

## ⚠️ CRITICAL: RefCounted Anti-Pattern Warning

### 🚨 NEVER Use RefCounted - It's an Anti-Pattern

**RefCounted was used as a workaround but causes serious issues:**

```gdscript
# ❌ WRONG - RefCounted anti-pattern (causes type safety issues)
extends RefCounted
class_name MyComponent

func my_method(entity: RefCounted) -> RefCounted:  # Loses all type safety
    pass

# ✅ CORRECT - Use proper class types
extends Resource  # For data classes
class_name MyComponent

func my_method(entity: CombatEntity) -> StatusEffect:  # Full type safety
    pass
```

### Why RefCounted Breaks Everything
1. **Type Safety Loss**: `RefCounted` type hints lose all compile-time checking
2. **IDE Degradation**: No autocompletion or error detection
3. **Runtime Errors**: Type mismatches only caught at runtime
4. **Maintenance Nightmare**: Unclear interfaces and dependencies
5. **Performance Impact**: Dynamic type checking at runtime

### The Correct Patterns
- **Data Classes**: `extends Resource` + proper serialization
- **Manager Classes**: `extends Node` + autoload registration  
- **Component Classes**: Use specific types with preload patterns
- **Type Hints**: Always use exact class types, never RefCounted

**This anti-pattern was fixed project-wide in January 2025 - never reintroduce it.**

---

## Type Safety Patterns

### Avoiding Circular Dependencies

```gdscript
# ❌ RISKY - Can cause circular dependency
class_name CardManager
var database: CardDatabase  # If CardDatabase references CardManager = circular

# ✅ SAFE - Use preload for one-way dependencies
const CardDatabase = preload("res://path/to/CardDatabase.gd")
var database: CardDatabase  # Safe if relationship is one-way

# ✅ SAFE - Dynamic loading pattern (breaks circular deps)
func _get_card_database():
    var DatabaseScript = load("res://src/core/managers/CardDatabase.gd")
    return DatabaseScript.new()

# ✅ SAFE - Duck typing with documentation
var database  # CardDatabase - documented but not enforced

# ✅ SAFE - Use in method signatures
func process_card(card: Card) -> void:  # Usually safe
    pass
```

### 🚨 Critical: Self-Reference in Static Methods

**NEVER use class name to reference self in static methods:**

```gdscript
# ❌ WRONG - Self-reference creates compile-time circular dependency  
class_name SaveFile
static func validate_save_file(path: String) -> Dictionary:
    var save_file = SaveFile.new()  # ERROR: Needs SaveFile resolved to compile SaveFile!
    return save_file.validate_file(path)

# ✅ CORRECT - Use load() to break compile-time dependency
static func validate_save_file(path: String) -> Dictionary:
    var save_file = load("res://src/core/save/SaveFile.gd").new()  # Runtime loading
    return save_file.validate_file(path)

# ✅ ALTERNATIVE - Use instance method instead of static
func validate_save_file(path: String) -> Dictionary:
    var save_file = SaveFile.new()  # Works fine - no compile-time loop
    return save_file.validate_file(path)
```

**Why self-reference fails:**
1. **Compile-time loop**: GDScript must resolve `SaveFile` to compile SaveFile.gd
2. **Class resolution deadlock**: SaveFile.gd contains `SaveFile.new()` → infinite loop
3. **Static context problem**: No instance exists yet to reference

**Why load() works:**
1. **Runtime resolution**: `load()` uses file path, resolved at runtime not compile-time
2. **Breaks dependency chain**: No class name resolution needed during compilation
3. **Deferred loading**: File loads when method executes, not when class compiles

### 🚨 Autoload Pattern Solves Most Circular Dependencies

**Autoloads break circular dependency chains automatically:**

```gdscript
# ✅ BEST PRACTICE - Autoload managers can reference each other safely
# In StateSerializer.gd:
func _serialize_system_managers() -> Dictionary:
    var systems = {}
    var system_names = [
        "ResourceManager",  # Autoload
        "SaveManager",      # Autoload - NO circular dependency!
        "EventBus"          # Autoload
    ]
    
    for system_name in system_names:
        # Safe because autoloads are globally accessible
        var system = _get_system_reference(system_name)

# In SaveManager.gd (autoload):
const StateSerializer = preload("res://src/core/save/StateSerializer.gd")
# ✅ No circular dependency - autoload → preload is safe
```

**Why autoloads solve circularity:**
1. **Autoloads are singletons** - instantiated once at startup
2. **Globally accessible** - no import chain needed  
3. **Break dependency cycles** - autoload access ≠ class dependency
4. **Static reference** - `SaveManager.method()` doesn't create new instances

### 🎯 Complete Decision Guide: load() vs preload() vs Autoload

#### Quick Decision Tree
```
Need to access this class/resource?
├─ Will it be used by multiple systems globally?
│   └─ YES → Use Autoload (singleton pattern)
├─ Is the path known at compile time?
│   ├─ YES → Check: Does the target class also reference this class?
│   │   ├─ NO (one-way) → Use preload() (type-safe, fast)
│   │   └─ YES (circular) → Use load() or autoload (breaks circular deps)
│   └─ NO → Use load() (dynamic paths)
```

#### Detailed Comparison Matrix

| Aspect | **Autoload** | **preload()** | **load()** |
|--------|--------------|---------------|------------|
| **When Loaded** | At game start | At compile time | At runtime when called |
| **Performance** | Always in memory | Fast (pre-cached) | Slower (loads on demand) |
| **Type Safety** | Full (global name) | Full (const type) | Partial (runtime checks) |
| **Memory Usage** | Persistent | Persistent | Can be freed |
| **Circular Deps** | ✅ Breaks them | ❌ Can cause them | ✅ Breaks them |
| **Path Flexibility** | Fixed in project.godot | Fixed at compile | Dynamic/conditional |
| **Global Access** | ✅ Yes | ❌ No | ❌ No |
| **Requirements** | Must extend Node | Any resource/script | Any resource/script |

#### When to Use Each Pattern

##### Use **Autoload** When:
```gdscript
# ✅ BEST FOR: Global managers and singletons
# In project.godot:
[autoload]
SaveManager="res://src/core/managers/SaveManager.gd"
EventBus="res://src/core/managers/EventBus.gd"

# Access from anywhere:
SaveManager.save_game()
EventBus.emit_signal("player_died")

# Requirements:
# - extends Node (or descendant)
# - NO class_name declaration (conflicts with singleton)
# - Used by multiple systems
# - Needs persistent state
```

##### Use **preload()** When:
```gdscript
# ✅ BEST FOR: Type-safe dependencies without circular refs
const Card = preload("res://src/gameplay/cards/Card.gd")
const CardTexture = preload("res://assets/card.png")

var my_card: Card = Card.new()  # Full type safety

# When to use:
# - Path known at compile time
# - Type safety important
# - No circular dependency risk
# - Performance critical (avoid runtime loading)
# - One-way dependencies only
```

##### Use **load()** When:
```gdscript
# ✅ BEST FOR: Dynamic loading and breaking circular deps

# Breaking circular dependencies in static methods:
static func create_instance():
    return load("res://src/core/save/SaveFile.gd").new()

# Dynamic/conditional loading:
func load_level(level_name: String):
    var level_path = "res://levels/%s.tscn" % level_name
    return load(level_path)

# User-generated content:
func load_mod(mod_path: String):
    if ResourceLoader.exists(mod_path):
        return load(mod_path)

# When to use:
# - Breaking circular dependencies
# - Dynamic paths (user input, config files)
# - Optional resources (may not exist)
# - Memory management (can free after use)
# - Plugin/mod systems
```

#### 🚨 How preload() Creates Circular Dependencies

**Understanding the Compile-Time Dependency Chain:**

```gdscript
# File: Player.gd
class_name Player
const Inventory = preload("res://Inventory.gd")  # Player needs Inventory at compile

# File: Inventory.gd  
class_name Inventory
const Player = preload("res://Player.gd")  # Inventory needs Player at compile

# RESULT: Circular dependency error!
# Compile order deadlock: Player → Inventory → Player → ...
```

**Why this happens:**
1. GDScript tries to compile Player.gd
2. Sees `preload("Inventory.gd")` → must compile Inventory.gd first
3. Tries to compile Inventory.gd
4. Sees `preload("Player.gd")` → must compile Player.gd first
5. **Deadlock!** Each file needs the other compiled first

**How to Identify Circular Dependency Risks:**

```gdscript
# ✅ SAFE - One-way dependency
# Card.gd
class_name Card
const CardEffect = preload("res://CardEffect.gd")  # Card uses Effect

# CardEffect.gd
class_name CardEffect
# No reference back to Card = SAFE

# ❌ RISKY - Two-way dependency  
# CombatManager.gd
class_name CombatManager
const CombatUI = preload("res://CombatUI.gd")  # Manager uses UI

# CombatUI.gd
class_name CombatUI  
const CombatManager = preload("res://CombatManager.gd")  # UI uses Manager
# CIRCULAR! Both preload each other

# ✅ SOLUTION 1 - Use load() in one direction
# CombatManager.gd
const CombatUI = preload("res://CombatUI.gd")  # Keep preload here

# CombatUI.gd
func get_manager():
    return load("res://CombatManager.gd").new()  # Use load() here

# ✅ SOLUTION 2 - Make one an autoload
# CombatManager.gd (as autoload)
extends Node  # No class_name, accessed globally as CombatManager

# CombatUI.gd
class_name CombatUI
# Access manager via global: CombatManager.some_method()
```

#### Common Patterns and Pitfalls

```gdscript
# ❌ WRONG - Circular dependency in static method
class_name MyClass
static func create():
    return MyClass.new()  # Compile-time circular ref!

# ✅ CORRECT - Use load() to break it
static func create():
    return load("res://path/to/MyClass.gd").new()

# ❌ WRONG - Indirect circular dependency
# A.gd
const B = preload("res://B.gd")
# B.gd  
const C = preload("res://C.gd")
# C.gd
const A = preload("res://A.gd")  # A→B→C→A = circular!

# ✅ CORRECT - Break the chain
# Use load() or autoload for at least one link

# ❌ WRONG - Autoload with class_name
class_name EventBus  # Conflicts with autoload name!
extends Node

# ✅ CORRECT - No class_name for autoloads
extends Node  # Access as EventBus globally
```

#### Memory and Performance Considerations

| Pattern | Memory Impact | Load Time | Best For |
|---------|--------------|-----------|----------|
| **Autoload** | Always loaded | At startup | Core systems |
| **preload()** | Always loaded | At compile | Known dependencies |
| **load()** | On-demand | When called | Optional/dynamic content |

```gdscript
# Memory-efficient pattern for optional resources:
var _cached_resource = null
func get_resource():
    if not _cached_resource:
        _cached_resource = load("res://optional_resource.tres")
    return _cached_resource

# Clear when not needed:
func clear_cache():
    _cached_resource = null
```

---

## Autoload Setup

### In project.godot
```ini
[autoload]
EventBus="res://src/core/managers/EventBus.gd"
CardDatabase="res://src/core/managers/CardDatabase.gd"
ResourceManager="res://src/gameplay/resources/ResourceManager.gd"
```

### Requirements for Autoload Scripts
1. **MUST extend Node** (or descendant)
2. **MUST have _ready() if initialization needed**
3. **Accessible globally by name**
4. **Singleton pattern automatic**
5. **NEVER use class_name** in autoloaded scripts (causes conflicts)

### Critical Autoload Gotchas
```gdscript
# ❌ WRONG - class_name conflicts with autoload singleton name
class_name EventBus  # This hides the autoload singleton!
extends Node

# ✅ CORRECT - no class_name in autoloaded scripts
extends Node
# Access globally as: EventBus.some_method()
```

---

## Quick Test Templates

### Minimal Compilation Test
```gdscript
# test_compile.gd
extends SceneTree

func _init():
    print("Testing compilation...")
    
    # Test class loading
    const MyClass = preload("res://path/to/MyClass.gd")
    assert(MyClass != null, "Failed to load MyClass")
    
    # Test instantiation
    var instance = MyClass.new()
    assert(instance != null, "Failed to create instance")
    
    print("✓ Compilation test passed")
    quit()
```

Run: `godot --headless --script test_compile.gd`

### Autoload Access Test
```gdscript
# test_autoload.gd
extends SceneTree

func _init():
    # Wait for autoloads
    await process_frame
    
    # Test autoload access
    var manager = root.get_node("ResourceManager")
    assert(manager != null, "ResourceManager not found")
    
    print("✓ Autoload access working")
    quit()
```

---

## Performance Considerations

### Scene Tree Access Cost
- `get_node()` with path: **Fast** (cached)
- `find_node()` recursive: **Slow** (avoid)
- Direct reference: **Fastest** (store in variable)

```gdscript
# ❌ SLOW - Multiple lookups
func update():
    get_node("/root/Manager").method1()
    get_node("/root/Manager").method2()

# ✅ FAST - Single lookup, cached reference
var manager
func _ready():
    manager = get_node("/root/Manager")
func update():
    manager.method1()
    manager.method2()
```

---

## Signal Best Practices

### Connection Patterns
```gdscript
# One-shot connections (Godot 4.4 syntax)
signal.connect(callback, Object.CONNECT_ONE_SHOT)

# Deferred connections (end of frame)
signal.connect(callback, Object.CONNECT_DEFERRED)

# Always disconnect in _exit_tree() if connected in _ready()
func _ready():
    EventBus.some_signal.connect(_on_signal)

func _exit_tree():
    if EventBus.some_signal.is_connected(_on_signal):
        EventBus.some_signal.disconnect(_on_signal)
```

---

## Common Godot Gotchas

1. **Resources are shared by default**
   ```gdscript
   # ❌ Modifying resource affects all users
   var card_def = preload("res://card.tres")
   card_def.value = 10  # Changes for EVERYONE
   
   # ✅ Duplicate for instance-specific changes
   var my_card = card_def.duplicate()
   my_card.value = 10  # Only affects this instance
   ```

2. **Node operations in _init() fail**
   ```gdscript
   # ❌ Scene tree not ready in _init()
   func _init():
       add_child(node)  # FAILS
   
   # ✅ Use _ready() for scene operations
   func _ready():
       add_child(node)  # Works
   ```

3. **Export variables need tool mode for editor**
   ```gdscript
   @tool  # Required for editor updates
   extends Node
   @export var color: Color = Color.WHITE:
       set(value):
           color = value
           if Engine.is_editor_hint():
               queue_redraw()
   ```

4. **Never override Object built-in methods**
   ```gdscript
   # ❌ WRONG - overrides Object.to_string()
   func to_string() -> String:  # Compilation warning/error
       return "my string"
   
   # ✅ CORRECT - use different method names
   func to_debug_string() -> String:
       return "my debug string"
   
   func to_display_string() -> String:
       return "my display string"
   ```

5. **Standalone scripts can't access autoloads**
   ```gdscript
   # ❌ FAILS - running script directly
   # godot --script test_script.gd
   extends SceneTree
   func _init():
       EventBus.emit_event("test")  # ERROR: not available
   
   # ✅ WORKS - scene-based testing
   # TestScene.gd attached to TestScene.tscn
   extends Node
   func _ready():
       EventBus.emit_event("test")  # SUCCESS: autoloads available
   ```

---

## Modern Godot 4.4 Patterns

### Export Annotations
```gdscript
# Range-constrained exports
@export_range(0.0, 1.0) var opacity: float = 1.0
@export_range(1, 100, 1, "or_greater") var health: int = 100

# Enum exports
@export_enum("Easy", "Medium", "Hard") var difficulty: int = 0
@export_enum("Linear", "Quad", "Cubic") var transition_type: int = 0

# File/directory exports
@export_file("*.json") var config_path: String
@export_dir var asset_directory: String

# Multiline text exports
@export_multiline var description: String

# Color exports with alpha
@export var tint_color: Color = Color.WHITE

# Groups and categories
@export_group("Combat Settings")
@export var attack_power: int = 10
@export var defense_power: int = 5

@export_group("Visual Settings") 
@export var sprite_texture: Texture2D
@export var animation_speed: float = 1.0
```

### @onready Initialization
```gdscript
# Automatic initialization when node is ready
@onready var health_bar = $UI/HealthBar
@onready var tween = create_tween()
@onready var timer = $Timer

# Equivalent to:
# var health_bar
# func _ready():
#     health_bar = $UI/HealthBar
```

### Safe Node Access
```gdscript
# Safe node access (returns null if not found)
var node = get_node_or_null("path/to/node")
if node:
    node.do_something()

# Alternative pattern
if has_node("path/to/node"):
    get_node("path/to/node").do_something()
```

### Performance Monitoring Patterns
```gdscript
# Built-in performance tracking
func _process_with_timing(delta):
    var start_time = Time.get_ticks_usec()
    
    # ... processing logic ...
    
    var elapsed = (Time.get_ticks_usec() - start_time) / 1000000.0
    if elapsed > 0.016:  # > 16ms = frame drop
        push_warning("Slow frame: %f seconds" % elapsed)

# Frame-limited processing
const MAX_OPERATIONS_PER_FRAME = 100
const TIME_LIMIT_PER_FRAME = 0.001  # 1ms

func _process_queue():
    var start_time = Time.get_ticks_usec()
    var operations = 0
    
    while not queue.is_empty() and operations < MAX_OPERATIONS_PER_FRAME:
        if (Time.get_ticks_usec() - start_time) > TIME_LIMIT_PER_FRAME * 1000000:
            break  # Time limit reached
        
        process_next_item()
        operations += 1
```

### Memory Management Patterns
```gdscript
# Object pooling
var _object_pool: Array[MyObject] = []

func get_pooled_object() -> MyObject:
    if _object_pool.is_empty():
        return MyObject.new()
    return _object_pool.pop_back()

func return_to_pool(obj: MyObject):
    obj.reset()  # Clear state
    _object_pool.append(obj)

# Proper cleanup
func _exit_tree():
    # Always clean up signal connections
    if EventBus.some_signal.is_connected(_on_signal):
        EventBus.some_signal.disconnect(_on_signal)
    
    # Return pooled objects
    for obj in my_objects:
        return_to_pool(obj)
    my_objects.clear()
```

---

## Testing Best Practices (Godot 4.4)

### GUT Testing Framework Patterns
**Proven patterns that work reliably:**

```gdscript
extends GutTest

const MyClass = preload("res://src/MyClass.gd")
var instance: MyClass

func before_each():
    instance = MyClass.new()

func after_each(): 
    instance = null  # Clean references

# ✅ GOOD - Test one specific behavior
func test_should_increment_counter():
    instance.increment()
    assert_eq(instance.get_count(), 1, "Counter should increment by 1")

# ✅ GOOD - Test signal emission
func test_should_emit_signal_on_completion():
    var signal_count = 0
    instance.completed.connect(func(): signal_count += 1)
    
    instance.complete_task()
    assert_eq(signal_count, 1, "Should emit completed signal")

# ✅ GOOD - Test error conditions
func test_should_handle_invalid_input():
    var initial_state = instance.get_state()
    instance.process_invalid_data(null)
    assert_eq(instance.get_state(), initial_state, "State should not change on invalid input")
```

### Signal Testing Patterns

```gdscript
# ✅ CORRECT - Modern Godot 4.4 lambda syntax for signal testing
func test_signal_with_parameters():
    var received_values = []
    instance.value_changed.connect(func(old_val, new_val): 
        received_values.append([old_val, new_val])
    )
    
    instance.set_value(42)
    assert_eq(received_values.size(), 1, "Should emit signal once")
    assert_eq(received_values[0], [0, 42], "Should pass correct parameters")

# ✅ GOOD - Test signal disconnection
func test_signal_cleanup():
    var callback = func(): pass
    instance.some_signal.connect(callback)
    
    assert_true(instance.some_signal.is_connected(callback), "Signal should be connected")
    instance.some_signal.disconnect(callback)
    assert_false(instance.some_signal.is_connected(callback), "Signal should be disconnected")
```

### Serialization Testing

```gdscript
# ✅ EXCELLENT - Round-trip serialization testing
func test_serialization_round_trip():
    # Set up complex state
    instance.set_name("Test Object")
    instance.add_items(["item1", "item2"]) 
    instance.set_position(Vector2(10, 20))
    
    # Serialize
    var data = instance.to_dict()
    
    # Deserialize into new instance
    var new_instance = MyClass.new()
    new_instance.from_dict(data)
    
    # Verify all data preserved
    assert_eq(new_instance.get_name(), "Test Object", "Name should survive serialization")
    assert_eq(new_instance.get_items(), ["item1", "item2"], "Items should survive serialization")
    assert_eq(new_instance.get_position(), Vector2(10, 20), "Position should survive serialization")
```

### Testing State Machines

```gdscript
# ✅ GOOD - Test all state transitions
func test_state_machine_transitions():
    assert_eq(instance.get_state(), MyClass.State.INACTIVE, "Should start inactive")
    
    instance.activate()
    assert_eq(instance.get_state(), MyClass.State.ACTIVE, "Should transition to active")
    
    instance.complete()
    assert_eq(instance.get_state(), MyClass.State.COMPLETED, "Should transition to completed")
    
    # Test invalid transitions
    instance.activate()  # Try to reactivate
    assert_eq(instance.get_state(), MyClass.State.COMPLETED, "Should not allow invalid transition")
```

### Test Organization Anti-Patterns

```gdscript
# ❌ BAD - Testing multiple unrelated things
func test_everything():
    instance.set_name("test")  # Name functionality
    instance.add_item("item")  # Item functionality  
    instance.process()         # Processing functionality
    # Too much in one test!

# ❌ BAD - No assertions
func test_method_runs():
    instance.some_method()
    # No verification of results!

# ❌ BAD - Hardcoded magic numbers without explanation  
func test_calculation():
    var result = instance.calculate(5, 3)
    assert_eq(result, 8, "Should be 8")  # Why 8? What's the rule?

# ✅ GOOD - Focused, clear, documented
func test_should_add_numbers():
    var a = 5
    var b = 3
    var expected = a + b
    
    var result = instance.add(a, b)
    assert_eq(result, expected, "Should add two numbers correctly")
```

### Performance Testing Patterns

```gdscript
func test_operation_performance():
    var start_time = Time.get_ticks_usec()
    
    # Perform operation
    instance.expensive_operation()
    
    var elapsed_usec = Time.get_ticks_usec() - start_time
    var elapsed_ms = elapsed_usec / 1000.0
    
    # Should complete within reasonable time
    assert_lt(elapsed_ms, 100.0, "Operation should complete within 100ms")
```

---

## Quick Command Reference

### Headless Testing
```bash
# Check compilation only
godot --path /project/path --headless --check-only

# Run specific script
godot --path /project/path --headless --script test.gd

# Run with verbose output
godot --path /project/path --headless --verbose --script test.gd
```

### Project Validation
```bash
# Validate project settings
godot --path /project/path --headless --validate-conversion-3to4

# Export project (validates everything)
godot --path /project/path --headless --export-debug "Linux/X11"
```

---

## Emergency Debugging

### When Nothing Works
1. **Check base class** - 90% of errors are Node vs Resource issues
2. **Check autoload order** - Dependencies must load first
3. **Print scene tree** - `get_tree().root.print_tree()`
4. **Verify paths** - `ResourceLoader.exists(path)`
5. **Check instance validity** - `is_instance_valid(object)`

### 🔄 Autoload Initial Load Quirk (Known Godot Behavior)

**Symptom**: Autoloads appear to fail or throw errors on initial project load, but work correctly when re-run or after a second attempt.

**This is a KNOWN Godot 4.4 behavior**, not a bug in your code. It happens because:
1. **Script compilation order**: GDScript compiles scripts in dependency order during project scan
2. **Autoload initialization timing**: Autoloads initialize after all scripts compile, but type resolution happens during compilation
3. **Race condition window**: On first load, some class_name references may not yet be resolved when autoloads compile

**When you see this**:
```
# First run (may fail):
ERROR: Identifier "SomeClass" not declared in the current scope

# Second run (works):
(No errors - everything loads correctly)
```

**Solutions**:
1. **Re-run the project** - Often the simplest fix; the second run has all types resolved
2. **Use `load()` instead of `preload()`** - Defers resolution to runtime
3. **Use `load()` instead of class_name references** - Breaks compile-time dependency
4. **Check for circular preload chains** - These exacerbate the timing issue

```gdscript
# ❌ RISKY on initial load (compile-time resolution)
var manager = SomeManager.new()
const SomeClass = preload("res://src/SomeClass.gd")

# ✅ SAFE (runtime resolution)
var manager = load("res://src/SomeManager.gd").new()
func _ready():
    var SomeClass = load("res://src/SomeClass.gd")
```

**IDE/Editor Behavior**:
- Opening a project for the first time may show false errors
- Errors often disappear after "Reload Current Project" or re-opening
- CI/CD pipelines may need a "warm-up" run or multiple compilation passes

**Best Practice**: If you encounter this quirk regularly, audit your preload/class_name usage and convert problematic references to runtime `load()` calls.

### 🚨 Debugging Circular Dependencies

**Common symptoms:**
- "Identifier not found" errors during compilation
- Classes fail to load with `--check-only`
- "Could not resolve external class member" 
- Static methods can't reference their own class
- "Parser Error: Cyclic reference in constant function" (direct indicator!)

**Quick Detection Method:**
```bash
# 1. Map all preload dependencies
grep -rn "preload.*\.gd" src/ > preload_map.txt

# 2. For each file that uses preload, check if target also preloads it back
# Example: If Player.gd preloads Inventory.gd, check:
grep "preload.*Player\.gd" src/Inventory.gd

# 3. Test each file individually
godot --headless --check-only --script src/core/save/SaveFile.gd
godot --headless --check-only --script src/core/save/StateSerializer.gd

# 4. Check for self-references in static methods
grep -n "ClassName\.new()" src/**/*.gd
```

**How to Check if You Have a Circular Risk:**
```gdscript
# Before using preload, ask yourself:
# 1. Does the target class need to reference this class?
# 2. Will the target class ever create instances of this class?
# 3. Do they have a parent-child or manager-component relationship?

# If YES to any → Circular risk! Consider:
# - Making one an autoload (for managers)
# - Using load() in one direction
# - Dependency injection pattern
# - Signals for loose coupling
```

**Quick fixes:**
```gdscript
# ❌ If you see this pattern:
static func create_instance():
    return MyClass.new()  # Self-reference!

# ✅ Fix with load():
static func create_instance():
    return load("res://path/to/MyClass.gd").new()

# ❌ If autoload is excluded from serialization due to "circular dependency":
var system_names = ["EventBus", "CardDatabase"]  # SaveManager excluded

# ✅ Remember autoloads don't create circular dependencies:
var system_names = ["EventBus", "CardDatabase", "SaveManager"]  # Safe!
```

### Debug Print Helpers
```gdscript
# Print current class info
print("Class: ", get_class())
print("Script: ", get_script().resource_path)
print("Methods: ", get_method_list())

# Print scene tree location
if has_method("get_path"):
    print("Path: ", get_path())

# Print available autoloads
var tree = Engine.get_main_loop() as SceneTree
for child in tree.root.get_children():
    print("Autoload: ", child.name)
```

---

## File Organization Impact

| File Type | Base Class | Location | Access Pattern |
|-----------|------------|----------|----------------|
| Managers | Node | Autoload | Global singleton |
| Resources | Resource | /data/ | Load as needed |
| Components | Node/Resource | /src/ | Created by owners |
| UI | Control | /ui/ | Scene instances |
| Game Logic | Node/Resource | /src/ | Varies |

---

## Critical Development Gotchas (Production-Tested)

### 🚨 Top 6 Errors That WILL Happen
1. **NEVER use RefCounted as fallback** - Anti-pattern that breaks type safety
2. **Never use `class_name` in autoloaded scripts** - Causes singleton conflicts
3. **Don't override Object methods** like `to_string()` - Compilation errors
4. **Can't use `get_script()` in static functions** - No instance context
5. **Standalone scripts can't access autoloads** - Use scene-based testing
6. **Always export DISPLAY** for WSL headless testing - Required for CI/CD

### 🔧 Emergency Checklist
When nothing works, check in this order:
- [ ] Base class correct (Node for managers, Resource for data, NEVER RefCounted)?
- [ ] Autoload has class_name removed?
- [ ] Circular dependency via preload/class_name?
- [ ] **Self-reference in static methods** (`MyClass.new()` within MyClass)?
- [ ] **Autoload incorrectly excluded** from system serialization?
- [ ] Using scene-based testing for autoload access?
- [ ] All signals properly disconnected in _exit_tree()?

### ⚡ Proven Patterns That Work
These patterns were validated in production:
1. **Dynamic loading** - `var Script = load("path"); Script.new()`
2. **Scene-based testing** - TestScene.gd for autoload access
3. **Performance monitoring** - Time.get_ticks_usec() for frame timing
4. **Memory management** - Object pooling and _exit_tree() cleanup
5. **Explicit typing** - Avoid `:=` inference when ambiguous
6. **Self-reference fix** - `load("res://path/to/MyClass.gd").new()` in static methods
7. **Autoload serialization** - Include all autoloads in system serialization safely

---

## Production-Tested Development Workflow

### ✅ Reliable Implementation Process

**From Mission System implementation experience:**

1. **Class Creation Order**:
   ```gdscript
   # ✅ CORRECT - Simple to complex
   1. Create base data classes first (extends Resource)
   2. Add class_name declarations immediately
   3. Build manager classes last (extends Node)  
   4. Test each class individually before integration
   ```

2. **Testing Strategy**:
   ```gdscript
   # ✅ WORKS - Comprehensive testing approach
   1. Write unit tests using GUT framework
   2. Create verification scripts for integration testing
   3. Use headless compilation checks frequently
   4. Test serialization round-trips for data classes
   ```

3. **Error Resolution Priority**:
   ```gdscript
   # When errors occur, check in this order:
   1. Compilation: godot --headless --check-only
   2. Class names: Ensure class_name declarations exist
   3. Dependencies: Check preload vs load usage
   4. Base classes: Node vs RefCounted vs Resource
   5. Reserved words: Avoid Godot built-in names
   ```

### 🎯 Godot 4.4 Success Checklist

**Before committing any new system:**

- [ ] **All classes compile**: `godot --headless --check-only` passes
- [ ] **Proper class hierarchy**: Resource for data, Node for managers (AVOID RefCounted)
- [ ] **class_name declared**: Every class has proper class_name 
- [ ] **Modern signal syntax**: Using `func()` lambdas for connections
- [ ] **Typed arrays**: `Array[String]` not `Array`
- [ ] **Reserved word check**: No `assert`, `print`, `str` function names
- [ ] **Test coverage**: GUT tests for all public methods
- [ ] **Serialization tested**: Round-trip to_dict/from_dict works
- [ ] **Performance validated**: Critical operations under target times
- [ ] **Integration verified**: Works with existing systems

### 📚 Learning Resources Applied

**Key Godot 4.4 concepts successfully used:**
- **Lambda functions**: `signal.connect(func(param): action)`  
- **Typed collections**: `Array[String]`, `Dictionary`
- **Modern enum syntax**: `MyClass.EnumType.VALUE`
- **Resource pattern**: For pure data classes (NOT RefCounted)
- **Signal-driven architecture**: Event-based system communication
- **Resource serialization**: JSON-compatible data structures
- **Scene-tree independence**: Resource classes work headlessly

---

*Remember: When in doubt, check the base class first. Most Godot errors stem from trying to use Node methods in non-Node classes.*

---

## 🆕 Additional Patterns from Production Experience

### Resource Class Built-in Method Conflicts

**CRITICAL**: Resource base class has built-in methods that cannot be overridden in Godot 4.4

```gdscript
# ❌ WRONG - Conflicts with Resource.duplicate() built-in
class_name CardQuery
extends Resource
func duplicate() -> CardQuery:  # ERROR: "overrides native class method"
    return CardQuery.new()

# ✅ CORRECT - Use different method name  
func duplicate_query() -> CardQuery:
    var QueryClass = load("res://src/core/cards/CardQuery.gd")
    return QueryClass.new()
```

**Common Resource built-in methods to avoid overriding:**
- `duplicate()` - Creates deep/shallow copies
- `get_class()` - Returns class name string
- `get_script()` - Returns attached script
- `to_string()` - String representation

### Static Factory Methods in Resource Classes

**Issue**: Self-reference in static methods creates circular compile dependency

```gdscript
# ❌ WRONG - Circular dependency error
class_name CardDefinition
extends Resource
static func create_from_data(data: Dictionary) -> CardDefinition:
    return CardDefinition.new()  # ERROR: Needs CardDefinition resolved to compile CardDefinition!

# ✅ SOLUTION 1 - Use load() to break compile-time dependency
static func create_from_data(data: Dictionary) -> CardDefinition:
    var DefClass = load("res://src/core/cards/CardDefinition.gd")
    return DefClass.new()

# ✅ SOLUTION 2 - Use get_script() pattern  
func create_copy() -> CardDefinition:
    return get_script().new()

# ✅ SOLUTION 3 - Make instance method instead of static
func create_from_data(data: Dictionary) -> CardDefinition:
    var new_def = CardDefinition.new()  # Works fine - no compile loop
    new_def.apply_data(data)
    return new_def
```

**Why this happens**: GDScript must resolve class names at compile time, creating circular dependency when a class references itself in static context.

### Autoload Access from Resource Classes

**Problem**: Resource classes aren't part of scene tree, can't use `get_node()` or direct autoload access

```gdscript
# ❌ WRONG - Resource classes can't access scene tree directly
class_name CardQuery
extends Resource
func execute() -> Array:
    return CardDatabase.get_all_cards()  # ERROR: Not available in headless/Resource context

# ✅ CORRECT - Use Engine pattern for autoload access
func execute() -> Array:
    var card_db = _get_card_database()
    return card_db.get_all_cards() if card_db else []

## Helper method for accessing autoloads from Resource classes
func _get_card_database():
    var tree = Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        return tree.root.get_node("CardDatabase")
    return null
```

**Alternative pattern for multiple autoloads:**
```gdscript
func _get_autoload(autoload_name: String):
    var tree = Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        return tree.root.get_node(autoload_name)
    return null

func execute() -> Array:
    var card_db = _get_autoload("CardDatabase")
    var event_bus = _get_autoload("EventBus")
    # Use safely with null checks
```

### Type Inference Issues with String Operations

**Problem**: Godot 4.4 type inference can fail with string concatenation

```gdscript
# ❌ FAILS - "Cannot infer the type of variable because the value doesn't have a set type"
var file_path := directory + card_id + ".tres"

# ✅ WORKS - Explicit typing
var file_path: String = directory + card_id + ".tres"

# ❌ ALSO FAILS - StringName vs String incompatibility
var node_name: StringName = "Player"
var full_path := "/root/" + node_name  # ERROR: Invalid operands

# ✅ WORKS - Explicit conversion
var full_path: String = "/root/" + str(node_name)
```

**When to use explicit typing vs inference:**
- **Use `:=` when**: Result type is obvious (`var card = Card.new()`)
- **Use `: Type =` when**: String operations, mixed types, or complex expressions
- **Always check**: If you see "cannot infer type" errors

### Resource vs Node Decision Matrix

**Updated decision guide based on production experience:**

| Use Resource When: | Use Node When: | Never Use RefCounted |
|-------------------|----------------|---------------------|
| ✅ Pure data classes | ✅ Need scene tree access | ❌ Anti-pattern in Godot 4.4 |
| ✅ Serializable configs | ✅ Need signals/lifecycle | ❌ Breaks type safety |
| ✅ Template/definition objects | ✅ UI components | ❌ No compile-time benefits |
| ✅ Factory products | ✅ Game objects with position | ❌ Memory management unclear |
| ✅ Query builders | ✅ Need child nodes | ❌ IDE support degraded |

**Resource class best practices:**
- Extend Resource for data that needs serialization
- Use static methods sparingly (prefer instance methods)
- Always handle autoload access gracefully (null checks)
- Consider autoload pattern if class needs global access

### Circular Dependency Resolution Strategies

**Complete strategy ranking for Godot 4.4:**

1. **Autoload pattern** (best) - Breaks cycles automatically
2. **Dependency injection** - Pass dependencies to constructors
3. **load() in static methods** - Runtime loading breaks compile cycles  
4. **Signals for communication** - Event-driven decoupling
5. **Separate interface/implementation** - Abstract base classes
6. **get_script().new()** - Self-instantiation without class name

**Example of dependency injection pattern:**
```gdscript
# Instead of CardQuery accessing CardDatabase directly
class_name CardQuery
extends Resource

var _database  # Injected dependency

func _init(database = null):
    _database = database

func execute() -> Array:
    if not _database:
        _database = _get_card_database()  # Fallback
    return _database.get_all_cards() if _database else []
```

---