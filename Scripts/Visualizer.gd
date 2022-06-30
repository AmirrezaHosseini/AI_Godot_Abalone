extends Node

export var pieces_path : NodePath
onready var pieces = get_node(pieces_path)
var white_piece = preload("res://Scenes/White Piece.tscn")
var black_piece = preload("res://Scenes/Black Piece.tscn")
var turn
var inital_state
var transposition = []
var states = {}
const gravity_center= [
	30, #1
	21,22,31,39,38,29,#6
	13,14,15,23,32,40,47,46,45,37,28,20,#12
	6,7,8,9,16,24,33,41,48,54,53,52,51,44,36,27,19,12,#18
	0,1,2,3,4,10,17,25,34,42,49,55,60,59,58,57,56,50,43,35,26,18,11,5,#24
]


func _ready():
	draw_complete_board(BoardManager.current_board)
	var first_board = BoardManager.current_board
	inital_state = State.new(first_board, 0,0)
	turn = 2
	
	
func _process(delta):
	inital_state = minimax_depth_limit(inital_state, 2, turn)
	turn = 3 - turn
	update_board(inital_state.board)


func evaluate(piece, board):
	var result = 0
	var marbles = get_marbles(piece, board)
	var marbles_opp = get_marbles(3 - piece, board)
	result += 1000 * (len(marbles) - len(marbles_opp))
	result += +10 * center_distance(marbles)
	result += -50 * center_distance(marbles_opp)
	result += 10 * grouping(marbles)
	result += -50 * grouping(marbles_opp)
	return result
	
func transposition_table(moves):
	var filtered_moves = []
	for move in moves:
		if transposition.has(move.board):
			continue
		filtered_moves.append(move)
	return filtered_moves
	
func center_distance(marbles):
	var score = 0
	for p in marbles: 
		var index = gravity_center.find(p)
		if index < 24:
			score += 400
		elif index < 30:
			score += 300
		elif index < 35:
			score += 200
		else:
			score += 100
	return score
	
	
func delete_moves(moves, current_state, turn):
	var smart_moves = []
	for move in moves:
		if turn == 1:
			if move.white_score >= current_state.white_score:
				smart_moves.append(move)
		elif turn == 2:
			if move.black_score >= current_state.black_score:
				smart_moves.append(move)
	var final_moves = bublesort_moves(turn, smart_moves)
	return final_moves

func get_marbles(piece, board):
	var indexes = []
	for index in range(len(board)):
		if board[index] == piece:
			indexes.append(index)
	return indexes
	
func bublesort_moves(turn,moves):
	for move in moves: 
		move.heuristic_score = evaluate(turn ,move.board)
	var n = len(moves)
	for i in range(n):
		for j in range(0, n - i - 1):
			if moves[j].heuristic_score < moves[j+1].heuristic_score:
				var movej = moves[j]
				moves[j] = moves[j+1]
				moves[j+1] = moves[j]
	return moves
	
func minimax_depth_limit(state, depth, current_turn):
	return max_func(state, depth, current_turn)
	
	

func max_func(state, depth, current_turn):
	var alpha=-INF
	var beta=INF
	if state.black_score == 6 or state.white_score == 6 or depth <= 0:
		return state
		
	var legal_moves
	legal_moves = Successor.calculate_successor(state, turn)
	var legal_move_filtered = transposition_table(legal_moves)
	var smart_moves = delete_moves(legal_move_filtered, state, turn)
	
	for move in smart_moves:
		var min_state = min_func(move, depth-1, turn)
		if  move.heuristic_score >= beta:
			state = move
			return state
		elif move.heuristic_score > alpha:
			state = move
			alpha = move.heuristic_score
	
	return state


func min_func(state, depth, current_turn):
	var alpha=-INF
	var beta=INF
	if state.black_score == 6 or state.white_score == 6 or depth <= 0:
		return state
		
	var legal_moves
	legal_moves = Successor.calculate_successor(state, turn)
	var legal_move_filtered = transposition_table(legal_moves)
	var smart_moves = delete_moves(legal_move_filtered, state, turn)
	for move in smart_moves:
		var max_state = max_func(move, depth-1, turn)
		if  move.heuristic_score <= alpha:
			state = move
			return state
		elif move.heuristic_score < beta:
			state = move
			beta = move.heuristic_score
	return state


func grouping(marbles):
	var score = 0
	for marbel in marbles:
		if BoardManager.neighbors[marbel][BoardManager.L] in  marbles:
			score += 1
		if BoardManager.neighbors[marbel][BoardManager.UL] in marbles:
			score += 1
		if BoardManager.neighbors[marbel][BoardManager.UR] in marbles:
			score += 1
		if BoardManager.neighbors[marbel][BoardManager.DR] in marbles:
			score += 1
		if BoardManager.neighbors[marbel][BoardManager.DL] in marbles:
			score += 1
		if BoardManager.neighbors[marbel][BoardManager.R] in  marbles:
			score += 1
	return score




		

func print_history():
	for state in states:
		print(str(states[state]) + ": " + str(state.value))

func update_board(new_board):
	for child in pieces.get_children():
		child.queue_free()
	draw_complete_board(new_board)


func draw_complete_board(board):
	var coordinates = Vector3(0, 0, 0)
	for cell_number in range(len(board)):
		if board[cell_number] == BoardManager.WHITE:
			coordinates = get_3d_coordinates(cell_number)
			var piece = white_piece.instance()
			pieces.add_child(piece)
			piece.translation = coordinates
		elif board[cell_number] == BoardManager.BLACK:
			coordinates = get_3d_coordinates(cell_number)
			var piece = black_piece.instance()
			pieces.add_child(piece)
			piece.translation = coordinates


func get_3d_coordinates(cell_number):
	if cell_number >= 0 and cell_number <= 4:
		return Vector3(-0.6 + cell_number * 0.3, 0.01, -1.04)
	elif cell_number >= 5 and cell_number <= 10:
		return Vector3(-0.75 + (cell_number - 5) * 0.3, 0.01, -0.78)
	elif cell_number >= 11 and cell_number <= 17:
		return Vector3(-0.9 + (cell_number - 11) * 0.3, 0.01, -0.52)
	elif cell_number >= 18 and cell_number <= 25:
		return Vector3(-1.05 + (cell_number - 18) * 0.3, 0.001, -0.26)
	elif cell_number >= 26 and cell_number <= 34:
		return Vector3(-1.2 + (cell_number - 26) * 0.3, 0.01, 0)
	elif cell_number >= 35 and cell_number <= 42:
		return Vector3(-1.05 + (cell_number - 35) * 0.3, 0.01, 0.26)
	elif cell_number >= 43 and cell_number <= 49:
		return Vector3(-0.9 + (cell_number - 43) * 0.3, 0.01, 0.52)
	elif cell_number >= 50 and cell_number <= 55:
		return Vector3(-0.75 + (cell_number - 50) * 0.3, 0.01, 0.78)
	else:
		return Vector3(-0.6 + (cell_number - 56) * 0.3, 0.01, 1.04)


