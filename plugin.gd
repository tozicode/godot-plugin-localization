@tool
extends EditorPlugin

var inspector_plugin
var dock


func _enter_tree():
	# オートロードを登録
	add_autoload_singleton("Localization", "res://addons/localization/localization.gd")

	# インスペクタプラグインを登録
	inspector_plugin = preload("res://addons/localization/localized_string_inspector.gd").new()
	add_inspector_plugin(inspector_plugin)

	# ドックを登録
	dock = preload("res://addons/localization/localization_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)


func _exit_tree():
	# ドックを解除
	remove_control_from_docks(dock)
	dock.free()

	# インスペクタプラグインを解除
	remove_inspector_plugin(inspector_plugin)

	# オートロードを解除
	remove_autoload_singleton("Localization")
