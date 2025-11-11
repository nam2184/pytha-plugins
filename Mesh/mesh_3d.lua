---@param grid_x number
---@param grid_y number
---@param length number
---@param width number
---@param z_function fun(x:number, y:number):number
---@return table<number, table<number, table<number>>> points
function generate_grids(grid_x, grid_y, length, width, z_function)
	local points = {}
	local dx = length / (grid_x - 1)
	local dy = width / (grid_y - 1)

	for i = 1, grid_x do
		points[i] = {}
		for j = 1, grid_y do
			local x = (i - 1) * dx
			local y = (j - 1) * dy
			points[i][j] = { x, y, z_function(x, y) }
		end
	end

	return points
end

---@param points table<number, table<number, table<number>>> Grid of points {x,y,z}
---@param direction table<number> Translation vector {dx, dy, dz}
---@param grid_x number Number of points along X
---@param grid_y number Number of points along Y
---@return table<number, table<number, table<number>>> New grid of translated points
function translate_points(points, direction, grid_x, grid_y)
	local dx, dy, dz = direction[1], direction[2], direction[3]
	local new_points = {}

	for i = 1, grid_x do
		new_points[i] = {}
		for j = 1, grid_y do
			local temp = points[i][j]
			local x, y, z = temp[1], temp[2], temp[3]
			new_points[i][j] = { x + dx, y + dy, z + dz }
		end
	end

	return new_points
end

---@param points table<number, table<number, table<number>>> Grid of points {x,y,z}
---@param curr_elements element_handles[]
---@param grid_x number
---@param grid_y number
---@param cross_length number Length of rectangle cross-section
---@param cross_width number Width of rectangle cross-section
function create_mesh_faces(points, curr_elements, grid_x, grid_y, cross_length, cross_width)
	-- Sweep along rows (X-direction)
	for j = 1, grid_y do
		local row_points = {}
		for i = 1, grid_x do
			table.insert(row_points, points[i][j])
		end

		if #row_points >= 2 then
			local path = pytha.create_polyline("open", row_points)
			local cross = { type = "rectangle", length = cross_length, width = cross_width }
			local sweep = pytha.create_sweep(path, cross, { keep_vertical = 1 })
			table.insert(curr_elements, sweep[1])
		end
	end

	-- Sweep along columns (Y-direction)
	for i = 1, grid_x do
		local col_points = {}
		for j = 1, grid_y do
			table.insert(col_points, points[i][j])
		end

		if #col_points >= 2 then
			local path = pytha.create_polyline("open", col_points)
			local cross = { type = "rectangle", length = cross_length, width = cross_width }
			local sweep = pytha.create_sweep(path, cross, { keep_vertical = 1 })
			table.insert(curr_elements, sweep[1])
		end
	end
end
