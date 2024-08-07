# This singleton handles session data and settings.
extends Node

signal language_changed
signal ui_scale_changed
signal theme_changed
signal shortcuts_changed
signal number_precision_changed
signal highlight_colors_changed
signal basic_colors_changed
signal handle_visuals_changed
signal window_title_scheme_changed

# Session data
var save_data := SaveData.new()
const save_path = "user://save.tres"

# Settings
var config := ConfigFile.new()
const config_path = "user://config.tres"

func get_default(section: String, setting: String) -> Variant:
	return defaults[section][setting][0]

func get_signal(section: String, setting: String) -> Signal:
	return defaults[section][setting][1]

# Don't have the language setting here, so it's not reset.
var defaults = {
	"formatting": {
		"general_number_precision": [3, number_precision_changed],
		"general_angle_precision": [1, number_precision_changed],
		"xml_add_trailing_newline": [false, Signal()],
		"xml_shorthand_tags": [true, Signal()],
		"xml_pretty_formatting": [false, Signal()],
		"number_enable_autoformatting": [false, Signal()],
		"number_remove_zero_padding": [false, Signal()],
		"number_remove_leading_zero": [true, Signal()],
		"number_remove_plus_sign": [false, Signal()],
		"color_enable_autoformatting": [false, Signal()],
		"color_convert_rgb_to_hex": [false, Signal()],
		"color_convert_named_to_hex": [true, Signal()],
		"color_use_shorthand_hex_code": [true, Signal()],
		"color_use_short_named_colors": [false, Signal()],
		"pathdata_enable_autoformatting": [true, Signal()],
		"pathdata_compress_numbers": [true, Signal()],
		"pathdata_minimize_spacing": [true, Signal()],
		"pathdata_remove_spacing_after_flags": [false, Signal()],
		"pathdata_remove_consecutive_commands": [true, Signal()],
		"transform_list_enable_autoformatting": [true, Signal()],
		"transform_list_compress_numbers": [true, Signal()],
		"transform_list_minimize_spacing": [true, Signal()],
		"transform_list_remove_unnecessary_params": [true, Signal()],
	},
	"theming": {
		"highlighting_symbol_color": [Color("abc9ff"), highlight_colors_changed],
		"highlighting_element_color": [Color("ff8ccc"), highlight_colors_changed],
		"highlighting_attribute_color": [Color("bce0ff"), highlight_colors_changed],
		"highlighting_string_color": [Color("a1ffe0"), highlight_colors_changed],
		"highlighting_comment_color": [Color("cdcfd280"), highlight_colors_changed],
		"highlighting_text_color": [Color("cdcfeaac"), highlight_colors_changed],
		"highlighting_cdata_color": [Color("ffeda1ac"), highlight_colors_changed],
		"highlighting_error_color": [Color("ff866b"), highlight_colors_changed],
		"handle_inside_color": [Color("fff"), handle_visuals_changed],
		"handle_color": [Color("#111"), handle_visuals_changed],
		"handle_hovered_color": [Color("#aaa"), handle_visuals_changed],
		"handle_selected_color": [Color("#46f"), handle_visuals_changed],
		"handle_hovered_selected_color": [Color("#f44"), handle_visuals_changed],
		"background_color": [Color("1f2233"), Signal()],
		"basic_color_valid": [Color("9f9"), basic_colors_changed],
		"basic_color_error": [Color("f99"), basic_colors_changed],
		"basic_color_warning": [Color("ee5"), basic_colors_changed],
	},
	"other": {
		"invert_zoom": [false, Signal()],
		"wrap_mouse": [false, Signal()],
		"use_ctrl_for_zoom": [true, Signal()],
		"use_native_file_dialog": [true, Signal()],
		"use_filename_for_window_title": [true, window_title_scheme_changed],
		"handle_size": [1.0, handle_visuals_changed],
		"ui_scale": [1.0, ui_scale_changed],
		"auto_ui_scale": [true, ui_scale_changed],
	},
}

# No way to fetch defaults otherwise.
var default_input_events := {}  # Dictionary{String: Array[InputEvent]}

# Stores whether the keybinds should be modifiable.
const keybinds_dict = {
	"file": {
		"import": true,
		"export": true,
		"save": true,
		"optimize": true,
		"copy_svg_text": true,
		"clear_svg": true,
		"clear_file_path": true,
		"reset_svg": true,
	},
	"edit": {
		"undo": true,
		"redo": true,
		"select_all": true,
		"duplicate": true,
		"move_up": true,
		"move_down": true,
		"delete": true,
		"find": true,
	},
	"view": {
		"zoom_in": true,
		"zoom_out": true,
		"zoom_reset": true,
		"debug": false,
		"view_show_grid": true,
		"view_show_handles": true,
		"view_rasterized_svg": true,
		"load_reference": true,
		"view_show_reference": true,
		"view_overlay_reference": true,
	},
	"tool": {
		"move_relative": false,
		"move_absolute": false,
		"line_relative": false,
		"line_absolute": false,
		"horizontal_line_relative": false,
		"horizontal_line_absolute": false,
		"vertical_line_relative": false,
		"vertical_line_absolute": false,
		"close_path_relative": false,
		"close_path_absolute": false,
		"elliptical_arc_relative": false,
		"elliptical_arc_absolute": false,
		"quadratic_bezier_relative": false,
		"quadratic_bezier_absolute": false,
		"shorthand_quadratic_bezier_relative": false,
		"shorthand_quadratic_bezier_absolute": false,
		"cubic_bezier_relative": false,
		"cubic_bezier_absolute": false,
		"shorthand_cubic_bezier_relative": false,
		"shorthand_cubic_bezier_absolute": false,
	},
	"help": {
		"quit": false,
		"open_settings": true,
		"about_info": true,
		"about_donate": true,
		"about_repo": true,
		"about_website": true,
		"check_updates": true,
	}
}


var language: String:
	set(new_value):
		if language != new_value:
			language = new_value
			TranslationServer.set_locale(new_value)
			save_setting("localization", "language")
			language_changed.emit()

var palettes: Array[ColorPalette] = []


# Formatting
var general_number_precision := 3
var general_angle_precision := 1
var xml_add_trailing_newline := false
var xml_shorthand_tags := true
var xml_pretty_formatting := false
var number_enable_autoformatting := false
var number_remove_zero_padding := true
var number_remove_leading_zero := false
var color_enable_autoformatting := false
var color_convert_rgb_to_hex := false
var color_convert_named_to_hex := true
var color_use_shorthand_hex_code := true
var color_use_short_named_colors := false
var pathdata_enable_autoformatting := true
var pathdata_compress_numbers := true
var pathdata_minimize_spacing := true
var pathdata_remove_spacing_after_flags := false
var pathdata_remove_consecutive_commands := true
var transform_list_enable_autoformatting := true
var transform_list_compress_numbers := true
var transform_list_minimize_spacing := true
var transform_list_remove_unnecessary_params := true

# Theming
var highlighting_symbol_color := Color("abc9ff")
var highlighting_element_color := Color("ff8ccc")
var highlighting_attribute_color := Color("bce0ff")
var highlighting_string_color := Color("a1ffe0")
var highlighting_comment_color := Color("cdcfd280")
var highlighting_text_color := Color("cdcfeaac")
var highlighting_cdata_color := Color("ffeda1ac")
var highlighting_error_color := Color("ff866b")
var handle_inside_color := Color("fff")
var handle_color := Color("#111")
var handle_hovered_color := Color("#aaa")
var handle_selected_color := Color("#46f")
var handle_hovered_selected_color := Color("#f44")
var background_color := Color(0.12, 0.132, 0.2, 1):
	set(new_value):
		background_color = new_value
		RenderingServer.set_default_clear_color(background_color)
var basic_color_valid := Color("9f9")
var basic_color_error := Color("f99")
var basic_color_warning := Color("ee5")

# Other
var invert_zoom := false
var wrap_mouse := false
var use_ctrl_for_zoom := true
var use_native_file_dialog := true
var use_filename_for_window_title := true
var handle_size := 1.0
var ui_scale := 1.0
var auto_ui_scale := true


func reset_setting(section: String, setting: String) -> void:
	modify_setting(section, setting, get_default(section, setting))

func modify_setting(section: String, setting: String, new_value: Variant) -> void:
	if get(setting) != new_value:
		set(setting, new_value)
		save_setting(section, setting)
		var related_signal := get_signal(section, setting)
		if not related_signal.is_null():
			related_signal.emit()


func modify_keybind(action: String, new_events: Array[InputEvent]) -> void:
	InputMap.action_erase_events(action)
	for event in new_events:
		InputMap.action_add_event(action, event)
	save_keybind(action)
	shortcuts_changed.emit()

func reset_keybinds() -> void:
	InputMap.load_from_project_settings()
	for category in keybinds_dict:
		var category_dict: Dictionary = keybinds_dict[category]
		for action in category_dict:
			# Only reset the configurable ones.
			if category_dict[action]:
				save_keybind(action)
	shortcuts_changed.emit()


func save_setting(section: String, setting: String) -> void:
	config.set_value(section, setting, get(setting))
	config.save(config_path)

func save_palettes() -> void:
	config.set_value("palettes", "palettes", palettes)
	config.save(config_path)

func save_keybind(action: String) -> void:
	config.set_value("keybinds", action, InputMap.action_get_events(action))
	config.save(config_path)


func modify_save_data(property: String, new_value: Variant) -> void:
	save_data.set(property, new_value)
	ResourceSaver.save(save_data, save_path)

func load_user_data() -> void:
	if FileAccess.file_exists(save_path):
		save_data = ResourceLoader.load(save_path)

func _exit_tree() -> void:
	ResourceSaver.save(save_data, save_path)

func _enter_tree() -> void:
	for action in InputMap.get_actions():
		default_input_events[action] = InputMap.action_get_events(action)
	load_settings()
	load_user_data()
	ThemeGenerator.generate_theme()


func load_settings() -> void:
	var error := config.load(config_path)
	if error:
		# File wasn't found or maybe something broke, setup defaults again.
		reset_settings()
		reset_palettes()
		reset_keybinds()
		language = "en"
	else:
		for section in config.get_sections():
			if section == "keybinds":
				for category in keybinds_dict:
					var category_dict: Dictionary = keybinds_dict[category]
					for action in category_dict:
						# Only save ones that are configurable.
						if category_dict[action]:
							if config.has_section_key("keybinds", action):
								modify_keybind(action, config.get_value("keybinds", action))
							else:
								save_keybind(action)
			else:
				for setting in config.get_section_keys(section):
					set(setting, config.get_value(section, setting))
					save_setting(section, setting)

func reset_settings() -> void:
	for section in defaults.keys():
		for setting in defaults[section].keys():
			set(setting, get_default(section, setting))
			save_setting(section, setting)

func reset_palettes() -> void:
	palettes = [ColorPalette.new("Pure",
			PackedStringArray(["#fff", "#000", "#f00", "#0f0", "#00f", "#ff0", "#f0f", "#0ff"]),
			PackedStringArray(["White", "Black", "Red", "Green", "Blue", "Yellow", "Magenta", "Cyan"]))]
	save_palettes()

# Just some helpers.
func get_validity_color(error_condition: bool, warning_condition := false) -> Color:
	return basic_color_error if error_condition else\
			basic_color_warning if warning_condition else basic_color_valid

func get_quanta() -> float:
	return 0.1 ** general_number_precision
