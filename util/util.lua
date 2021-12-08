
local util = {}

util.pi = math.pi
util.twopi = util.pi * 2
util.rad_to_deg = 180 / util.pi
util.deg_to_rad = util.pi / 180
util.hash_blank = hash("")
util.empty_string = ""
util.zero_scale = vmath.vector3(0.0000001,0.0000001,0.0000001)
util.one_scale = vmath.vector3(1,1,1)
util.string_table = "table"
util.string_number = "number"
util.large_number = math.huge

local getiter = function(x)
    if util.isarray(x) then
        return ipairs
    elseif type(x) == "table" then
        return pairs
    end
    error("expected table", 3)
end

---Set up random number generator and clear bad rolls. Returns seed value used.
function util.randomseed(seed)
    seed = seed or (100000000000000 * (socket.gettime() % 1))
    math.randomseed(seed)
    for i=1,20 do
        math.random()
    end

    return seed
end

---Get the angle (degree) between two points
function util.angle_deg(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1) * util.rad_to_deg
end

---Get the angle (radians) between two points
function util.angle_rad(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

---Get the rotation needed to rotate an object towards a point using go.animate euler.z. Default object direction (0 deg) is to the right.
function util.get_rotation_for_animation(direction)

    return util.angle_deg(0,0,direction.x,direction.y)
end

---Get the rotation needed to rotate an object towards a point using go.set_rotation(). Default object direction (0 deg) is to the right.
function util.get_rotation_for_go_set(direction)

    return vmath.quat_rotation_z(math.atan2(-direction.y, -direction.x))
end

---Returns a normalized direction, 0 rad = 1,0,0 (right)
function util.get_direction_from_angle(rad)

    local dir = vmath.vector3(1,0,0)
    local rot = vmath.quat_rotation_z(rad)
    return vmath.rotate(rot, dir)
end

function util.get_direction(from, to)
    return vmath.normalize(from - to)
end

---Returns a random direction (vec3)
function util.get_random_direction()

    return vmath.normalize(vmath.vector3(1 - 2 * math.random(), 1 - 2 * math.random(), 0))
end

---Returns true if a vector3 has values and is not nan
function util.valid_vector(vec)

    return vec and vec.x and vec.y and vec.z and vec.x == vec.x
end

function util.constant_speed_intercept(runner_position, runner_direction, runner_speed, chaser_position, chaser_speed, dt, max_time)

    dt = dt or (1/60)
    max_time = max_time or 10
    local dist = vmath.length(runner_position - chaser_position)
    local chaser_movement = 0
    local new_runner_position = nil

    --calculate starting time, i.e. minimum time if they were going head-on
    local t = dist / (chaser_speed +  runner_speed)

    while t < max_time do

        t = t + dt
        new_runner_position = runner_position + runner_direction * runner_speed * t
        chaser_movement = chaser_speed * t
        dist = vmath.length(new_runner_position - chaser_position)
        
        if dist <= chaser_movement then
            return new_runner_position
        end

    end

    return runner_position
end

---Returns table:
---
---{position, dir, rad, rad_increment}
function util.get_position_in_circle(place_in_line, num_total, radius, mid_point, apply_symmetry)

    --adjust the starting rotation for symmetry
    local base_rotation = 0
    if apply_symmetry then
        if num_total%2 == 0 then
            if num_total%4 == 0 then
                base_rotation = -0.25 * util.pi
            else
                base_rotation = -1 * util.pi
            end
        else
            base_rotation = 0.5 * util.pi
        end
    end

    local rad_increment = util.twopi / num_total
    local dir = vmath.vector3(1,0,0)
    local rad = base_rotation + (place_in_line-1) * rad_increment
    local rot = vmath.quat_rotation_z(rad)
    dir = vmath.rotate(rot, dir)

    return {position = mid_point + dir * radius, dir = dir, rad = rad, rad_increment = rad_increment}
end

---Draws line using render.draw, color is optional and defaults to 25% alpha white line
function util.draw_line(from, to, color)
    if not from or not to then
        return
    end
    color = color or vmath.vector4(1,1,1,0.25)
	msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = color })
end

function util.clamp(var,min,max)

    if var < min then
        var = min
    end

    if var > max then
        var = max
    end

    return var
end

function util.is_between(amount,min,max,equal_to_okay)

    if amount == nil or min == nil or max == nil then
        print("error: is_between function given nil value",amount,min,max)
        return false
    end

    if equal_to_okay then
        return amount >= min and amount <= max
    else
        return amount > min and amount < max
    end
end

function util.length(target_arr)
	if target_arr ~= nil then
		return #target_arr
	else
		return 0
	end
end

function util.splice(t,i,len)
    -- t = table
    -- i = location in table
    -- len = number of elements to remove
	len = len or 1
    if (len > 0) then
        for r=0, len do
            if(r < len) then
                table.remove(t,i + r)
            end
        end
    end
    local count = 1
    local tempT = {}
    for i=1, #t do
        if t[i] then
            tempT[count] = t[i]
            count = count + 1
        end
    end
    t = tempT
end

function util.shallow_copy(t)
  local rtn = {}
  for k, v in pairs(t) do rtn[k] = v end
  return rtn
end

function util.deep_copy(t)
    if type(t) ~= util.string_table then return t end
    return sys.deserialize(sys.serialize(t))
end

function util.append(main, table_to_append)

    local num = #table_to_append
    for i=1,num do
        table.insert(main, table_to_append[i])
    end

    return main
end

function util.random_no_zero()
    return math.max(math.random(), 0.00000001)
end

function util.rand_between(min, max, int)
	if int then
		return util.round(math.random()*(max-min)+min)
	else
		return math.random()*(max-min)+min
	end
end

---Returns random number between 0-1. Power value (default 2) determines how hard it is to reach higher values. Power value 1 is identical to math.random()
function util.weighted_random(power)

	--[[
	"power" determines the weighting of the output. the output is just a number 0-1 (random) converted to an exponential function y = x^power

	default is 2, which makes lower values more likely, and higher values less likely
	increasing "power" beyond 2 makes higher values even harder to get

	when "power" is 1, the result is linear (and this function is pointless)
	]]

	--set default value
	power = power or 2

	return math.pow( math.random(), power)
end

function util.round(num, num_decimal_places)
	local mult = 10^(num_decimal_places or 0)
	return math.floor(num * mult + 0.5) / mult
end

---Returns 1 if x is 0 or above, returns -1 when x is negative.
function util.sign(x)
    return x < 0 and -1 or 1
end

---Switch sign (+/-) to opposite
function util.pingpong(x)
    return 1 - math.abs(1 - x % 2)
end

---Randomly switches the sign (+/-)
function util.plusorminus()
    return math.random() < 0.5 and -1 or 1
end

---Returns a copy of the table where the keys have become the values and the values the keys.
function util.invert(t)
    local rtn = {}
    for k, v in pairs(t) do rtn[v] = k end
    return rtn
end

---Returns a copy of the t array with all the duplicate values removed.
function util.unique(t)
    local rtn = {}
    for k in pairs(util.invert(t)) do
        rtn[#rtn + 1] = k
    end
    return rtn
end

---Returns the index/key of value in t. Returns nil if that value does not exist in the table.
function util.find(t, value)
    local iter = getiter(t)
    for k, v in iter(t) do
        if v == value then return k end
    end
    return nil
end

---Returns true if x is an array -- the value is assumed to be an array if it is a table which contains a value at the index 1. This function is used internally and can be overridden if you wish to use a different method to detect arrays.
function util.isarray(x)
    return type(x) == "table" and x[1] ~= nil
end

---Counts the number of values in the table t. If a fn function is supplied it is called on each value, the number of times it returns true is counted.
function util.count(t, fn)
    local count = 0
    local iter = getiter(t)
    if fn then
        fn = iteratee(fn)
        for _, v in iter(t) do
            if fn(v) then count = count + 1 end
        end
    else
        if util.isarray(t) then
            return #t
        end
        for _ in iter(t) do count = count + 1 end
    end
    return count
end

function util.count_keys(t)
    local count = 0
    for k,v in pairs(t) do count = count + 1 end
    return count
end

---Returns a copy of the array t with all its items sorted. If comp is a function it will be used to compare the items when sorting. If comp is a string it will be used as the key to sort the items by.
function util.sort(t, comp)
    local rtn = util.shallow_copy(t)
    if comp then
        if type(comp) == "string" then
            table.sort(rtn, function(a, b) return a[comp] < b[comp] end)
        else
            table.sort(rtn, comp)
        end
    else
        table.sort(rtn)
    end
    return rtn
end

---Returns a random value from a sequentially indexed table
function util.pick_random(t)

    return t[math.random(1, #t)]
end

---Returns a random index from a sequentially indexed table
function util.pick_random_i(t)

    return math.random(1,#t)
end

---Returns a table of unique random indices from a sequentially indexed table
function util.pick_random_i_multiple(t, num)

    local t_length = #t
    num = math.min(t_length, num)

    local index_table = {}
    for i=1,t_length do
        table.insert(index_table, i)
    end
    
    local result = {}
    local index = nil
    for i=1,num do
        index = math.random(1,t_length)
        table.insert(result, index_table[index])
        util.splice(index_table, index)
        t_length = t_length - 1
    end
    
    return result
end

---Returns a random key from a key-value indexed table
function util.pick_random_key(t)
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    return keys[math.random(1, #keys)]
end

function util.sort_associative_compare(a,b)
    return a[1] < b[1]
end

function util.sort_associative(t)

    --https://stackoverflow.com/questions/2038418/associatively-sorting-a-table-by-value-in-lua
    table.sort(t, util.sort_associative_compare)
    return t
end

function util.get_property(target_object, target_property, target_fragment)

    --[[
    define a property as follows:
        go.property("variable_name", 12)
    the property is then accessible using self.variable name
    ]]

    target_fragment = target_fragment or "script"

    local url = msg.url(target_object)
    url.fragment = target_fragment

    return go.get(url, target_property)
end

function util.go_exists(id)
    return pcall(function(id)go.get_position(id)end) == true
end

function util.gui_get_id(gui_url)

    return hash(hash_to_hex(gui_url.socket or util.hash_blank) .. hash_to_hex(gui_url.path) .. hash_to_hex(gui_url.fragment or util.hash_blank))
end

function util.do_lines_intersect( a, b, c, d )
    -- parameter conversion
    local L1 = {X1=a.x,Y1=a.y,X2=b.x,Y2=b.y}
    local L2 = {X1=c.x,Y1=c.y,X2=d.x,Y2=d.y}

    -- Denominator for ua and ub are the same, so store this calculation
    local d = (L2.Y2 - L2.Y1) * (L1.X2 - L1.X1) - (L2.X2 - L2.X1) * (L1.Y2 - L1.Y1)

    -- Make sure there is not a division by zero - this also indicates that the lines are parallel.
    -- If n_a and n_b were both equal to zero the lines would be on top of each
    -- other (coincidental).  This check is not done because it is not
    -- necessary for this implementation (the parallel check accounts for this).
    if (d == 0) then
        return false
    end

    -- n_a and n_b are calculated as seperate values for readability
    local n_a = (L2.X2 - L2.X1) * (L1.Y1 - L2.Y1) - (L2.Y2 - L2.Y1) * (L1.X1 - L2.X1)
    local n_b = (L1.X2 - L1.X1) * (L1.Y1 - L2.Y1) - (L1.Y2 - L1.Y1) * (L1.X1 - L2.X1)

    -- Calculate the intermediate fractional point that the lines potentially intersect.
    local ua = n_a / d
    local ub = n_b / d

    -- The fractional point will be between 0 and 1 inclusive if the lines
    -- intersect.  If the fractional calculation is larger than 1 or smaller
    -- than 0 the lines would need to be longer to intersect.
    if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
        local x = L1.X1 + (ua * (L1.X2 - L1.X1))
        local y = L1.Y1 + (ua * (L1.Y2 - L1.Y1))
        return {x=x, y=y}
    end

    return false
end

function util.is_in_front_of(start_pos, end_pos, direction)

    return vmath.dot(vmath.normalize(end_pos - start_pos), direction) >= 0
end

function util.is_in_range(range, v1, v2)

    return vmath.length(v1-v2) <= range
end

function util.is_in_rectangle(position, min_x, max_x, min_y, max_y)

    return position.x >= min_x and position.x <= max_x and position.y >= min_y and position.y <= max_y 
end

function util.line_intersects_rectangle(line_start, line_end, bottom_left, bottom_right, top_left, top_right)

	if util.do_lines_intersect(line_start, line_end, bottom_left, bottom_right) or util.do_lines_intersect(line_start, line_end, bottom_left, top_left) or util.do_lines_intersect(line_start, line_end, top_right, bottom_right) or util.do_lines_intersect(line_start, line_end, top_left, top_right) then
		return true
	else
		return false
	end
end

--Input a table of vectors to find the index of the vector closest to a given position
function util.find_closest(position, cut_off, values)

    --sqr
    cut_off = cut_off * cut_off

    local result = nil

    local closest_distance = math.huge
    local num = #values
    local dist = nil
    for i=1,num do
        dist  = vmath.length_sqr(position - values[i])
        if dist <= cut_off and dist < closest_distance then
            closest_distance = dist
            result = i
        end
    end

    return result
end

function util.print(...)
	print("PRINT: " .. debug.getinfo(2).short_src .. ":" .. debug.getinfo(2).currentline)
	print(...)
end

function util.pprint(...)
	print("PPRINT: " .. debug.getinfo(2).short_src .. ":" .. debug.getinfo(2).currentline)
	pprint(...)
end

function util.big_pprint(t)
    local type_table = "table"
    for key, value in pairs(t) do
        if type(value) == type_table then
            util.big_pprint(t)
        else
            print(key .. ": " .. value)
        end
    end
end

return util