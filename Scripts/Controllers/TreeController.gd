class_name TreeController extends Node

@export var settings : TreeControllerSettings

var tree_map : Array[TreeBase] = []

var update_thread : Thread
var semaphore : Semaphore
var tree_map_mutex : Mutex
var update_timer : Timer

func _ready():
	update_thread = Thread.new()
	semaphore = Semaphore.new()
	tree_map_mutex = Mutex.new()
	update_timer = Timer.new()
	update_thread.start(update_trees)
	add_child(update_timer)
	update_timer.start(settings.base_update_rate)
	update_timer.connect('timeout',run_update)

func run_update() -> void:
	semaphore.post();
	
func update_trees() -> void:
	while true:
		semaphore.wait()
		print('running tree update')
		tree_map_mutex.lock()
		for tree in tree_map:
			pass
		tree_map_mutex.unlock()
		update_timer.call_deferred(('start'),settings.base_update_rate)

func _exit_tree() -> void:
	semaphore.post()
	update_thread.wait_to_finish()
