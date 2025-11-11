function main()
	local data = {
		name = "TestDoorPlanes",
		origin = { 0, 0, 0 }, -- bottom-left-front corner of the door
		length = 1000, -- door legnth
		width = 30, -- door width
		height = 2000, -- door height
		thickness = 100,
		x_sections = 4, -- number of horizontal planes
		gap = 20, -- vertical gap between planes
		cur_elements = {},
		main_group = nil,
	}

	local knob_data = {
		name = "TestDoorKnob",
		origin = {
			data.origin[1] + 100, -- base_radius offset from left edge
			data.origin[2],
			data.origin[3] + (data.height / data.x_sections) * 2, -- front face
		},
		base_radius = 50,
		base_height = 10,
		spindle_radius = 10,
		spindle_height = 60,
		knob_radius = 40,
		cur_elements = {},
		main_group = nil,
	}

	recreate_geometry(data, knob_data)
end

---@param data DoorPatternData
---@param door_knob_data DoorKnobData
function recreate_geometry(data, door_knob_data)
	generate_outer_frame(data)
	door_face(data)
	door_knob(door_knob_data)
end
