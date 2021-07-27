extends Sprite

#Considerations about the current state od the project:
#Still on the early beginnings, steps being studied and taken from:
#https://www.thonky.com/qr-code-tutorial
#Good read for everyone who wants to know more about QRCodes
#Steps so far (only encompasses V1):
# - Finder Patterns
# - Data encoding
#Next:
# - Version and error type information
# - Error calculation
# - Data Masking

enum MODE {
	BYTE = 1,
	KANJI = 2
	ALPHANUM = 4,
	NUMERIC = 8,
}

enum DIR {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var APLHANUM_TABLE:Dictionary = {
	'0':0,'1':1,'2':2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8,'9':9,
	'A':10,'B':11,'C':12,'D':13,'E':14,'F':15,'G':16,'H':17,'I':18,'J':19,
	'K':20,'L':21,'M':22,'N':23,'O':24,'P':25,'Q':26,'R':27,'S':28,'T':29,
	'U':30,'V':31,'W':32,'X':33,'Y':34,'Z':35,' ':36,'$':37,'%':38,'*':39,
	'+':40,'-':41,'.':42,'/':43,':':44
}

var silent:int = 3

func _ready():
	pass

func generate_qrcode(data:String, size:int):
	var mode:int = _evaluate_mode(data)
	_create_texture(size, data)
	pass

func _create_texture(size:int, data:String):
	var _image:Image = Image.new()
	var _image_final:Image = Image.new()
	_image.create(size, size, false, Image.FORMAT_RGB8)
	_image_final.create(size + 2*silent, size + 2*silent, false, Image.FORMAT_RGB8)
	
	_image.lock()
	_image_final.lock()
	
	for x in range(size):
		for y in range(size):
			_image.set_pixel(x, y, Color.white)
	_write_mode(_image, MODE.BYTE)
	_write_msg(_image, data)
	_apply_mask(_image, 0)
	_place_markers(_image)
	
	for x in range(size + 2*silent):
		for y in range(size + 2*silent):
			_image_final.set_pixel(x, y, Color.white)
	for x in range(_image.get_width()):
		for y in range(_image.get_height()):
			_image_final.set_pixel(x + silent, y + silent, _image.get_pixel(x, y))
	
	_image.unlock()
	_image_final.unlock()
	
	var _texture:ImageTexture = ImageTexture.new()
	_texture.create_from_image(_image_final, ImageTexture.FLAG_CONVERT_TO_LINEAR)
	texture = _texture
	pass

func _write_mode(_image:Image, mode:int):
	_write_value_v(
		_image, 
		mode, 
		Vector2(_image.get_width() - 2, _image.get_height() - 2),
		Vector2(2,2)
	)
	pass

func _write_msg(_image:Image, msg:String):
	#Message Size
	_write_value_v(
		_image, 
		msg.length(), 
		Vector2(_image.get_width() - 2, _image.get_height() - 6),
		Vector2(2,4)
	)
	
	#Hard coded positions and directions for data areas
	var positions:Array = [
		[Vector2(_image.get_width() - 2, _image.get_height() - 10), DIR.UP],
		[Vector2(_image.get_width() - 4, _image.get_height() - 12), DIR.LEFT],
		[Vector2(_image.get_width() - 4, _image.get_height() - 10), DIR.DOWN],
		[Vector2(_image.get_width() - 4, _image.get_height() - 6), DIR.DOWN],
		[Vector2(_image.get_width() - 6, _image.get_height() - 2), DIR.RIGHT],
		[Vector2(_image.get_width() - 6, _image.get_height() - 6), DIR.UP],
		[Vector2(_image.get_width() - 6, _image.get_height() - 10), DIR.UP],
		[Vector2(_image.get_width() - 8, _image.get_height() - 12), DIR.LEFT],
		[Vector2(_image.get_width() - 8, _image.get_height() - 10), DIR.DOWN],
		[Vector2(_image.get_width() - 8, _image.get_height() - 6), DIR.DOWN],
		[Vector2(_image.get_width() - 10, _image.get_height() - 2), DIR.RIGHT],
		[Vector2(_image.get_width() - 10, _image.get_height() - 6), DIR.UP],
		[Vector2(_image.get_width() - 10, _image.get_height() - 10), DIR.UP],
		[Vector2(_image.get_width() - 10, _image.get_height() - 14), DIR.UP],
		[Vector2(_image.get_width() - 10, _image.get_height() - 19), DIR.UP],
		[Vector2(_image.get_width() - 12, _image.get_height() - 21), DIR.LEFT],
		[Vector2(_image.get_width() - 12, _image.get_height() - 19), DIR.DOWN],
		
	]
	#Encoding Message
	#Each _write function creates a image area
	#based on the direction as V1 specs require
	var size = min(positions.size(), msg.length() - 1)
	for i in range(size):
		var data:int = msg.to_utf8()[i]
		print(data)
		match positions[i][1]:
			DIR.UP:
				_write_value_v(
					_image, 
					data, 
					positions[i][0],
					Vector2(2,4)
				)
			DIR.LEFT:
				_write_value_h(
					_image, 
					data, 
					positions[i][0],
					Vector2(4,2)
				)
			DIR.DOWN:
				_write_value_v_r(
					_image, 
					data, 
					positions[i][0],
					Vector2(2,4)
				)
			DIR.RIGHT:
				_write_value_h_r(
					_image, 
					data, 
					positions[i][0],
					Vector2(4,2)
				)
	pass

func _to_bit_array(value:int)->Array:
	var arr:Array = []
	for b in range(8):
		if value & (1 << b) != 0:
			arr.append(1)
		else:
			arr.append(0)
	print(arr)
	return arr
	

func _write_value_v(_image:Image, value:int, pos:Vector2, sz:Vector2):
	var arr:Array = _to_bit_array(value)
	var idx:int = 0
	for y in range(sz.y):
		for x in range(sz.x):
			if arr[idx] == 1:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y +  sz.y - 1 - y, Color.black)
			else:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y +  sz.y - 1 - y, Color.white)
			idx += 1
	pass

func _write_value_v_r(_image:Image, value:int, pos:Vector2, sz:Vector2):
	var arr:Array = _to_bit_array(value)
	var idx:int = 0
	for y in range(sz.y):
		for x in range(sz.x):
			if arr[idx] == 1:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y + y, Color.black)
			else:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y + y, Color.white)
			idx += 1
	pass

func _write_value_h(_image:Image, value:int, pos:Vector2, sz:Vector2):
	var arr:Array = _to_bit_array(value)
	var idx:int = 0
	for y in range(sz.y):
		for x in range(sz.x/2):
			if arr[idx] == 1:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y +  sz.y - 1 - y, Color.black)
			else:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y +  sz.y - 1 - y, Color.white)
			idx += 1
	for y in range(sz.y):
		for x in range(sz.x/2, sz.x):
			if arr[idx] == 1:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y + y, Color.black)
			else:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y + y, Color.white)
			idx += 1
	pass

func _write_value_h_r(_image:Image, value:int, pos:Vector2, sz:Vector2):
	var arr:Array = _to_bit_array(value)
	var idx:int = 0
	for y in range(sz.y):
		for x in range(sz.x/2):
			if arr[idx] == 1:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y + y, Color.black)
			else:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y + y, Color.white)
			idx += 1
	for y in range(sz.y):
		for x in range(sz.x/2, sz.x):
			if arr[idx] == 1:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y +  sz.y - 1 - y, Color.black)
			else:
				_image.set_pixel(pos.x + sz.x - 1 - x, pos.y +  sz.y - 1 - y, Color.white)
			idx += 1
	pass

func _evaluate_mode(data:String)->int:
	#if only numbers
	if data.is_valid_integer():
		return MODE.NUMERIC
	
	#if all chars are on the table
	#https://www.thonky.com/qr-code-tutorial/alphanumeric-table
	if APLHANUM_TABLE.has_all(data.to_ascii()):
		return MODE.ALPHANUM
	
	#or else, is Byte, kanji for now unsupported
	return MODE.BYTE

func _place_markers(_image:Image):
	_place_position_markers(_image)
	if _image.get_width() != 21:
		_place_alignment_marker(_image)
	_place_timing_patterns(_image)
	pass

func _place_position_markers(_image:Image):
	_draw_marker(_image, Vector2(0,0), 7)
	_draw_marker(_image, Vector2(_image.get_width() - 7,0), 7)
	_draw_marker(_image, Vector2(0,_image.get_height() - 7), 7)
	pass

func _place_alignment_marker(_image:Image):
	_draw_marker(_image, Vector2(
		_image.get_width() - 8,
		_image.get_height() - 8
	), 5)
	pass

func _place_timing_patterns(_image:Image):
	for x in range(7, _image.get_height() - 8):
		if x % 2 == 0:
			_image.set_pixel(6, x, Color.black)
		else:
			_image.set_pixel(6, x, Color.white)
	
	for y in range(7, _image.get_height() - 8):
		if y % 2 == 0:
			_image.set_pixel(y, 6, Color.black)
		else:
			_image.set_pixel(y, 6, Color.white)
	pass

func _draw_marker(_image:Image, _pos:Vector2, _sz:int):
	var sz:Vector2 = Vector2(_sz,_sz)
	_draw_square(_image, _pos, sz, Color.black)
	sz -= Vector2.ONE*2
	_pos += Vector2.ONE
	_draw_square(_image, _pos, sz, Color.white)
	sz -= Vector2.ONE*2
	_pos += Vector2.ONE
	_draw_square(_image, _pos, sz, Color.black)
	pass

func _apply_mask(_image:Image, mask_type:int):
	pass

func _draw_square(_image:Image, pos:Vector2, sz:Vector2, color:Color):
	for x in range(sz.x):
		for y in range(sz.y):
			_image.set_pixel(pos.x + x, pos.y + y, color)
	pass
