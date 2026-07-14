- small project implementing single-platform deterministic godot rapier save/load
- uses `PackedScene`s for saving as described in the [Godot documentation](https://docs.godotengine.org/en/stable/classes/class_packedscene.html)
- through testing it was observed that the following two conditions must be met to get a deterministic simulation:
  - reload the scene tree and only then instantiate the scene (with `get_tree().reload_current_scene()`)
  - the physics-objects (`RigidBody2D`s, `Area2D`s) must be located at the same position in the scene tree. other state like `RID`s is unimportant for the simulation
  - load the rapier state not until the next physics tick


