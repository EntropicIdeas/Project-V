
extends CharacterBody2D

@export var SPEED = 100
@export var JUMP_VELOCITY = -32000
@export var START_GRAVITY = 1700
@export var COYOTE_TIME = 140 # in ms
@export var JUMP_BUFFER_TIME = 100 # in ms
@export var JUMP_CUT_MULTIPLIER = 0.4
@export var AIR_HANG_MULTIPLIER = 0.95
@export var AIR_HANG_THRESHOLD = 50
@export var Y_SMOOTHING = 0.8
@export var AIR_X_SMOOTHING = 0.10
@export var MAX_FALL_SPEED = 25000
@export var DASHING = false 
@export var DASH_CD = true
@export var DASH_SPEED = 400
@onready var sprite: AnimatedSprite2D = $"AnimatedSprite2D"

var prevVelocity = Vector2.ZERO
var lastFloorMsec = 0
var lastJumpQueueMsec: int
var gravity = START_GRAVITY

func _ready():
	set_meta("tag", "player")

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if is_on_floor():
		lastFloorMsec = Time.get_ticks_msec()
		if Input.is_action_just_pressed("jump") or (Time.get_ticks_msec() - lastJumpQueueMsec < JUMP_BUFFER_TIME):
			velocity.y = JUMP_VELOCITY * delta
			sprite.play("Jump")
			
		elif Input.is_action_just_pressed("dash"): # and DASH_CD == true:

			DASHING = true
			DASH_CD = false
			$dash_timer.start()
			$dash_cooldown.start()

			
		else:
			if direction == 0:
				sprite.play("Idle")
				velocity.x = 0
			elif DASHING == true:
				sprite.play("Dash")
			else:
				sprite.play("Run")
				run(direction, delta)

	else:
		if Input.is_action_just_released("jump"):
			velocity.y *= JUMP_CUT_MULTIPLIER

		run(direction, delta)
		velocity.x = lerp(prevVelocity.x, velocity.x, AIR_X_SMOOTHING)
		
		if Input.is_action_just_pressed("jump") and (Time.get_ticks_msec() - lastFloorMsec < COYOTE_TIME):
			velocity.y = JUMP_VELOCITY * delta
			sprite.play("Jump")
		
		velocity.y += gravity * delta
		
		if abs(velocity.y) < AIR_HANG_THRESHOLD:
			gravity *= AIR_HANG_MULTIPLIER
		else:
			gravity = START_GRAVITY



	velocity.y = lerp(prevVelocity.y, velocity.y, Y_SMOOTHING)
	velocity.y = min(velocity.y, MAX_FALL_SPEED * delta)
	
	prevVelocity = velocity
	
	move_and_slide()
	
func run(direction, delta):
	if DASHING == false:
		velocity.x = SPEED * direction 
	else:
		velocity.x = DASH_SPEED * direction
	if direction != 0:
		sprite.flip_h = direction < 0

func die():
	velocity.x = 0
	velocity.y = 0
	sprite.stop()
	#sprite.play("dead")


func _on_dash_timer_timeout():
	DASHING = false 

func _on_dash_cooldown_timeout():
	DASH_CD = true
