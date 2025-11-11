pattern = {
	diagonal_lines = 1,
	horizontal_lines = 2,
	circles = 3,
	chaffered_rect = 4,
}

---@class DoorPatternData
---@field name string Name of the door or pattern element
---@field origin number[] Base origin {x, y, z} of the door
---@field width number Total door width
---@field length number Total door width
---@field gap number
---@field width number Total door width
---@field height number Total door height
---@field thickness number Door or panel thickness
---@field x_sections integer Number of pattern sections horizontally
---@field y_sections integer Number of pattern sections vertically
---@field x_spacing number Horizontal spacing between features (e.g., holes, grooves, panels)
---@field y_spacing number Vertical spacing between features
---@field feature_size number Base feature diameter or size (can represent holes, grooves, or motifs)
---@field margin number Margin from door frame to start of pattern
---@field diameter number If genereting layered circles
---@field centered boolean Whether to center the pattern inside margins
---@field shape_pattern integer Pattern mode (1 = circle, 2 = rectangle)
---@field frame_thickness number Optional: frame width or depth for outlining door panels
---@field material string|nil Optional: material or color name for door visualization
---@field main_group element_handle|nil Main grouped element for the whole door
---@field cur_elements element_handle[]|nil List of current geometry elements generated

---@param data DoorPatternData
function generate_outer_frame(data)
	local cross = { type = "rectangle", length = data.thickness, width = data.thickness / 2 }
	local curr_elements = {}

	local origin = data.origin
	-- 4 edges of the frame
	local edges = {
		{ { origin[1], origin[2], origin[3] }, { origin[1], origin[2], origin[3] + data.height } }, -- left vertical
		{
			{ origin[1] + data.length, origin[2], origin[3] },
			{ origin[1] + data.length, origin[2], origin[3] + data.height },
		}, -- right vertical
		{
			{ origin[1], origin[2], origin[3] + data.height },
			{ origin[1] + data.length, origin[2], origin[3] + data.height },
		}, -- top horizontal
		{ { origin[1], origin[2], origin[3] }, { origin[1] + data.length, origin[2], origin[3] } }, -- bottom horizontal
	}

	-- sweep each edge
	for _, edge in ipairs(edges) do
		local path = pytha.create_polyline("closed", edge)
		local sweep = pytha.create_sweep(path, cross, { keep_vertical = 0 })
		table.insert(curr_elements, sweep[1])
		pytha.delete_element(path)
	end

	-- join all edges into one solid frame
	local frame = pytha.boole_part_union(curr_elements)
	pytha.set_element_name(frame, "Door_Frame")

	return frame
end

---@param data DoorPatternData
function door_face(data)
	-- Delete previous geometry
	if data.main_group ~= nil then
		pytha.delete_element(pytha.get_group_members(data.main_group))
	end
	data.cur_elements = {}

	-- Calculate panel height with optional gap
	local total_gap = data.gap * (data.x_sections - 1)
	local height_sections = (data.height - total_gap) / data.x_sections
	local z_start = data.origin[3]

	for i = 1, data.x_sections do
		-- Define rectangle points for this panel
		local seg_plane_points = {
			{ data.origin[1], data.origin[2], z_start },
			{ data.origin[1] + data.length, data.origin[2], z_start },
			{ data.origin[1] + data.length, data.origin[2], z_start + height_sections },
			{ data.origin[1], data.origin[2], z_start + height_sections },
		}

		-- Create the plane; each point needs a segment placeholder
		local seg_plane = pytha.create_polygon(seg_plane_points)

		pytha.set_element_name(seg_plane, "Panel " .. i)
		table.insert(data.cur_elements, seg_plane)

		-- Move z_start up for next panel + gap
		z_start = z_start + height_sections + data.gap
	end

	local door = pytha.create_block(data.length, data.width, data.height, data.origin)
	table.insert(data.cur_elements, door)
	-- Group everything
	data.main_group = pytha.create_group(data.cur_elements)
	pytha.set_element_name(data.main_group, data.name)
	pytha.set_element_history(data.main_group, data, "door_face_history")
end

---@class DoorKnobData
---@field name string Name of the knob element
---@field origin table Base origin {x, y, z} of the knob (center point)insert
---@field type string "sphere, idk what the other type is called"
---@field base_radius number Radius of the base
---@field base_height number Height or the base
---@field spindle_radius number Radius of the spindle
---@field spindle_height number Height of the spindle
---@field knob_radius number Radius of the knob sphere
---@field handle_length number Optional: length of handle or lever
---@field handle_angle number Optional: angle of handle in degrees
---@field orientation number[] Optional: local axes {u, v, w} for rotation/orientation
---@field material string|nil Optional: material or color of the knob
---@field main_element element_handle|nil Handle to the main knob element
---@field cur_elements element_handle[]|nil List of current geometry elements (sphere, lever, base plate)
---@field main_group string

---@param data DoorKnobData
function door_knob(data)
	-- Clear previous geometry
	if data.main_group ~= nil then
		pytha.delete_element(pytha.get_group_members(data.main_group))
		data.main_element = nil
	end
	data.cur_elements = {}

	local base_center = { data.origin[1], data.origin[2], data.origin[3] }
	local base = pytha.create_cylinder(
		data.base_height,
		data.base_radius,
		base_center,
		{ w_axis = { 0, 0, 1 }, u_axis = { 0, 0, -1 } }
	)
	table.insert(data.cur_elements, base)

	local spindle_center = { data.origin[1], data.origin[2], data.origin[3] }
	local spindle = pytha.create_cylinder(
		data.spindle_height,
		data.spindle_radius,
		spindle_center,
		{ w_axis = { 0, 0, 1 }, u_axis = { 0, 0, -1 } }
	)
	table.insert(data.cur_elements, spindle)

	local knob_center =
		{ data.origin[1], spindle_center[2] - data.spindle_height * 2 + data.knob_radius, data.origin[3] }
	local knob = pytha.create_sphere(data.knob_radius, knob_center, { segments = 32, latitude_segments = 16 })
	table.insert(data.cur_elements, knob)

	-- Create main group
	data.main_group = pytha.create_group(data.cur_elements)
	data.main_element = pytha.boole_part_union(data.cur_elements)
	pytha.set_element_name(data.main_group, data.name)
	pytha.set_element_history(data.main_group, data, "door_knob_history")
end

---@param data DoorPatternData
function layered_circles(data)
	if data.main_group ~= nil then
		pyui.alert("deleting old elements")
		pytha.delete_element(pytha.get_group_members(data.main_group))
	end

	data.cur_elements = {}
	local x_diameter = data.diameter
	local y_diameter = data.diameter
	local x_spacing = data.x_spacing
	local y_spacing = data.y_spacing

	local x_hole_dist = x_diameter + x_spacing
	local y_hole_dist = y_diameter + y_spacing
	local x_off = 0
	local y_off = 0

	local center_margin_x = data.margin + x_diameter / 2
	local center_margin_y = data.margin + y_diameter / 2

	-- Center pattern if requested
	if data.centered then
		local max_width = math.floor((data.width - 2 * data.margin - x_diameter) / x_hole_dist) * x_hole_dist
			+ x_diameter
		local max_height = math.floor((data.height - 2 * data.margin - y_diameter) / y_hole_dist) * y_hole_dist
			+ y_diameter
		x_off = (data.width - 2 * data.margin - max_width) / 2
		y_off = (data.height - 2 * data.margin - max_height) / 2
	end

	for j = data.origin[1] + x_off + center_margin_x, data.origin[1] + data.width - center_margin_x, x_hole_dist do
		local k_count = 0
		for k = data.origin[3] + y_off + center_margin_y, data.origin[3] + data.height - center_margin_y, y_hole_dist do
			local j_offset = j + 0.5 * (k_count % 2) * x_hole_dist

			-- Center of circle
			local center = { j_offset, data.origin[2], k }
			local radius = data.diameter / 2

			-- Create the circular face
			local circle = pytha.create_circle(radius, center, {
				w_axis = { 0, 1, 0 },
				segments = 48,
			})
			pytha.set_element_name(circle, "Circle Face")

			-- Extrude it upward as a raised circle layer
			local raised = pytha.create_profile(circle, data.thickness)
			for _, part in pairs(raised) do
				pytha.set_element_name(part, "Raised Circle")
				table.insert(data.cur_elements, part)
			end

			pytha.delete_element(circle)
			k_count = k_count + 1
		end
	end

	data.main_group = pytha.create_group(data.cur_elements)
	pytha.set_element_name(data.main_group, data.name)
	pytha.set_element_history(data.main_group, data, "layered_circle_history")
end
