extends TileMap
class_name TilePlacerStateMachine
#warnings-disable

var state = null
var previous_state = null
var states := {}

onready var parent = get_parent()


# Calls below functions.
func _unhandled_input(event: InputEvent):
	if state == null:
		return
	var transition = _get_transition(event)
	if transition != null:
		set_state(transition)


# Return value will be used to change state.
func _get_transition(event: InputEvent):
	return null


# Called on entering state.
# new_state is the state being entered.
# old_state is the state being exited.
func _enter_state(new_state: String, old_state) -> void:
	pass


# Called on exiting state.
# old_state is the state being exited.
# new_state is the state being entered.
func _exit_state(old_state, new_state: String) -> void:
	pass


# Sets state while calling _exit_state and _enter_state
# If you want to call this method use call_deferred.
func set_state(new_state: String) -> void:
	previous_state = state
	state = new_state
	
	if previous_state != null:
		_exit_state(previous_state, new_state)
	
	_enter_state(new_state, previous_state)


# Adds a state.
# Should be called in the _ready function.
func add_state(state_name: String) -> void:
	states[state_name] = state_name
