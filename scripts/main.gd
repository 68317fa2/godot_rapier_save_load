extends Node2D

var scene: Node2D = null
@export var rapier_state: StateManager2D
@export var current_ticks = 0

var todo_state = null

func _ready():
  get_tree().physics_frame.connect(_physics_frame)

  # load scenes
  if Static.next_scene:
    load_save(Static.next_scene)
  else:
    load_save("test2")

func load_save(path: String):
  # reset things
  # if scene:
  #   scene.free()
  # current_ticks = 0

  # add scene instance
  var instance = load("res://saves/" + path + ".tscn").instantiate()
  add_child(instance)
  scene = instance

  # get rapier physics state
  var state_path = "res://saves/" + path + ".json"
  if FileAccess.file_exists(state_path):
    var state = FileAccess.open(state_path, FileAccess.READ).get_as_text()
    # var space = get_world_2d().space
    # rapier_state.import_state(space, state)
    # TEST: load the physics state in the next frame
    todo_state = state

    # var new_state = rapier_state.export_state(space, "Json")
    # if new_state != state:
    #   print("unequal")
    # else:
    #   print("equal")

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
  if Input.is_action_just_pressed("load"):
    print("schedule load")

    Static.next_scene = "test"
    get_tree().reload_current_scene()

    # load_save("test")
  if Input.is_action_just_pressed("save"):
    print("save")
    save("test")

  # TEST: load the physics state in the next frame
  if todo_state:
    # import state
    var space = get_world_2d().space
    rapier_state.import_state(space, todo_state)

    # check if state was successfully loaded
    var new_state = rapier_state.export_state(space, "Json")
    if new_state != todo_state:
      FileAccess.open("logs/state_a.txt", FileAccess.WRITE).store_string(todo_state.replace(",", ",\n"))
      FileAccess.open("logs/state_b.txt", FileAccess.WRITE).store_string(new_state.replace(",", ",\n"))
      push_warning("loaded state is different from saved state")
      print("loaded state is different from saved state")
    else:
      print("loaded state successfully")

    todo_state = null

func _physics_process(_delta: float) -> void:
  current_ticks += 1
