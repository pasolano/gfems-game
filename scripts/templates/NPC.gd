tool
extends KinematicBody2D
class_name NPC

export (int) var speed = 300
export (String, FILE) var dialogue_file
export (Array, String, FILE) var extra_dialogue
export (String) var npc_name
export (bool) var randomize_conversation = false
export (bool) var seated

# checkpoints are set up as arrays with x, y, delay at point in seconds, and visibility (0 for invisible, 1 for visible)
export (bool) var moves = false
export (Array, Array, int) var checkpoints = [[3075, 2304, 0, 1], [1839, 2304, 0, 1], [1839, 2117, 3, 0], [1839,2304, 0, 1], [3075,2304, 0, 1], [3075,2174, 3, 0]]


# pathfinding variables
var velocity = Vector2()



var current_destination = 0
var current_checkpoint
var pause_timer = 0
var x_dif
var y_dif
var current_check_viz
# references
var dialogue_popup
var player
var tool_tip
var detection
var collision
var dialogue

var response_num = "0"
var curr_data

func _get_configuration_warning():
	return "dialogue_file must be set" if dialogue_file == "" else ""

func _ready():
	dialogue_popup = get_tree().root.get_node("Root/DialogueLayer/DialoguePopup")
	player = get_tree().root.get_node("Root/YSort/Player")
	detection = get_node("NPCDetection")
	collision = get_node("CollisionShape2D")
	
# state machine
# check position, then update seen/velocity
func update_velocity(delta):
	velocity = Vector2()

	# get info about current checkpoint and check how far npc is from there
	current_checkpoint = checkpoints[current_destination]
	x_dif = self.position.x - current_checkpoint[0]
	y_dif = self.position.y - current_checkpoint[1]
	if current_checkpoint[3] == 0:
		current_check_viz = false
	else:
		current_check_viz = true

	# uses a 3 pixel fudge factor, as otherwise the velocity can overshoot the destination
	# move in direction of checkpoint
	# could be optimized by using vector math
	if x_dif >= 3:
		velocity.x -= 1
	elif x_dif <= -3:
		velocity.x += 1
	else:
		self.position.x = current_checkpoint[0]

	
	if y_dif >= 3:
		velocity.y -= 1
	elif y_dif <= -3:
		velocity.y += 1
	else:
		self.position.y = current_checkpoint[1]

	

	# if the character has arrived at the checkpoint, check if there is a delay
	if self.position.x == current_checkpoint[0] and self.position.y == current_checkpoint[1]:
		pause_timer += delta
		if pause_timer > current_checkpoint[2]:
			
			if current_destination == checkpoints.size() - 1:
				current_destination = 0
			else:
				current_destination += 1
			pause_timer = 0
			current_checkpoint = checkpoints[current_destination]
			if current_checkpoint[3] == 0:
				current_check_viz = false
			else:
				current_check_viz = true
			
			
			self.visible = current_check_viz
		else:
			
			self.visible = current_check_viz
	else:
		self.visible = true

	if self.visible:
		collision.disabled = false
		detection.disabled = false
	else:
		collision.disabled = true
		detection.disabled = true
		

	velocity = velocity.normalized() * speed


func _physics_process(delta):
	var direction = velocity.normalized()
	if moves:
		update_velocity(delta)
		velocity = move_and_slide(velocity)
	# Update player animation
	animation_manager(false, direction)
	
func animation_manager(convo, dir):
	var act_str = null
	var dir_s = null
	
	var action = "run"
	if dir == Vector2.ZERO:
		action = "idle"
		if seated:
			action = "sit"

	# if convo, should face the player
	if convo:
		# set animation to idle in direction of player
		var player_to_npc_x_delta = player.position.x - self.position.x
		var player_to_npc_y_delta = player.position.y - self.position.y

		# if player is further on the x axis, then the rotation should be on x axis
		if abs(player_to_npc_x_delta) >= abs(player_to_npc_y_delta):
			if player_to_npc_x_delta < 0:
				dir_s = "left"
			elif player_to_npc_x_delta > 0:
				dir_s = "right"
		else:
			if player_to_npc_y_delta < 0:
				dir_s = "up"
			elif player_to_npc_y_delta > 0:
				dir_s = "down"
	else:
		if dir.x == 1:
			dir_s = "right"
		if dir.x == -1:
			dir_s = "left"
		elif dir.y == 1:
			dir_s = "down"
		elif dir.y == -1:
			dir_s = "up"
			
	if dir_s:
		act_str = action + "_" + dir_s
		$AnimatedSprite.play(act_str)

# logic to select conversation, returns an integer depending on how conversation
# is selected. Each NPC can have a different funciton here
func select_conversation(dialogue_file, extra_dialogue, randomize_conversation) -> String:

	####################################
	# Logic for randomize_conversation #
	####################################
	if randomize_conversation:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var conversation = rng.randi(0, len(extra_dialogue))
		
		# if conversation is the length of dialogue, then keep regular dialogue_file
		# otherwise, set to one of the extra_dialogues
		if conversation != len(extra_dialogue):
			dialogue_file = extra_dialogue[conversation]
	
	#############################################################################################################
	# Default NPC behavior for getting extra dialogue 															#
	# If not the first time talking to character and there is extra_dialogue, get the first extra dialogue file #
	#############################################################################################################
	if (npc_name in PlayerData.conversations_held) and (len(extra_dialogue) > 0):
		# logic to select the dialogue file to load goes here.
		dialogue_file = extra_dialogue[0]
	
	return dialogue_file

func talk(answer = "") -> void:
	# load file and parse JSON
	var use_file = select_conversation(dialogue_file, extra_dialogue, randomize_conversation)
	
	dialogue = load_file(use_file)
		
	filename = use_file.split('/')[-1].split('.')[0]
	
	# Set dialoguePopup npc to neighbor
	dialogue_popup.npc = self
	
	# Update animation
	animation_manager(true, velocity.normalized())

	# Get player's dialogue choice
	if answer != "":
		var next_data = curr_data.next
		if answer == 'Z':
			response_num = next_data[0].id
		elif answer == 'X' and len(next_data) > 1:
			response_num = next_data[1].id
		elif answer == 'C' and len(next_data) > 2:
			response_num = next_data[2].id
		elif answer == 'V' and len(next_data) > 3:
			response_num = next_data[3].id
		elif answer == 'B':
			response_num = "-1"
		else:
			response_num = dialogue.start

	# Check if done
	if response_num == "-1":
		response_num = "0"
		dialogue_popup.close()
		
		# Keep track of the number of interactions between player and NPCs. Set
		# to add when the conversation ends.
		if npc_name in PlayerData.conversations_held:
			if !(filename in PlayerData.conversations_held[npc_name]):
				PlayerData.conversations_held[npc_name].append(filename)
		else:
			PlayerData.conversations_held[npc_name] = [filename]
		return
	
	# Set possible buttons
	# TODO don't hardcode this here
	var buttons = ['Z', 'X', 'C', 'V', 'B']
	
	var ans
	
	var answers = ""

	if response_num in dialogue.lines:
		curr_data = dialogue.lines[response_num]
	else:
		print("no such response number in file ", dialogue_file, " ", response_num)
		
	dialogue_popup.npc_name = curr_data.actor.replace("%player%", player.player_name)
	dialogue_popup.dialogue = curr_data.text.replace("%player%", player.player_name)
	for i in range(len(curr_data.next)):
		ans = curr_data.next[i]
		answers += '[' + buttons[i] + "] " + ans.text + "  "
	dialogue_popup.answers = "[center]%s[/center]" % answers
	dialogue_popup.answers = dialogue_popup.answers.replace("%player%", player.player_name)
	dialogue_popup.open()

# load file and parse JSON
func load_file(file_path: String):
	var file = File.new()
	assert (file.file_exists(file_path))
	file.open(file_path, file.READ)
	return parse_json(file.get_as_text())
