extends Node3D
class_name AIController3D

enum ControlModes {
	INHERIT_FROM_SYNC, ## Inherit setting from sync node
	HUMAN, ## Test the environment manually
	TRAINING, ## Train a model
	ONNX_INFERENCE, ## Load a pretrained model using an .onnx file
	RECORD_EXPERT_DEMOS ## Record observations and actions for expert demonstrations
}
@export var control_mode: ControlModes = ControlModes.INHERIT_FROM_SYNC
## The path to a trained .onnx model file to use for inference (overrides the path set in sync node).
@export var onnx_model_path := ""
## Once the number of steps has passed, the flag 'needs_reset' will be set to 'true' for this instance.
@export var reset_after := 1000

@export_group("Record expert demos mode options")
## Path where the demos will be saved. The file can later be used for imitation learning.
@export var expert_demo_save_path: String
## The action that erases the last recorded episode from the currently recorded data.
@export var remove_last_episode_key: InputEvent
## Action will be repeated for n frames. Will introduce control lag if larger than 1.
## Can be used to ensure that action_repeat on inference and training matches
## the recorded demonstrations.
@export var action_repeat: int = 1

@export_group("Multi-policy mode options")
## Allows you to set certain agents to use different policies.
## Changing has no effect with default SB3 training. Works with Rllib example.
## Tutorial: https://github.com/edbeeching/godot_rl_agents/blob/main/docs/TRAINING_MULTIPLE_POLICIES.md
@export var policy_name: String = "shared_policy"

@onready var raycast_sensor := $RayCastSensor3D
@onready var position_sensor := $PositionSensor3D
@onready var approach_goal_reward := $ApproachNodeReward3D

var onnx_model: ONNXModel

var heuristic := "human"
var done := false
var reward := 0.0
var n_steps := 0
var needs_reset := false

var _player: Node3D


func _ready():
	add_to_group("AGENT")


func init(player: Node3D):
	_player = player


#region Methods that need implementing using the "extend script" option in Godot
func get_obs() -> Dictionary:
	#assert(false, "the get_obs method is not implemented when extending from ai_controller")
	
	var obs: Array
	obs.append_array(raycast_sensor.get_observation())
	obs.append_array(position_sensor.get_observation())
	return {"obs": obs}


func get_reward() -> float:
	#assert(false, "the get_reward method is not implemented when extending from ai_controller")
	#return 0.0
	reward += approach_goal_reward.get_reward()
	
	return reward


func get_action_space() -> Dictionary:
	"""
	assert(
		false, "the get_action_space method is not implemented when extending from ai_controller"
	)
	"""
	
	return {
		"move": {"size": 2, "action_type": "continuous"},
		"jump": {"size": 2, "action_type": "continuous"},
	}


func set_action(action) -> void:
	#assert(false, "the set_action method is not implemented when extending from ai_controller")
	
	_player.requested_movement.x = action["move"][0]
	_player.requested_movement.y = action["move"][1]
	_player.requested_jump = action["jump"][0] > 0


#endregion


#region Methods that sometimes need implementing using the "extend script" option in Godot
# Only needed if you are recording expert demos with this AIController
func get_action() -> Array:
	assert(
		false,
		"the get_action method is not implemented in extended AIController but demo_recorder is used"
	)
	return []


# For providing additional info (e.g. `is_success` for SB3 training)
func get_info() -> Dictionary:
	return {}
	#TODO: Find out what this function do

#endregion


func _physics_process(delta):
	n_steps += 1
	if n_steps > reset_after:
		reward -= 0.1
		needs_reset = true
		done = true


func get_obs_space():
	# may need overriding if the obs space is complex
	var obs = get_obs()
	return {
		"obs": {"size": [len(obs["obs"])], "space": "box"},
	}


func reset():
	n_steps = 0
	needs_reset = false


func reset_if_done():
	if done:
		reset()


func set_heuristic(h):
	# sets the heuristic from "human" or "model" nothing to change here
	heuristic = h


func get_done():
	return done


func set_done_false():
	done = false


func zero_reward():
	reward = 0.0
