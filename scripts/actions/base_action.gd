class_name BaseAction extends Node
## base class for a combat action for actors


########### CONFIG #############

@export_group("config")
@export var friendly_name : String = "":  ## name of the action, shown in the ui
	set(value):
		friendly_name = value
		_cooldown_timer.set_name("CooldownTimer_" + friendly_name)
		target_finder.set_name("TargetFinder_" + friendly_name)
@export var tags : Array[Constants.ActionTag] = []  ## property tags describing the action
@export var target_type : Constants.TargetType = Constants.TargetType.ENEMY  ## what target the action can effect
@export var target_preferences : Array[Constants.TargetPreference] = [Constants.TargetPreference.ANY]  ## what kind of target to find, within the target type
@export var trigger : Constants.ActionTrigger = Constants.ActionTrigger.ATTACK  ## what triggers the action
@export var action_type : Constants.ActionType = Constants.ActionType.ATTACK
@export var target_selection : Constants.ActionTargetSelection = Constants.ActionTargetSelection.ACTOR  ## what thing is selected to cast the action

@export var _base_stamina_cost : int = 0
@export var _base_cooldown : float = 0.0
@export var _base_damage : int = 0
@export var _base_damage_type : Constants.DamageType = Constants.DamageType.MUNDANE
@export var _base_range : int = 0
@export var _base_cast_time : float = 0.0

@export_group("", "")  # end grouping

######### ATTRIBUTES ##########

var uid : int
var _creator : Actor
var _target : Actor
var _cooldown_timer : Timer
## length of cooldown of action
var cooldown : float:
	get:
		# TODO: mod by creator stats
		return _base_cooldown
	set(_value):
		push_warning("Tried to set cooldown directly. Not allowed.")
## amount of time left on cooldown
var cooldown_remaining : float:
	get:
		return _cooldown_timer.time_left
	set(_value):
		push_warning("Tried to set cooldown_remaining directly. Not allowed.")
var range : float:
	get:
		# TODO: mod by creator stats
		return _base_range
	set(_value):
		push_warning("Tried to set range directly. Not allowed.")
var cast_time : float:
	get:
		# TODO: mod by creator stats
		return _base_cast_time
	set(_value):
		push_warning("Tried to set cast_time directly. Not allowed.")
## check if action is ready to use
var is_ready : bool = true:
	get:
		return _cooldown_timer.is_stopped()
	set(_value):
		push_warning("Tried to set is_ready directly. Not allowed.")
var target_finder: TargetFinder


######### UI ##############

var icon : Texture

########### SETUP  ###########

func _init(creator: Actor) -> void:
	_creator = creator

	uid = Utility.generate_id()

	# TODO: move components to sit under actions. They need the parents, which doesnt exist at init.
	target_finder = Factory.add_target_finder(_creator, range)
	target_finder.set_name("TargetFinder_" + friendly_name)

	_cooldown_timer = Timer.new()
	_cooldown_timer.set_name("CooldownTimer_" + friendly_name)
	_creator.add_child(_cooldown_timer)
	_cooldown_timer.set_one_shot(true)

	_configure()
	_setup()


## configure the action's base data
##
## @tag: virtual method
func _configure() -> void:
	assert(false, "Virtual method not overriden.")


## last step of setup, post config
func _setup() -> void:
	set_cooldown(cooldown)


########### FUNCTIONALITY ###########

## use action on a target
##
## must call super in subclass; this updates _target and charges stamina cost
func use(initial_target: Actor) -> void:
	_target = initial_target
	Combat.reduce_stamina(_creator, _base_stamina_cost)

	print(_creator.debug_name + " used " + friendly_name + " on " + initial_target.debug_name + ".")


## set the cooldown of the action and start the cooldown timer.
##
## value must be greater than 0, else ignored.
func set_cooldown(cooldown_time: float) -> void:
	# ignore if wait time == 0
	if cooldown_time > 0:
		_cooldown_timer.start(cooldown_time)


## reset cooldown timer to cooldown time
func reset_cooldown() -> void:
	set_cooldown(cooldown)

########### ATTIBUTE GETTERS ###############

## get the action's description
##
## description is held in function to make it easier to add dynamic data
## @tag: virtual method
func get_description() -> String:
	assert(false, "Virtual method not overriden.")
	return "No description set"


########## EFFECTS ##############

## get new target of a type, with a given preference, within a certain range
func _effect_new_target(
	target_type:Constants.TargetType,
	_preference: Constants.TargetPreference = Constants.TargetPreference.ANY,
	range: float = INF
	) -> void:
	push_warning("new target: effect not created")


## apply amount of damage to current target. returns damage dealth
func _effect_damage(amount: int, damage_type: Constants.DamageType) -> int:
	var damage = Combat.calculate_damage(_creator, _target, amount, damage_type)
	Combat.deal_damage(_creator, _target, damage, damage_type)

	return damage


## apply amount of damage to current target
func _effect_heal(amount: int) -> void:
	Combat.heal(_creator, _target, amount)


## apply a status effect to current target
func _effect_status(status_effect_name: String) -> void:
	# FIXME: status not being applied
	var action_type_ = Constants.ActionType.STATUS_EFFECT
	var script_path : String = Utility.get_action_type_script_path(action_type_) + status_effect_name + ".gd"
	var status_effect = load(script_path).new(_target)
	_target.status_effects.add_status_effect(status_effect)


## create a projectile. returns created projectile
func _effect_projectile(data: ProjectileData) -> Projectile:
	return Factory.create_projectile(data)


## create a summon
func _effect_summon(_summon) -> void:
	push_warning("summon: effect not created")


## create terrain
func _effect_terrain(_terrain) -> void:
	push_warning("terrain: effect not created")


## apply force as a vector
func _effect_apply_force(_velocity) -> void:
	push_warning("apply_force: effect not created")


## teleport to new location
func _effect_teleport(_direction, _distance) -> void:
	push_warning("teleport: effect not created")


## instantly kill target. returns true if successfully killed.
func _effect_kill() -> bool:
	# TODO - check for immunity
	Combat.kill(_creator, _target)

	return true
