extends Popup

var npc_name setget name_set
var dialogue setget dialogue_set
var answers setget answers_set
var npc

func name_set(new_value):
	npc_name = new_value
	$ColorRect/CharacterName.bbcode_text = new_value

func dialogue_set(new_value):
	dialogue = new_value
	$ColorRect/Dialogue.bbcode_text = new_value

func answers_set(new_value):
	answers = new_value
	$ColorRect/Answers.bbcode_text = new_value

func open():
	get_tree().paused = true
	popup()
	$AnimationPlayer.playback_speed = 60.0 / dialogue.length()
	$AnimationPlayer.play("ShowDialogue")

func close():
	get_tree().paused = false
	hide()
	
func _ready():
	set_process_input(false)


func _on_AnimationPlayer_animation_finished(anim_name):
	set_process_input(true)
	
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_Z:
			set_process_input(false)
			npc.talk('Z')
		elif event.scancode == KEY_X:
			set_process_input(false)
			npc.talk('X')
		elif event.scancode == KEY_C:
			set_process_input(false)
			npc.talk('C')
		elif event.scancode == KEY_V:
			set_process_input(false)
			npc.talk('V')