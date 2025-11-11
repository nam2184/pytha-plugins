function main()
	local length = 1000
	local width = 600
	local height_factor = -0.0010
	local grid_x = 10
	local grid_y = 8
	local cross_length = 5
	local cross_width = 10
	local curr_elements = {}

	-- paraboloid height function
	local function paraboloid(x, y)
		return height_factor * ((x - length / 2) ^ 2 + (y - width / 2) ^ 2)
	end

	local points = generate_grids(grid_x, grid_y, length, width, paraboloid)

	create_mesh_faces(points, curr_elements, grid_x, grid_y, cross_length, cross_width)

	-- Union all sweep solids into a single element
	local parabol = pytha.boole_part_union(curr_elements)
	pytha.set_element_name(parabol, "Paraboloid_Solid")
end
