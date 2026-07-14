# partially copied from https://github.com/appsinacup/godot-rapier-physics/blob/main/bin2d/tests/determinism/determinism_test.gd
class_name PhysicsHasher extends Node2D

@export var current_ticks = 0
@export var hash_ticks = 60*2
@export var output_path = "res://logs/determinism_test.txt"

@export var frame_records: Array[Dictionary] = []

func _physics_process(_delta: float) -> void:
  current_ticks += 1

  # Record state every frame
  var frame_state := {}
  for child in get_children_recursive(get_parent()):
    if child is RigidBody2D:
      frame_state[child.name] = _serialize_body(child)
  frame_records.append(frame_state)

  if current_ticks == hash_ticks:
    print(frame_records.size())
    
    for child in get_children_recursive(get_parent()):
      if child is RigidBody2D:
        print(child.transform)
    _finish()

    queue_free()

## Convert a float to its IEEE 754 bit representation as a hex string.
## This guarantees bit-exact comparison across platforms.
static func _float_to_hex(value: float) -> String:
  var buf := PackedByteArray()
  buf.resize(8)
  buf.encode_double(0, value)
  # Encode as big-endian hex for readability and consistent ordering
  var hex := ""
  for i in range(7, -1, -1):
    hex += "%02x" % buf[i]
  return hex

func _finish() -> void:
  var output := {
    "metadata": {
      "simulation_frames": hash_ticks,
      "physics_ticks_per_second": 60,
      "os": OS.get_name(),
      "arch": Engine.get_architecture_name(),
    },
    "frames": frame_records,
  }

  var json_string := JSON.stringify(output, " ", true)

  # Write to user:// directory
  var file := FileAccess.open(output_path, FileAccess.WRITE)
  if file:
    file.store_string(json_string)
    file.close()
    print("DETERMINISM_TEST: Output written to %s" % output_path)
    # Also compute a simple hash for quick comparison in logs
    var hash_val := json_string.md5_text()
    print("DETERMINISM_TEST: MD5=%s" % hash_val)
    print("DETERMINISM_TEST: STATUS=SUCCESS")
  else:
    print("DETERMINISM_TEST: ERROR - Failed to open output file")
    print("DETERMINISM_TEST: STATUS=FAILED")

## Serialize a body's full state using bit-exact float representation.
## Uses PhysicsServer2D.body_get_state() to read directly from the physics
## engine, bypassing any node-side caching or processing.
static func _serialize_body(body: RigidBody2D) -> Dictionary:
  var rid := body.get_rid()
  var trans: Transform2D = PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM)
  # var trans: Transform2D = PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM)
  var lin_vel: Vector2 = PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
  var ang_vel: float = PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY)
  return {
    "tx_ax": _float_to_hex(trans.x.x),
    "tx_ay": _float_to_hex(trans.x.y),
    "tx_bx": _float_to_hex(trans.y.x),
    "tx_by": _float_to_hex(trans.y.y),
    "tx_ox": _float_to_hex(trans.origin.x),
    "tx_oy": _float_to_hex(trans.origin.y),
    "vx": _float_to_hex(lin_vel.x),
    "vy": _float_to_hex(lin_vel.y),
    "av": _float_to_hex(ang_vel),
  }

static func get_children_recursive(node: Node, filter_deleted: bool = true) -> Array[Node]:
  var childs: Array[Node] = [node]
  var i = 0

  while i < len(childs):
    for child in childs[i].get_children():
      if !child.is_queued_for_deletion() || !filter_deleted:
        childs.append(child)
    i += 1

  return childs
