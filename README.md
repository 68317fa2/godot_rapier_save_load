# godot_rapier_save_load
- small project implementing single-platform deterministic godot rapier save/load
- uses `PackedScene`s for saving as described in the [Godot documentation](https://docs.godotengine.org/en/stable/classes/class_packedscene.html)
- through testing it was observed that the following two conditions must be met to get a deterministic simulation:
  - reload the scene tree and only then instantiate the scene (with `get_tree().reload_current_scene()`)
  - the physics-objects (`RigidBody2D`s, `Area2D`s) must be located at the same position in the scene tree. other state like `RID`s is unimportant for the simulation
  - load the rapier state not until the next physics tick

## tutorial
- load scene with `Ctrl-L`
- save scene with `Ctrl-S` (per default into `res://scenes/test.tscn`)
- when the loaded scenes contain different objects, errors are thrown on subsequent loads:
```
  <godot_rapier::bodies::rapier_collision_object_base::RapierCollisionObjectBase as core::ops::drop::Drop>::drop: Body leaked
  <C++ Source>  src/bodies/rapier_collision_object_base.rs:601 @ <godot_rapier::bodies::rapier_collision_object_base::RapierCollisionObjectBase as core::ops::drop::Drop>::drop()
```
- also, the `rapier_state.import_state()` function does not work correctly if the bodies differ from the previously loaded scene
  - as seen through `diff logs/state_a.txt logs/state_b.txt`, the imported `physics_objects_state` is empty
- to reproduce the bug:
  - set `load_save("test2")` in `main.gd`, line 21
  - run the DEBUG mode
  - load the scene with `Ctrl-L` twice
  - observe the bug

