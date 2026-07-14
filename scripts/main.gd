extends Node2D

var scene: Node2D = null
var current_ticks = 0
var todo_state = null

@export var rapier_state: StateManager2D

# if the scene tree should be reloaded before loading a scene
@export var reload_scene_on_load := true
# if the rapier state should be imported only on the next physics tick
@export var load_rapier_state_delayed := true

func _ready():
  get_tree().physics_frame.connect(_physics_frame)

  # load scenes
  if Static.next_scene:
    load_save(Static.next_scene)
  else:
    load_save("init")

func load_save(path: String):
  # reset things (only done when reload_scene_on_load == false)
  if scene:
    scene.free()
  current_ticks = 0

  # add scene instance
  var instance = load("res://saves/" + path + ".tscn").instantiate()
  add_child(instance)
  scene = instance

  # get rapier physics state
  var state_path = "res://saves/" + path + ".json"
  if FileAccess.file_exists(state_path):
    var state = FileAccess.open(state_path, FileAccess.READ).get_as_text()

    if load_rapier_state_delayed:
      todo_state = state
    else:
      _load_rapier_state(state)

func save(path: String):
  print("current tick: " + str(current_ticks))

  # pack scene
  var saved_scene = PackedScene.new()
  saved_scene.pack(scene)
  var save_path = "res://saves/" + path + ".tscn"

  # save scene to file
  ResourceSaver.save(saved_scene, save_path)

  # get rapier physics state
  var space = get_world_2d().space
  var state = rapier_state.export_state(space, "Json")

  # save state to file
  var state_path = "res://saves/" + path + ".json"
  FileAccess.open(state_path, FileAccess.WRITE).store_string(state)

func _physics_frame() -> void:
  # get input
  if Input.is_action_just_pressed("load"):
    print("loading")

    # schedule load
    if reload_scene_on_load:
      Static.next_scene = "test"
      get_tree().reload_current_scene()
    else:
      load_save("test")
  if Input.is_action_just_pressed("save"):
    print("saving")
    save("test")

  # load the physics state in this frame (delayed to the load)
  if todo_state:
    _load_rapier_state(todo_state)
    todo_state = null

func _physics_process(_delta: float) -> void:
  current_ticks += 1

func _load_rapier_state(state: Variant):
  var space = get_world_2d().space
  rapier_state.import_state(space, state)

  # check if state was successfully loaded
  var new_state = rapier_state.export_state(space, "Json")
  if new_state != state:
    # write error to logs
    FileAccess.open("logs/state_a.txt", FileAccess.WRITE).store_string(state.replace(",", ",\n"))
    FileAccess.open("logs/state_b.txt", FileAccess.WRITE).store_string(new_state.replace(",", ",\n"))
    push_warning("loaded state is different from saved state")
    print("loaded state is different from saved state")
  else:
    print("loaded state successfully")

  state = null

