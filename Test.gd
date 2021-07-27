extends Node2D

export(int) var LIMIT = 17

onready var txtf:TextEdit = $VBoxContainer/TextEdit

var current_text = ''
var cursor_line = 0
var cursor_column = 0

func _ready():
	pass

func _on_Button_pressed():
	$QrCode.generate_qrcode(txtf.text, 21)
	pass # Replace with function body.


#https://godotengine.org/qa/44117/how-to-add-a-character-limit-to-text-edit-node
func _on_TextEdit_text_changed():
	var new_text : String = txtf.text
	if new_text.length() > LIMIT:
		txtf.text = current_text
		# when replacing the text, the cursor will get moved to the beginning of the
		# text, so move it back to where it was 
		txtf.cursor_set_line(cursor_line)
		txtf.cursor_set_column(cursor_column)

	current_text = txtf.text
	# save current position of cursor for when we have reached the limit
	cursor_line = txtf.cursor_get_line()
	cursor_column = txtf.cursor_get_column()
