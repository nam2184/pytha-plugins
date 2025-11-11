---@param data DoorPatternData
function cut_circles_panel(data)
	if data.main_group ~= nil then
		pytha.delete_element(pytha.get_group_members(data.main_group))
	end

	data.cur_elements = {}
	local panel_width = data.width / data.x_panels
	local panel_height = data.height / data.y_panels
	local loc_origin = { data.origin[1], data.origin[2], data.origin[3] }

	local x_diameter = data.diameter
	local y_diameter = data.diameter
	local x_spacing = data.x_spacing
	local y_spacing = data.y_spacing
	local x_hole_dist = x_diameter + x_spacing
	local y_hole_dist = y_diameter + y_spacing
	local circ_seg = { angle = -180, segments = -24 }

	local x_off, y_off = 0, 0
	if data.centered then
		local max_width = math.floor((data.width - 2 * data.margin - x_diameter) / x_hole_dist) * x_hole_dist
			+ x_diameter
		local max_height = math.floor((data.height - 2 * data.margin - y_diameter) / y_hole_dist) * y_hole_dist
			+ y_diameter
		x_off = (data.width - 2 * data.margin - max_width) / 2
		y_off = (data.height - 2 * data.margin - max_height) / 2
	end

	for i = 1, data.x_sections do
		for g = 1, data.y_sections do
			-- Outer panel as the first loop
			local outer_frame = {
				loc_origin,
				{ loc_origin[1] + panel_width, loc_origin[2], loc_origin[3] },
				{ loc_origin[1] + panel_width, loc_origin[2], loc_origin[3] + panel_height },
				{ loc_origin[1], loc_origin[2], loc_origin[3] + panel_height },
			}

			local loops = {}
			table.insert(loops, { outer_frame, { {}, {}, {}, {} } })

			-- Circle holes
			for j = data.origin[1] + x_off + data.margin + x_diameter / 2, data.origin[1] + data.width - data.margin - x_diameter / 2, x_hole_dist do
				local k_count = 0
				for k = data.origin[3] + y_off + data.margin + y_diameter / 2, data.origin[3] + data.height - data.margin - y_diameter / 2, y_hole_dist do
					local j_offset = j + 0.5 * (k_count % 2) * x_hole_dist
					if
						j_offset >= outer_frame[1][1] - x_diameter / 2
						and j_offset <= outer_frame[3][1] + x_diameter / 2
					then
						if k >= outer_frame[1][3] - y_diameter / 2 and k <= outer_frame[3][3] + y_diameter / 2 then
							local circle_points = {
								{ j_offset, data.origin[2], k - y_diameter / 2 },
								{ j_offset, data.origin[2], k + y_diameter / 2 },
							}
							table.insert(loops, { circle_points, { circ_seg, circ_seg } })
						end
						k_count = k_count + 1
					end
				end
			end

			local panel_face = pytha.create_polygon_ex(loops, { 0, 0, 0 })

			if data.thickness > 0 then
				local extruded = pytha.create_profile(panel_face, -data.thickness)
				for _, part in pairs(extruded) do
					pytha.set_element_name(part, "Panel")
					table.insert(data.cur_elements, part)
				end
				pytha.delete_element(panel_face)
			else
				pytha.set_element_name(panel_face, "Panel")
				table.insert(data.cur_elements, panel_face)
			end

			loc_origin[3] = loc_origin[3] + panel_height
		end
		loc_origin[3] = data.origin[3]
		loc_origin[1] = loc_origin[1] + panel_width
	end

	data.main_group = pytha.create_group(data.cur_elements)
	pytha.set_element_name(data.main_group, data.name)
	pytha.set_element_history(data.main_group, data, "pegboard_circle_history")
end
