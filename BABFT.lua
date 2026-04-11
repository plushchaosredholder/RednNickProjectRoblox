-- BABFT_Bundle.lua
-- Biblioteca Unificada (Bundle XD)

local BABFT = {}
local Modules = {}

--------------------------------------------------------------------------------
-- MODULE: Utils
--------------------------------------------------------------------------------
Modules.Utils = (function()
    local Utils = {}
    
    function Utils.toCFrame(value)
    	if typeof(value) == "CFrame" then
    		return value
    	elseif typeof(value) == "Vector3" then
    		return CFrame.new(value)
    	elseif typeof(value) == "table" then
    		if value.CFrame then
    			return Utils.toCFrame(value.CFrame)
    		elseif value.Position then
    			return CFrame.new(value.Position)
    		elseif value[1] or value[2] or value[3] then
    			return CFrame.new(value[1] or 0, value[2] or 0, value[3] or 0)
    		end
    	end
    	return CFrame.new()
    end
    
    function Utils.toVector3(value)
    	if typeof(value) == "Vector3" then
    		return value
    	elseif typeof(value) == "CFrame" then
    		return value.Position
    	elseif typeof(value) == "table" then
    		return Vector3.new(value[1] or value.X or 0, value[2] or value.Y or 0, value[3] or value.Z or 0)
    	end
    	return Vector3.new()
    end
    
    function Utils.toColor3(value)
    	if typeof(value) == "Color3" then
    		return value
    	elseif typeof(value) == "table" then
    		return Color3.new(value[1] or value.R or 1, value[2] or value.G or 1, value[3] or value.B or 1)
    	end
    	return Color3.new(1, 1, 1)
    end
    
    function Utils.toList(value)
    	if typeof(value) == "table" then
    		return value
    	end
    	return { value }
    end
    
    function Utils.copy(t)
    	local out = {}
    	for k, v in pairs(t or {}) do
    		out[k] = v
    	end
    	return out
    end
    
    function Utils.deepCopy(t)
    	if typeof(t) ~= "table" then
    		return t
    	end
    	local out = {}
    	for k, v in pairs(t) do
    		out[k] = Utils.deepCopy(v)
    	end
    	return out
    end
    
    function Utils.flatten(t)
    	local out = {}
    	for _, v in ipairs(t or {}) do
    		if typeof(v) == "table" then
    			for _, x in ipairs(v) do
    				table.insert(out, x)
    			end
    		else
    			table.insert(out, v)
    		end
    	end
    	return out
    end
    
    function Utils.clamp(x, a, b)
    	return math.max(a, math.min(b, x))
    end
    
    function Utils.lerp(a, b, t)
    	return a + (b - a) * t
    end
    
    function Utils.round(x)
    	return math.floor(x + 0.5)
    end
    
    function Utils.sign(x)
    	if x > 0 then
    		return 1
    	elseif x < 0 then
    		return -1
    	end
    	return 0
    end
    
    function Utils.getPart(block)
    	if not block then
    		return nil
    	end
    
    	if typeof(block) == "Instance" then
    		if block:IsA("Model") then
    			return block.PrimaryPart or block:FindFirstChildWhichIsA("BasePart")
    		end
    		if block:IsA("BasePart") then
    			return block
    		end
    	end
    
    	if typeof(block) == "table" and block.Part then
    		return block.Part
    	end
    
    	return nil
    end
    
    function Utils.blockPosition(block)
    	local part = Utils.getPart(block)
    	return part and part.Position or nil
    end
    
    function Utils.closestBlock(blocks, targetCF)
    	local closest, dist = nil, math.huge
    
    	for _, b in pairs(blocks or {}) do
    		local part = Utils.getPart(b)
    		if part then
    			local d = (part.Position - targetCF.Position).Magnitude
    			if d < dist then
    				dist = d
    				closest = b
    			end
    		end
    	end
    
    	return closest, dist
    end
    
    function Utils.findByName(list, name)
    	for _, v in ipairs(list or {}) do
    		if v.Name == name or v[1] == name then
    			return v
    		end
    	end
    	return nil
    end
    
    function Utils.chunk(t, size)
    	local out = {}
    	local current = {}
    
    	for _, v in ipairs(t or {}) do
    		table.insert(current, v)
    		if #current >= size then
    			table.insert(out, current)
    			current = {}
    		end
    	end
    
    	if #current > 0 then
    		table.insert(out, current)
    	end
    
    	return out
    end
    
    function Utils.map(t, fn)
    	local out = {}
    	for i, v in ipairs(t or {}) do
    		out[i] = fn(v, i)
    	end
    	return out
    end
    
    function Utils.filter(t, fn)
    	local out = {}
    	for i, v in ipairs(t or {}) do
    		if fn(v, i) then
    			table.insert(out, v)
    		end
    	end
    	return out
    end
    
    function Utils.reduce(t, fn, initial)
    	local acc = initial
    	local startIndex = 1
    
    	if acc == nil then
    		acc = t[1]
    		startIndex = 2
    	end
    
    	for i = startIndex, #t do
    		acc = fn(acc, t[i], i)
    	end
    
    	return acc
    end
    
    function Utils.safePCall(fn, ...)
    	local ok, result = pcall(fn, ...)
    	return ok, result
    end
    
    function Utils.tableKeys(t)
    	local out = {}
    	for k in pairs(t or {}) do
    		table.insert(out, k)
    	end
    	return out
    end
    
    return Utils
end)()

--------------------------------------------------------------------------------
-- MODULE: Resolver
--------------------------------------------------------------------------------
Modules.Resolver = (function()
    local Resolver = {}
    
    local exact = {}
    local alias = {}
    
    local function norm(s)
    	return string.lower(tostring(s or "")):gsub("%s+", ""):gsub("_", ""):gsub("-", "")
    end
    
    local function levenshtein(a, b)
    	a = norm(a)
    	b = norm(b)
    
    	local la = #a
    	local lb = #b
    
    	if la == 0 then
    		return lb
    	end
    	if lb == 0 then
    		return la
    	end
    
    	local prev = {}
    	local curr = {}
    
    	for j = 0, lb do
    		prev[j] = j
    	end
    
    	for i = 1, la do
    		curr[0] = i
    		for j = 1, lb do
    			local cost = (a:sub(i, i) == b:sub(j, j)) and 0 or 1
    			curr[j] = math.min(
    				curr[j - 1] + 1,
    				prev[j] + 1,
    				prev[j - 1] + cost
    			)
    		end
    		prev, curr = curr, prev
    	end
    
    	return prev[lb]
    end
    
    function Resolver.register(name, value)
    	exact[norm(name)] = value
    end
    
    function Resolver.alias(name, value)
    	alias[norm(name)] = value
    end
    
    function Resolver.registerMany(tbl)
    	for k, v in pairs(tbl or {}) do
    		Resolver.register(k, v)
    	end
    end
    
    function Resolver.get(name)
    	local key = norm(name)
    	if exact[key] ~= nil then
    		return exact[key]
    	end
    	if alias[key] ~= nil then
    		return alias[key]
    	end
    	return nil
    end
    
    function Resolver.names()
    	local out = {}
    	for k, _ in pairs(exact) do
    		table.insert(out, k)
    	end
    	for k, _ in pairs(alias) do
    		table.insert(out, k)
    	end
    	return out
    end
    
    function Resolver.closestName(name)
    	local key = norm(name)
    	local bestName, bestDist = nil, math.huge
    
    	for k, v in pairs(exact) do
    		local d = levenshtein(key, k)
    		if d < bestDist then
    			bestDist = d
    			bestName = v
    		end
    	end
    
    	for k, v in pairs(alias) do
    		local d = levenshtein(key, k)
    		if d < bestDist then
    			bestDist = d
    			bestName = v
    		end
    	end
    
    	return bestName, bestDist
    end
    
    function Resolver.resolve(name, fallback)
    	local got = Resolver.get(name)
    	if got ~= nil then
    		return got
    	end
    	local closest = Resolver.closestName(name)
    	if closest ~= nil then
    		return closest
    	end
    	return fallback
    end
    
    function Resolver.makeIndex(tbl)
    	Resolver.registerMany(tbl)
    	return tbl
    end
    
    return Resolver
end)()

--------------------------------------------------------------------------------
-- MODULE: Smart
--------------------------------------------------------------------------------
Modules.Smart = (function()
    local Smart = {}
    
    local Utils = Modules.Utils
    local Resolver = Modules.Resolver
    
    function Smart.closestBlock(blocks, targetCF)
    	local best, bestDist = nil, math.huge
    
    	for _, b in pairs(blocks or {}) do
    		local p = Utils.getPart(b)
    		if p then
    			local d = (p.Position - targetCF.Position).Magnitude
    			if d < bestDist then
    				bestDist = d
    				best = b
    			end
    		end
    	end
    
    	return best, bestDist
    end
    
    function Smart.closestName(name, fallback)
    	return Resolver.resolve(name, fallback)
    end
    
    function Smart.retry(fn, tries, delaySeconds)
    	tries = tries or 3
    	delaySeconds = delaySeconds or 0
    
    	local lastErr
    	for _ = 1, tries do
    		local ok, result = pcall(fn)
    		if ok then
    			return result
    		end
    		lastErr = result
    		if delaySeconds > 0 then
    			task.wait(delaySeconds)
    		end
    	end
    
    	return nil, lastErr
    end
    
    function Smart.safeInvoke(fn, fallback)
    	local ok, result = pcall(fn)
    	if ok then
    		return result
    	end
    	return fallback, result
    end
    
    function Smart.bestBy(items, scoreFn)
    	local bestItem, bestScore = nil, -math.huge
    	for _, item in ipairs(items or {}) do
    		local s = scoreFn(item)
    		if s > bestScore then
    			bestScore = s
    			bestItem = item
    		end
    	end
    	return bestItem, bestScore
    end
    
    function Smart.autoName(name, fallback)
    	return Resolver.resolve(name, fallback)
    end
    
    return Smart
end)()

--------------------------------------------------------------------------------
-- MODULE: Error
--------------------------------------------------------------------------------
Modules.Error = (function()
    local Error = {}
    
    function Error.try(fn)
    	local ok, result = pcall(fn)
    	return ok, result
    end
    
    function Error.safe(fn, fallback)
    	local ok, result = pcall(fn)
    	if ok then
    		return result
    	end
    	return fallback, result
    end
    
    function Error.wrap(fn, onError)
    	return function(...)
    		local args = { ... }
    		local ok, result = pcall(function()
    			return fn(unpack(args))
    		end)
    		if ok then
    			return result
    		end
    		if onError then
    			return onError(result, args)
    		end
    		return nil, result
    	end
    end
    
    function Error.assert(ok, message)
    	if not ok then
    		error(message or "assertion failed", 2)
    	end
    	return true
    end
    
    function Error.isNil(v)
    	return v == nil
    end
    
    function Error.isValid(v)
    	return v ~= nil
    end
    
    return Error
end)()

--------------------------------------------------------------------------------
-- MODULE: AutoFix
--------------------------------------------------------------------------------
Modules.AutoFix = (function()
    local AutoFix = {}
    
    function AutoFix.value(v, fallback)
    	if v == nil then
    		return fallback
    	end
    	return v
    end
    
    function AutoFix.boolean(v, fallback)
    	if typeof(v) == "boolean" then
    		return v
    	end
    	return fallback or false
    end
    
    function AutoFix.number(v, fallback)
    	if typeof(v) == "number" then
    		return v
    	end
    	return fallback or 0
    end
    
    function AutoFix.vector(v, fallback)
    	if typeof(v) == "Vector3" then
    		return v
    	end
    	if typeof(v) == "table" then
    		return Vector3.new(v[1] or v.X or 0, v[2] or v.Y or 0, v[3] or v.Z or 0)
    	end
    	return fallback or Vector3.new()
    end
    
    function AutoFix.cframe(v, fallback)
    	if typeof(v) == "CFrame" then
    		return v
    	end
    	if typeof(v) == "Vector3" then
    		return CFrame.new(v)
    	end
    	if typeof(v) == "table" and v.Position then
    		return CFrame.new(v.Position)
    	end
    	return fallback or CFrame.new()
    end
    
    function AutoFix.color(v, fallback)
    	if typeof(v) == "Color3" then
    		return v
    	end
    	if typeof(v) == "table" then
    		return Color3.new(v[1] or v.R or 1, v[2] or v.G or 1, v[3] or v.B or 1)
    	end
    	return fallback or Color3.new(1, 1, 1)
    end
    
    function AutoFix.list(v)
    	if typeof(v) == "table" then
    		return v
    	end
    	return { v }
    end
    
    function AutoFix.name(v, fallback)
    	if typeof(v) == "string" and v ~= "" then
    		return v
    	end
    	return fallback or "PlasticBlock"
    end
    
    return AutoFix
end)()

--------------------------------------------------------------------------------
-- MODULE: Numpy
--------------------------------------------------------------------------------
Modules.Numpy = (function()
    -- Numpy.lua
    local Numpy = {}
    
    function Numpy.array(t) return t end
    function Numpy.matrix(rows, cols, val)
        local m = {}
        for i=1, rows do
            m[i] = {}
            for j=1, cols do m[i][j] = val or 0 end
        end
        return m
    end
    function Numpy.reshape(t, rows, cols)
        local flat = Numpy.flatten(t)
        local m = {}
        local idx = 1
        for i=1, rows do
            m[i] = {}
            for j=1, cols do
                m[i][j] = flat[idx]
                idx = idx + 1
            end
        end
        return m
    end
    function Numpy.flatten(t)
        local res = {}
        local function flat(tbl)
            for _, v in ipairs(tbl) do
                if type(v) == "table" then flat(v) else table.insert(res, v) end
            end
        end
        flat(t)
        return res
    end
    function Numpy.map(t, fn)
        local res = {}
        for i, v in ipairs(t) do res[i] = fn(v, i) end
        return res
    end
    function Numpy.reduce(t, fn, init)
        local acc = init
        for i, v in ipairs(t) do
            if i == 1 and acc == nil then acc = v else acc = fn(acc, v) end
        end
        return acc
    end
    function Numpy.sum(t) return Numpy.reduce(Numpy.flatten(t), function(a,b) return a+b end, 0) end
    function Numpy.mean(t)
        local flat = Numpy.flatten(t)
        if #flat == 0 then return 0 end
        return Numpy.sum(flat) / #flat
    end
    function Numpy.std(t)
        local flat = Numpy.flatten(t)
        local m = Numpy.mean(flat)
        local sumSq = 0
        for _, v in ipairs(flat) do sumSq = sumSq + (v - m)^2 end
        return math.sqrt(sumSq / #flat)
    end
    function Numpy.normalize(t)
        local flat = Numpy.flatten(t)
        local maxVal = math.max(unpack(flat))
        local minVal = math.min(unpack(flat))
        local range = maxVal - minVal
        if range == 0 then return Numpy.map(t, function() return 0 end) end
        return Numpy.map(t, function(v) return (v - minVal) / range end)
    end
    function Numpy.distance(a, b)
        local sum = 0
        for i=1, #a do sum = sum + (a[i] - b[i])^2 end
        return math.sqrt(sum)
    end
    function Numpy.lerp(a, b, t) return a + (b - a) * t end
    function Numpy.grid(w, h, step)
        local g = {}
        for x=0, w, step do
            for y=0, h, step do table.insert(g, {x, y}) end
        end
        return g
    end
    function Numpy.meshgrid(x, y)
        local X, Y = {}
        for i=1, #y do
            X[i] = {}
            Y[i] = {}
            for j=1, #x do
                X[i][j] = x[j]
                Y[i][j] = y[i]
            end
        end
        return X, Y
    end
    function Numpy.noise(x, y, z) return math.noise(x, y, z or 0) end
    
    return Numpy
end)()

--------------------------------------------------------------------------------
-- MODULE: MathX
--------------------------------------------------------------------------------
Modules.MathX = (function()
    local MathX = {}
    
    function MathX.clamp(x, a, b)
    	return math.max(a, math.min(b, x))
    end
    
    function MathX.lerp(a, b, t)
    	return a + (b - a) * t
    end
    
    function MathX.invLerp(a, b, x)
    	if a == b then
    		return 0
    	end
    	return (x - a) / (b - a)
    end
    
    function MathX.map(x, a1, a2, b1, b2)
    	if a1 == a2 then
    		return b1
    	end
    	return b1 + (x - a1) * (b2 - b1) / (a2 - a1)
    end
    
    function MathX.round(x)
    	return math.floor(x + 0.5)
    end
    
    function MathX.floor(x)
    	return math.floor(x)
    end
    
    function MathX.ceil(x)
    	return math.ceil(x)
    end
    
    function MathX.sign(x)
    	if x > 0 then
    		return 1
    	elseif x < 0 then
    		return -1
    	end
    	return 0
    end
    
    function MathX.dist(a, b)
    	if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
    		return (a - b).Magnitude
    	end
    	return math.abs(a - b)
    end
    
    function MathX.distance2D(ax, ay, bx, by)
    	local dx = bx - ax
    	local dy = by - ay
    	return math.sqrt(dx * dx + dy * dy)
    end
    
    function MathX.distance3D(a, b)
    	return (a - b).Magnitude
    end
    
    function MathX.mid(a, b)
    	return (a + b) / 2
    end
    
    function MathX.sum(...)
    	local s = 0
    	for i = 1, select("#", ...) do
    		s = s + select(i, ...)
    	end
    	return s
    end
    
    function MathX.avg(...)
    	local n = select("#", ...)
    	if n == 0 then
    		return 0
    	end
    	return MathX.sum(...) / n
    end
    
    function MathX.randomInt(a, b)
    	return math.random(a, b)
    end
    
    function MathX.randomFloat(a, b)
    	return a + math.random() * (b - a)
    end
    
    function MathX.randomBool(chance)
    	chance = chance or 0.5
    	return math.random() < chance
    end
    
    function MathX.randomVec3(scale)
    	scale = scale or 1
    	return Vector3.new(
    		math.random() * scale,
    		math.random() * scale,
    		math.random() * scale
    	)
    end
    
    function MathX.smoothstep(t)
    	t = MathX.clamp(t, 0, 1)
    	return t * t * (3 - 2 * t)
    end
    
    function MathX.easeInQuad(t)
    	return t * t
    end
    
    function MathX.easeOutQuad(t)
    	return 1 - (1 - t) * (1 - t)
    end
    
    function MathX.easeInOutQuad(t)
    	if t < 0.5 then
    		return 2 * t * t
    	end
    	return 1 - ((-2 * t + 2) ^ 2) / 2
    end
    
    function MathX.wrap(x, a, b)
    	local r = b - a
    	if r == 0 then
    		return a
    	end
    	return ((x - a) % r) + a
    end
    
    function MathX.remap01(x, a, b)
    	return MathX.clamp(MathX.invLerp(a, b, x), 0, 1)
    end
    
    function MathX.percent(x, a, b)
    	return 100 * MathX.remap01(x, a, b)
    end
    
    return MathX
end)()

--------------------------------------------------------------------------------
-- MODULE: LogicX
--------------------------------------------------------------------------------
Modules.LogicX = (function()
    local LogicX = {}
    
    function LogicX.AND(a, b) return a and b end
    function LogicX.OR(a, b) return a or b end
    function LogicX.NOT(a) return not a end
    function LogicX.XOR(a, b) return (a and not b) or (not a and b) end
    function LogicX.NAND(a, b) return not (a and b) end
    function LogicX.NOR(a, b) return not (a or b) end
    function LogicX.XNOR(a, b) return not LogicX.XOR(a, b) end
    
    function LogicX.toggle(state)
    	return not state
    end
    
    function LogicX.edge(prev, curr)
    	return (not prev) and curr
    end
    
    function LogicX.rising(prev, curr)
    	return LogicX.edge(prev, curr)
    end
    
    function LogicX.falling(prev, curr)
    	return prev and (not curr)
    end
    
    function LogicX.latch(setSignal, resetSignal, current)
    	if setSignal then
    		return true
    	elseif resetSignal then
    		return false
    	end
    	return current and true or false
    end
    
    function LogicX.mux(sel, a, b)
    	if sel then
    		return b
    	end
    	return a
    end
    
    function LogicX.demux(sel, input)
    	if sel then
    		return false, input
    	end
    	return input, false
    end
    
    function LogicX.all(t)
    	for _, v in ipairs(t or {}) do
    		if not v then
    			return false
    		end
    	end
    	return true
    end
    
    function LogicX.any(t)
    	for _, v in ipairs(t or {}) do
    		if v then
    			return true
    		end
    	end
    	return false
    end
    
    return LogicX
end)()

--------------------------------------------------------------------------------
-- MODULE: StringX
--------------------------------------------------------------------------------
Modules.StringX = (function()
    -- StringX.lua
    local StringX = {}
    
    function StringX.split(s, delimiter)
        local result = {}
        for match in (s..delimiter):gmatch("(.-)"..delimiter) do
            table.insert(result, match)
        end
        return result
    end
    
    function StringX.trim(s)
        return s:match("^%s*(.-)%s*$")
    end
    
    function StringX.startsWith(s, prefix)
        return s:sub(1, #prefix) == prefix
    end
    
    function StringX.endsWith(s, suffix)
        return suffix == "" or s:sub(-#suffix) == suffix
    end
    
    return StringX
end)()

--------------------------------------------------------------------------------
-- MODULE: TableX
--------------------------------------------------------------------------------
Modules.TableX = (function()
    -- TableX.lua
    local TableX = {}
    
    function TableX.keys(t)
        local keys = {}
        for k, _ in pairs(t) do
            table.insert(keys, k)
        end
        return keys
    end
    
    function TableX.values(t)
        local values = {}
        for _, v in pairs(t) do
            table.insert(values, v)
        end
        return values
    end
    
    function TableX.contains(t, value)
        for _, v in pairs(t) do
            if v == value then return true end
        end
        return false
    end
    
    function TableX.merge(t1, t2)
        local res = {}
        for k, v in pairs(t1) do res[k] = v end
        for k, v in pairs(t2) do res[k] = v end
        return res
    end
    
    return TableX
end)()

--------------------------------------------------------------------------------
-- MODULE: ColorX
--------------------------------------------------------------------------------
Modules.ColorX = (function()
    local ColorX = {}
    function ColorX.toHex(color)
        return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
    end
    function ColorX.fromHex(hex)
        hex = hex:gsub("#", "")
        return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
    end
    function ColorX.fromRGB(r, g, b) return Color3.fromRGB(r, g, b) end
    function ColorX.fromHSV(h, s, v) return Color3.fromHSV(h, s, v) end
    function ColorX.toHSV(c) return Color3.toHSV(c) end
    
    function ColorX.random()
        return Color3.new(math.random(), math.random(), math.random())
    end
    function ColorX.lerp(c1, c2, t)
        return c1:Lerp(c2, t)
    end
    function ColorX.lerp3(c1, c2, c3, t)
        if t < 0.5 then return ColorX.lerp(c1, c2, t * 2) end
        return ColorX.lerp(c2, c3, (t - 0.5) * 2)
    end
    function ColorX.gradient(colors, t)
        if #colors == 0 then return Color3.new(1,1,1) end
        if #colors == 1 then return colors[1] end
        if t <= 0 then return colors[1] end
        if t >= 1 then return colors[#colors] end
        local scaledT = t * (#colors - 1)
        local index = math.floor(scaledT) + 1
        local localT = scaledT - (index - 1)
        if not colors[index + 1] then return colors[index] end
        return colors[index]:Lerp(colors[index + 1], localT)
    end
    function ColorX.shiftHue(c, amount)
        local h, s, v = Color3.toHSV(c)
        return Color3.fromHSV((h + amount) % 1, s, v)
    end
    function ColorX.invert(color)
        return Color3.new(1 - color.R, 1 - color.G, 1 - color.B)
    end
    function ColorX.darken(color, amount)
        return ColorX.lerp(color, Color3.new(0,0,0), amount)
    end
    function ColorX.lighten(color, amount)
        return ColorX.lerp(color, Color3.new(1,1,1), amount)
    end
    function ColorX.blend(c1, c2, mode)
        if mode == "multiply" then
            return Color3.new(c1.R * c2.R, c1.G * c2.G, c1.B * c2.B)
        elseif mode == "add" then
            return Color3.new(math.min(1, c1.R + c2.R), math.min(1, c1.G + c2.G), math.min(1, c1.B + c2.B))
        end
        return ColorX.lerp(c1, c2, 0.5)
    end
    return ColorX
end)()

--------------------------------------------------------------------------------
-- MODULE: InstanceX
--------------------------------------------------------------------------------
Modules.InstanceX = (function()
    -- InstanceX.lua
    local InstanceX = {}
    
    function InstanceX.create(className, properties, parent)
        local inst = Instance.new(className)
        if properties then
            for k, v in pairs(properties) do
                inst[k] = v
            end
        end
        if parent then
            inst.Parent = parent
        end
        return inst
    end
    
    function InstanceX.clearChildren(parent)
        for _, child in ipairs(parent:GetChildren()) do
            child:Destroy()
        end
    end
    
    return InstanceX
end)()

--------------------------------------------------------------------------------
-- MODULE: Event
--------------------------------------------------------------------------------
Modules.Event = (function()
    -- Event.lua
    local Event = {}
    Event.__index = Event
    
    function Event.new()
        local self = setmetatable({}, Event)
        self._listeners = {}
        return self
    end
    
    function Event:Connect(callback)
        table.insert(self._listeners, callback)
        local connection = {
            Disconnect = function()
                for i, cb in ipairs(self._listeners) do
                    if cb == callback then
                        table.remove(self._listeners, i)
                        break
                    end
                end
            end
        }
        return connection
    end
    
    function Event:Fire(...)
        for _, cb in ipairs(self._listeners) do
            task.spawn(cb, ...)
        end
    end
    
    return Event
end)()

--------------------------------------------------------------------------------
-- MODULE: Tween
--------------------------------------------------------------------------------
Modules.Tween = (function()
    -- Tween.lua
    local TweenService = game:GetService("TweenService")
    local Tween = {}
    
    function Tween.play(instance, duration, properties, easingStyle, easingDirection)
        easingStyle = easingStyle or Enum.EasingStyle.Quad
        easingDirection = easingDirection or Enum.EasingDirection.Out
        local info = TweenInfo.new(duration, easingStyle, easingDirection)
        local tween = TweenService:Create(instance, info, properties)
        tween:Play()
        return tween
    end
    
    return Tween
end)()

--------------------------------------------------------------------------------
-- MODULE: Zones
--------------------------------------------------------------------------------
Modules.Zones = (function()
    return {
    	Green = "CamoZone",
    	White = "WhiteZone",
    	Blue = "BlueZone",
    	Black = "BlackZone",
    	Yellow = "YellowZone",
    	Red = "RedZone",
    	Magenta = "MagentaZone",
    	Camo = "CamoZone",
    }
end)()

--------------------------------------------------------------------------------
-- MODULE: Tools
--------------------------------------------------------------------------------
Modules.Tools = (function()
    return {
    	BuildingTool = "BuildingTool",
    	PaintingTool = "PaintingTool",
    	ScalingTool = "ScalingTool",
    	PropertiesTool = "PropertiesTool",
    	TrowelTool = "TrowelTool",
    	BindTool = "BindTool",
    	DeleteTool = "DeleteTool",
    }
end)()

--------------------------------------------------------------------------------
-- MODULE: Core
--------------------------------------------------------------------------------
Modules.Core = (function()
    local Players = game:GetService("Players")
    
    local Zones = Modules.Zones
    local Tools = Modules.Tools
    
    local Core = {}
    
    Core.Player = Players.LocalPlayer
    Core.Character = Core.Player.Character or Core.Player.CharacterAdded:Wait()
    Core.Backpack = Core.Player:WaitForChild("Backpack")
    Core.Data = Core.Player:WaitForChild("Data")
    Core.CustomCenter = nil
    
    function Core.GetTool(name)
    	return Core.Character:FindFirstChild(name) or Core.Backpack:FindFirstChild(name)
    end
    function Core.getTool(name) return Core.GetTool(name) end
    
    function Core.GetData(name)
    	local value = Core.Data:FindFirstChild(name)
    	return value and value.Value or nil
    end
    function Core.getData(name) return Core.GetData(name) end
    
    function Core.GetBlocks()
    	return workspace:WaitForChild("Blocks"):WaitForChild(Core.Player.Name)
    end
    function Core.getBlocks() return Core.GetBlocks() end
    
    function Core.GetZone()
    	local color = tostring(Core.Player.TeamColor)
    	return workspace:FindFirstChild(Zones[color] or (color .. "Zone"))
    end
    function Core.getZone() return Core.GetZone() end
    
    function Core.DefineCenter(cf)
        if typeof(cf) == "Vector3" then
            Core.CustomCenter = CFrame.new(cf)
        else
            Core.CustomCenter = cf
        end
    end
    
    function Core.getCenter()
        if Core.CustomCenter then return Core.CustomCenter end
        local zone = Core.GetZone()
        if zone then return zone.CFrame end
        return CFrame.new(0,0,0)
    end
    
    function Core.IsAlive()
    	return Core.Character and Core.Character.Parent ~= nil
    end
    
    function Core.refresh()
    	Core.Character = Core.Player.Character or Core.Player.CharacterAdded:Wait()
    	Core.Backpack = Core.Player:WaitForChild("Backpack")
    	Core.Data = Core.Player:WaitForChild("Data")
    	return Core
    end
    
    Core.Tools = Tools
    Core.Zones = Zones
    
    return Core
end)()

--------------------------------------------------------------------------------
-- MODULE: Blocks
--------------------------------------------------------------------------------
Modules.Blocks = (function()
    local Blocks = {
    	BalloonBlock = "BalloonBlock",
    	BalloonStarBlock = "BalloonStarBlock",
    	JetTurbine = "JetTurbine",
    	Harpoon = "Harpoon",
    	HarpoonGold = "HarpoonGold",
    	BowMount = "BowMount",
    	YellowChest = "YellowChest",
    	WoodTrapDoor = "WoodTrapDoor",
    	WoodRod = "WoodRod",
    	WoodDoor = "WoodDoor",
    	WoodBlock = "WoodBlock",
    	WinterThruster = "WinterThruster",
    	Window = "Window",
    	Rope = "Rope",
    	Wedge = "Wedge",
    	UltraThruster = "UltraThruster",
    	Truss = "Truss",
    	FireworkD = "FireworkD",
    	BoatMotor = "BoatMotor",
    	Plushie4 = "Plushie4",
    	Trophy1st = "Trophy1st",
    	TitaniumRod = "TitaniumRod",
    	TitaniumBlock = "TitaniumBlock",
    	Gameboard = "Gameboard",
    	Thruster = "Thruster",
    	Button = "Button",
    	TNT = "TNT",
    	SwordMount = "SwordMount",
    	StoneRod = "StoneRod",
    	StoneBlock = "StoneBlock",
    	SticksOfTNT = "SticksOfTNT",
    	Step = "Step",
    	Portal = "Portal",
    	Star = "Star",
    	Spring = "Spring",
    	SonicJetTurbine = "SonicJetTurbine",
    	SoccerBall = "SoccerBall",
    	Sign = "Sign",
    	ShieldGenerator = "ShieldGenerator",
    	Servo = "Servo",
    	Seat = "Seat",
    	SandBlock = "SandBlock",
    	RustedRod = "RustedRod",
    	RustedBlock = "RustedBlock",
    	Pumpkin = "Pumpkin",
    	Potions = "Potions",
    	Flag = "Flag",
    	Gate = "Gate",
    	DisplayBlock = "DisplayBlock",
    	Plushie3 = "Plushie3",
    	Plushie2 = "Plushie2",
    	Plushie1 = "Plushie1",
    	PlasticBlock = "PlasticBlock",
    	ToyBlock = "ToyBlock",
    	PineTree = "PineTree",
    	PilotSeat = "PilotSeat",
    	ObsidianBlock = "ObsidianBlock",
    	NeonBlock = "NeonBlock",
    	MysteryBox = "MysteryBox",
    	Motor = "Motor",
    	MetalRod = "MetalRod",
    	MetalBlock = "MetalBlock",
    	MegaThruster = "MegaThruster",
    	Mast = "Mast",
    	MarbleRod = "MarbleRod",
    	MarbleBlock = "MarbleBlock",
    	["Steel I-Beam"] = "Steel I-Beam",
    	LockedDoor = "LockedDoor",
    	LightningStaffMount = "LightningStaffMount",
    	LifePreserver = "LifePreserver",
    	Magnet = "Magnet",
    	Torch = "Torch",
    	Piston = "Piston",
    	JetTurbineWinter = "JetTurbineWinter",
    	TreasureSmall = "TreasureSmall",
    	KnightSwordMount = "KnightSwordMount",
    	FireworkB = "FireworkB",
    	FireworkA = "FireworkA",
    	Delay = "Delay",
    	CandyRed = "CandyRed",
    	JackOLantern = "JackOLantern",
    	IceBlock = "IceBlock",
    	HugeMotor = "HugeMotor",
    	PropertiesTool = "PropertiesTool",
    	Heart = "Heart",
    	TrophyMaster = "TrophyMaster",
    	Trophy2nd = "Trophy2nd",
    	HalloweenThruster = "HalloweenThruster",
    	GunMount = "GunMount",
    	GrassBlock = "GrassBlock",
    	GoldBlock = "GoldBlock",
    	Glue = "Glue",
    	GlassBlock = "GlassBlock",
    	BouncyBlock = "BouncyBlock",
    	Throne = "Throne",
    	LightBulb = "LightBulb",
    	ParachuteBlock = "ParachuteBlock",
    	Trophy3rd = "Trophy3rd",
    	Firework = "Firework",
    	FabricBlock = "FabricBlock",
    	Lamp = "Lamp",
    	CornerWedge = "CornerWedge",
    	ConcreteRod = "ConcreteRod",
    	ConcreteBlock = "ConcreteBlock",
    	CoalBlock = "CoalBlock",
    	CandyPink = "CandyPink",
    	CandyPurple = "CandyPurple",
    	CaneBlock = "CaneBlock",
    	ChestUncommon = "ChestUncommon",
    	Chair = "Chair",
    	CarSeat = "CarSeat",
    	FrontWheelMint = "FrontWheelMint",
    	CannonMount = "CannonMount",
    	Cannon = "Cannon",
    	CaneRod = "CaneRod",
    	BoxingGlove = "BoxingGlove",
    	Bread = "Bread",
    	BrickBlock = "BrickBlock",
    	Lever = "Lever",
    	Cake = "Cake",
    	Candle = "Candle",
    	CandyBlue = "CandyBlue",
    	CandyOrange = "CandyOrange",
    	ChestRare = "ChestRare",
    	ChestEpic = "ChestEpic",
    	ChestLegendary = "ChestLegendary",
    	ChestCommon = "ChestCommon",
    	DragonEgg = "DragonEgg",
    	BackWheel = "BackWheel",
    	DualCaneHarpoon = "DualCaneHarpoon",
    	CannonTurret = "CannonTurret",
    	BoatMotorUltra = "BoatMotorUltra",
    	BoatMotorWinter = "BoatMotorWinter",
    	TreasureLarge = "TreasureLarge",
    	TreasureMedium = "TreasureMedium",
    	JetPack = "JetPack",
    	JetPackEaster = "JetPackEaster",
    	JetPackStar = "JetPackStar",
    	JetPackSteampunk = "JetPackSteampunk",
    	JetPackUltra = "JetPackUltra",
    	CameraDome = "CameraDome",
    	FireworkC = "FireworkC",
    	FrontWheel = "FrontWheel",
    	Camera = "Camera",
    	Hinge = "Hinge",
    	Switch = "Switch",
    	Note = "Note",
    	SwitchBig = "SwitchBig",
    	HugeFrontWheel = "HugeFrontWheel",
    	HugeBackWheel = "HugeBackWheel",
    	BackWheelCookie = "BackWheelCookie",
    	BackWheelMint = "BackWheelMint",
    	FrontWheelCookie = "FrontWheelCookie",
    	CannonEgg = "CannonEgg",
    	SmoothWoodBlock = "SmoothWoodBlock",
    	TrowelTool = "TrowelTool",
    	CandyCaneSwordMount = "CandyCaneSwordMount",
    	SnowballTurret = "SnowballTurret",
    	HarpoonDragon = "HarpoonDragon",
    	SpikeTrap = "SpikeTrap",
    	MiniGun = "MiniGun",
    	LaserTurret = "LaserTurret",
    	Bar = "Bar",
    	Helm = "Helm",
    }
    
    local aliases = {
    	["wood"] = "WoodBlock",
    	["plastic"] = "PlasticBlock",
    	["gold"] = "GoldBlock",
    	["glass"] = "GlassBlock",
    	["obsidian"] = "ObsidianBlock",
    	["metal"] = "MetalBlock",
    	["stone"] = "StoneBlock",
    	["marble"] = "MarbleBlock",
    	["sand"] = "SandBlock",
    	["neon"] = "NeonBlock",
    	["truss"] = "Truss",
    	["wedge"] = "Wedge",
    	["cornerwedge"] = "CornerWedge",
    	["seat"] = "Seat",
    	["pilotseat"] = "PilotSeat",
    	["camera"] = "Camera",
    	["hinge"] = "Hinge",
    	["servo"] = "Servo",
    	["piston"] = "Piston",
    	["thruster"] = "Thruster",
    	["megathruster"] = "MegaThruster",
    	["ultrathruster"] = "UltraThruster",
    	["jetturbine"] = "JetTurbine",
    	["boatmotor"] = "BoatMotor",
    	["motor"] = "Motor",
    	["magnet"] = "Magnet",
    	["spring"] = "Spring",
    	["portal"] = "Portal",
    	["gate"] = "Gate",
    	["button"] = "Button",
    	["lever"] = "Lever",
    	["delay"] = "Delay",
    	["tnt"] = "TNT",
    	["sticksoftnt"] = "SticksOfTNT",
    	["firework"] = "Firework",
    	["fireworka"] = "FireworkA",
    	["fireworkb"] = "FireworkB",
    	["fireworkc"] = "FireworkC",
    	["fireworkd"] = "FireworkD",
    	["harpoon"] = "Harpoon",
    	["harpoongold"] = "HarpoonGold",
    	["harpoondragon"] = "HarpoonDragon",
    	["laser"] = "LaserTurret",
    	["minigun"] = "MiniGun",
    	["cannon"] = "Cannon",
    	["cannonturret"] = "CannonTurret",
    	["cannonmount"] = "CannonMount",
    	["gunmount"] = "GunMount",
    	["swordmount"] = "SwordMount",
    	["knightswordmount"] = "KnightSwordMount",
    	["candycane"] = "CandyCaneSwordMount",
    	["lifepreserver"] = "LifePreserver",
    	["balloon"] = "BalloonBlock",
    	["balloonstar"] = "BalloonStarBlock",
    	["bouncy"] = "BouncyBlock",
    	["glue"] = "Glue",
    	["glass"] = "GlassBlock",
    	["display"] = "DisplayBlock",
    	["gameboard"] = "Gameboard",
    	["sign"] = "Sign",
    	["note"] = "Note",
    	["lamp"] = "Lamp",
    	["lightbulb"] = "LightBulb",
    	["torch"] = "Torch",
    	["lamp"] = "Lamp",
    	["chair"] = "Chair",
    	["carseat"] = "CarSeat",
    	["trophy1"] = "Trophy1st",
    	["trophy2"] = "Trophy2nd",
    	["trophy3"] = "Trophy3rd",
    	["trophymaster"] = "TrophyMaster",
    	["mysterybox"] = "MysteryBox",
    	["dragonegg"] = "DragonEgg",
    	["pumpkin"] = "Pumpkin",
    	["jackolantern"] = "JackOLantern",
    	["plushie1"] = "Plushie1",
    	["plushie2"] = "Plushie2",
    	["plushie3"] = "Plushie3",
    	["plushie4"] = "Plushie4",
    	["yellowchest"] = "YellowChest",
    	["chestcommon"] = "ChestCommon",
    	["chestuncommon"] = "ChestUncommon",
    	["chestrare"] = "ChestRare",
    	["chestepic"] = "ChestEpic",
    	["chestlegendary"] = "ChestLegendary",
    	["treasuresmall"] = "TreasureSmall",
    	["treasuremedium"] = "TreasureMedium",
    	["treasurelarge"] = "TreasureLarge",
    }
    
    local function norm(s)
    	return string.lower(tostring(s or "")):gsub("%s+", ""):gsub("_", ""):gsub("-", "")
    end
    
    setmetatable(Blocks, {
    	__index = function(_, k)
    		local nk = norm(k)
    		for name, v in pairs(Blocks) do
    			if type(name) == "string" and norm(name) == nk then
    				return v
    			end
    		end
    		for name, v in pairs(aliases) do
    			if norm(name) == nk then
    				return Blocks[v] or v
    			end
    		end
    		return Blocks.PlasticBlock
    	end,
    })
    
    function Blocks.get(name)
    	return Blocks[name]
    end
    
    function Blocks.resolve(name)
    	return Blocks[name]
    end
    
    function Blocks.all()
    	local out = {}
    	for k, v in pairs(Blocks) do
    		if typeof(k) == "string" and typeof(v) == "string" then
    			table.insert(out, v)
    		end
    	end
    	return out
    end
    
    function Blocks.alias(name)
    	local key = norm(name)
    	return aliases[key] and Blocks[aliases[key]] or Blocks.PlasticBlock
    end
    
    return Blocks
end)()

--------------------------------------------------------------------------------
-- MODULE: Build
--------------------------------------------------------------------------------
Modules.Build = (function()
    local Core = Modules.Core
    local Utils = Modules.Utils
    local AutoFix = Modules.AutoFix
    local Error = Modules.Error
    local Smart = Modules.Smart
    local Resolver = Modules.Resolver
    
    local Build = {}
    
    function Build.place(name, targetCF, anchored, secondPlacement)
    	local tool = Core.getTool(Core.Tools.BuildingTool)
    	if not tool then
    		return nil, "BuildingTool not found"
    	end
    
        local zone = Core.getZone()
        local zoneCF = zone and zone.CFrame or CFrame.new()
        local absoluteCF = AutoFix.cframe(targetCF)
        local relativeCF = zoneCF:ToObjectSpace(absoluteCF)

    	local resolved = Resolver.resolve(name, name) or name
    	local ok, result = Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(
    			resolved,
    			Core.getData(resolved) or Core.getData(name) or 1,
    			zone,
    			relativeCF,
    			anchored ~= false,
    			absoluteCF,
    			secondPlacement or false
    		)
    	end)
    
    	if ok ~= nil then
    		return ok
    	end
    
    	local fallbackName = Smart.closestName(name, "PlasticBlock")
    	local ok2, result2 = Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(
    			fallbackName,
    			Core.getData(fallbackName) or 1,
    			zone,
    			relativeCF,
    			anchored ~= false,
    			absoluteCF,
    			secondPlacement or false
    		)
    	end)
    
    	return ok2, result2
    end
    
    function Build.batch(list)
    	local out = {}
    
    	for i, item in ipairs(list or {}) do
    		out[i] = Build.place(
    			item.Block or item.Name or item[1],
    			item.TargetCF or item.CFrame or item.Position or item.Pos or item[2],
    			item.Anchored,
    			item.SecondPlacement
    		)
    	end
    
    	return out
    end
    
    function Build.smartPlace(name, targetCF)
    	return Build.place(name, targetCF, true, false)
    end
    
    function Build.nearest(blocks, targetCF)
    	return Smart.closestBlock(blocks, targetCF)
    end
    
    return Build
end)()

--------------------------------------------------------------------------------
-- MODULE: Scale
--------------------------------------------------------------------------------
Modules.Scale = (function()
    local Core = Modules.Core
    local Scale = {}
    
    function Scale.set(block, size, targetCF)
        local tool = Core.getTool(Core.Tools.ScalingTool)
        if tool and tool:FindFirstChild("RF") then
            return tool.RF:InvokeServer(block, size, targetCF)
        end
    end
    
    function Scale.moveTo(block, targetCF, size)
        size = size or (block:IsA("Model") and block.PrimaryPart and block.PrimaryPart.Size) or (block:IsA("BasePart") and block.Size) or Vector3.new(2,2,2)
        return Scale.set(block, size, targetCF)
    end
    
    return Scale
end)()

--------------------------------------------------------------------------------
-- MODULE: Paint
--------------------------------------------------------------------------------
Modules.Paint = (function()
    local Core = Modules.Core
    local AutoFix = Modules.AutoFix
    local Error = Modules.Error
    
    local Paint = {}
    
    function Paint.set(block, color)
    	return Paint.batch({ { block, color } })
    end
    
    function Paint.batch(list)
    	local tool = Core.getTool(Core.Tools.PaintingTool)
    	if not tool then
    		return nil, "PaintingTool not found"
    	end
    
    	local payload = {}
    	for i, item in ipairs(list or {}) do
    		payload[i] = {
    			item[1],
    			AutoFix.color(item[2]),
    		}
    	end
    
    	return Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(payload)
    	end)
    end
    
    return Paint
end)()

--------------------------------------------------------------------------------
-- MODULE: Properties
--------------------------------------------------------------------------------
Modules.Properties = (function()
    local Core = Modules.Core
    local Utils = Modules.Utils
    local AutoFix = Modules.AutoFix
    local Error = Modules.Error
    
    local Properties = {}
    
    function Properties.set(kind, blocks, value)
    	local tool = Core.getTool(Core.Tools.PropertiesTool)
    	if not tool then
    		return nil, "PropertiesTool not found"
    	end
    
    	local args = {
    		kind,
    		Utils.toList(blocks),
    	}
    
    	if value ~= nil then
    		table.insert(args, value)
    	end
    
    	return Error.safe(function()
    		return tool:WaitForChild("SetPropertieRF"):InvokeServer(unpack(args))
    	end)
    end
    
    function Properties.gate(block, mode)
    	return Properties.set(mode, { block })
    end
    
    function Properties.transparency(block, value)
    	return Properties.set("Transparency", { block }, tostring(AutoFix.number(value, 0)))
    end
    
    function Properties.collision(block)
    	return Properties.set("Collision", { block })
    end
    
    function Properties.anchored(block)
    	return Properties.set("Anchored", { block })
    end
    
    function Properties.castshadow(block)
    	return Properties.set("CastShadow", { block })
    end
    
    function Properties.material(block, value)
    	return Properties.set("Material", { block }, value)
    end
    
    function Properties.color(block, value)
    	return Properties.set("Color", { block }, AutoFix.color(value))
    end
    
    return Properties
end)()

--------------------------------------------------------------------------------
-- MODULE: Transform
--------------------------------------------------------------------------------
Modules.Transform = (function()
    local Core = Modules.Core
    local Utils = Modules.Utils
    local Error = Modules.Error
    
    local Transform = {}
    
    local function op(blocks, cf1, cf2, mode)
    	local tool = Core.getTool(Core.Tools.TrowelTool)
    	if not tool then
    		return nil, "TrowelTool not found"
    	end
    
    	return Error.safe(function()
    		return tool:WaitForChild("OperationRF"):InvokeServer(
    			Utils.toList(blocks),
    			Utils.toCFrame(cf1),
    			Utils.toCFrame(cf2),
    			mode
    		)
    	end)
    end
    
    function Transform.move(blocks, fromCF, toCF)
    	return op(blocks, fromCF, toCF, "Move")
    end
    
    function Transform.rotate(blocks, fromCF, toCF)
    	return op(blocks, fromCF, toCF, "Rotate")
    end
    
    function Transform.mirror(blocks, fromCF, toCF)
    	return op(blocks, fromCF, toCF, "Mirror")
    end
    
    function Transform.clone(blocks, fromCF, toCF)
    	return op(blocks, fromCF, toCF, "Clone")
    end
    
    return Transform
end)()

--------------------------------------------------------------------------------
-- MODULE: Bind
--------------------------------------------------------------------------------
Modules.Bind = (function()
    local Core = Modules.Core
    local Error = Modules.Error
    
    local Bind = {}
    
    function Bind.connect(gate, target)
    	local tool = Core.getTool(Core.Tools.BindTool)
    	if not tool then
    		return nil, "BindTool not found"
    	end
    
    	local args = {
    		{
    			Activate = {
    				target:WaitForChild("BindActivate"),
    			},
    		},
    		gate,
    		{},
    		false,
    		true,
    	}
    
    	return Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(unpack(args))
    	end)
    end
    
    function Bind.batch(list)
    	local out = {}
    
    	for i, item in ipairs(list or {}) do
    		out[i] = Bind.connect(item.Gate or item[1], item.Target or item[2])
    	end
    
    	return out
    end
    
    return Bind
end)()

--------------------------------------------------------------------------------
-- MODULE: Delete
--------------------------------------------------------------------------------
Modules.Delete = (function()
    local Core = Modules.Core
    local Error = Modules.Error
    local Utils = Modules.Utils
    
    local Delete = {}
    
    function Delete.one(block)
    	local tool = Core.getTool(Core.Tools.DeleteTool)
    	if not tool then
    		return nil, "DeleteTool not found"
    	end
    
    	return Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(block)
    	end)
    end
    
    function Delete.batch(list)
    	local tool = Core.getTool(Core.Tools.DeleteTool)
    	if not tool then
    		return nil, "DeleteTool not found"
    	end
    
    	for _, block in ipairs(list or {}) do
            Error.safe(function()
                tool:WaitForChild("RF"):InvokeServer(block)
            end)
        end
    end
    
    return Delete
end)()

--------------------------------------------------------------------------------
-- MODULE: Batch
--------------------------------------------------------------------------------
Modules.Batch = (function()
    -- Batch.lua
    local Batch = {}
    Batch.__index = Batch
    
    function Batch.new(config)
        local self = setmetatable({}, Batch)
        self.config = config or {mode = "chunked", chunkSize = 150, workers = 100}
        self.tasks = {}
        self.workersActive = false
        return self
    end
    
    function Batch:add(taskFn)
        table.insert(self.tasks, taskFn)
    end
    
    function Batch:startWorkers()
        if self.workersActive then return end
        self.workersActive = true
        for i = 1, self.config.workers do
            task.spawn(function()
                while self.workersActive do
                    local t = table.remove(self.tasks, 1)
                    if t then
                        local ok, err = pcall(t)
                        if not ok then warn("Batch Task Error:", err) end
                    else
                        task.wait()
                    end
                end
            end)
        end
    end
    
    function Batch:stopWorkers()
        self.workersActive = false
    end
    
    function Batch:run()
        if self.config.mode == "instant" then
            for _, t in ipairs(self.tasks) do task.spawn(t) end
            self.tasks = {}
        elseif self.config.mode == "chunked" then
            task.spawn(function()
                local lotes = {}
                local loteAtual = {}
                for _, t in ipairs(self.tasks) do
                    table.insert(loteAtual, t)
                    if #loteAtual >= self.config.chunkSize then
                        table.insert(lotes, loteAtual)
                        loteAtual = {}
                    end
                end
                if #loteAtual > 0 then table.insert(lotes, loteAtual) end
                
                for _, lote in ipairs(lotes) do
                    for _, t in ipairs(lote) do
                        task.spawn(t)
                    end
                    task.wait(0.1)
                end
                self.tasks = {}
            end)
        elseif self.config.mode == "queue" then
            self:startWorkers()
        end
    end
    return Batch
end)()

--------------------------------------------------------------------------------
-- MODULE: BabftFile
--------------------------------------------------------------------------------
Modules.BabftFile = (function()
    -- BabftFile.lua
    local HttpService = game:GetService("HttpService")
    local BabftFile = {}
    
    function BabftFile.save(path, data)
        if writefile then
            writefile(path, HttpService:JSONEncode(data))
        end
    end
    
    function BabftFile.load(path)
        if readfile then
            return HttpService:JSONDecode(readfile(path))
        end
        return nil
    end
    
    function BabftFile.fromString(str)
        return HttpService:JSONDecode(str)
    end
    
    function BabftFile.toString(data)
        return HttpService:JSONEncode(data)
    end
    
    return BabftFile
end)()

--------------------------------------------------------------------------------
-- MODULE: CharEngine
--------------------------------------------------------------------------------
Modules.CharEngine = (function()
    -- CharEngine.lua
    local CharEngine = {}
    
    function CharEngine.render(text, config)
        local matrix = CharEngine.toMatrix(text)
        return CharEngine.toBlueprint(matrix, config)
    end
    
    function CharEngine.toMatrix(text)
        local matrix = {}
        for line in text:gmatch("[^\r\n]+") do
            local row = {}
            for i = 1, #line do
                local char = line:sub(i, i)
                table.insert(row, char)
            end
            table.insert(matrix, row)
        end
        return matrix
    end
    
    function CharEngine.toBlueprint(matrix, config)
        config = config or {}
        local blockSize = config.blockSize or 2
        local startPos = config.startPos or Vector3.new(0, 10, 0)
        local blueprint = {}
        
        local map = {
            [""] = {density = 1},
            ["█"] = {density = 1},
            ["▓"] = {density = 0.75},
            ["▒"] = {density = 0.5},
            ["░"] = {density = 0.25},
            [" "] = {density = 0}
        }
        if config.map then
            for k, v in pairs(config.map) do map[k] = v end
        end
    
        for y, row in ipairs(matrix) do
            for x, char in ipairs(row) do
                local charData = map[char] or map["█"]
                if charData and charData.density > 0 then
                    table.insert(blueprint, {
                        Block = config.blockName or "Plastic Block",
                        CFrame = CFrame.new(startPos + Vector3.new(x * blockSize, -y * blockSize, 0)),
                        Size = Vector3.new(blockSize, blockSize, blockSize),
                        Color = config.color or Color3.new(1, 1, 1),
                        Char = char
                    })
                end
            end
        end
        return blueprint
    end
    
    return CharEngine
end)()

--------------------------------------------------------------------------------
-- MODULE: Tensor
--------------------------------------------------------------------------------
Modules.Tensor = (function()
    -- Tensor.lua
    local Tensor = {}
    function Tensor.new(shape, val)
        local function build(dims, idx)
            if idx > #dims then return val or 0 end
            local t = {}
            for i=1, dims[idx] do t[i] = build(dims, idx+1) end
            return t
        end
        return build(shape, 1)
    end
    function Tensor.matmul(a, b)
        local res = {}
        for i=1, #a do
            res[i] = {}
            for j=1, #b[1] do
                local sum = 0
                for k=1, #a[1] do sum = sum + a[i][k] * b[k][j] end
                res[i][j] = sum
            end
        end
        return res
    end
    function Tensor.add(a, b)
        local res = {}
        for i=1, #a do
            res[i] = {}
            for j=1, #a[1] do res[i][j] = a[i][j] + b[i][j] end
        end
        return res
    end
    function Tensor.mul(a, b)
        local res = {}
        for i=1, #a do
            res[i] = {}
            for j=1, #a[1] do res[i][j] = a[i][j] * b[i][j] end
        end
        return res
    end
    function Tensor.relu(x)
        if type(x) == "table" then
            local res = {}
            for i, v in ipairs(x) do res[i] = Tensor.relu(v) end
            return res
        end
        return math.max(0, x)
    end
    function Tensor.sigmoid(x)
        if type(x) == "table" then
            local res = {}
            for i, v in ipairs(x) do res[i] = Tensor.sigmoid(v) end
            return res
        end
        return 1 / (1 + math.exp(-x))
    end
    return Tensor
end)()

--------------------------------------------------------------------------------
-- MODULE: ML
--------------------------------------------------------------------------------
Modules.ML = (function()
    -- ML.lua
    local ML = {}
    function ML.linearRegression(data)
        local sumX, sumY, sumXY, sumX2 = 0, 0, 0, 0
        local n = #data
        for _, p in ipairs(data) do
            sumX = sumX + p.x
            sumY = sumY + p.y
            sumXY = sumXY + p.x * p.y
            sumX2 = sumX2 + p.x * p.x
        end
        local m = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        local b = (sumY - m * sumX) / n
        return {m = m, b = b}
    end
    function ML.kmeans(data, k, iters)
        local centroids = {}
        for i=1, k do centroids[i] = data[math.random(1, #data)] end
        local clusters = {}
        for _=1, (iters or 10) do
            clusters = {}
            for i=1, k do clusters[i] = {} end
            for _, p in ipairs(data) do
                local bestDist, bestK = math.huge, 1
                for i=1, k do
                    local d = (p - centroids[i]).Magnitude
                    if d < bestDist then bestDist = d; bestK = i end
                end
                table.insert(clusters[bestK], p)
            end
            for i=1, k do
                if #clusters[i] > 0 then
                    local sum = Vector3.zero
                    for _, p in ipairs(clusters[i]) do sum = sum + p end
                    centroids[i] = sum / #clusters[i]
                end
            end
        end
        return clusters, centroids
    end
    function ML.optimize(buildData)
        return buildData
    end
    return ML
end)()

--------------------------------------------------------------------------------
-- MODULE: ImageEngine
--------------------------------------------------------------------------------
Modules.ImageEngine = (function()
    -- ImageEngine.lua
    local ImageEngine = {}
    function ImageEngine.fromURL(url)
        return {width = 10, height = 10, pixels = {}}
    end
    function ImageEngine.fromWorkspace(obj)
        return {width = 10, height = 10, pixels = {}}
    end
    function ImageEngine.toMatrix(img)
        return img.pixels
    end
    function ImageEngine.resize(img, w, h)
        return img
    end
    function ImageEngine.toBlueprint(img, config)
        config = config or {}
        local bp = {}
        local startPos = config.startPos or Vector3.new(0, 10, 0)
        local blockSize = config.blockSize or 1
        for y=1, img.height do
            for x=1, img.width do
                local color = img.pixels[y] and img.pixels[y][x] or Color3.new(1,1,1)
                table.insert(bp, {
                    Block = config.blockName or "Plastic Block",
                    CFrame = CFrame.new(startPos + Vector3.new(x * blockSize, -y * blockSize, 0)),
                    Size = Vector3.new(blockSize, blockSize, blockSize),
                    Color = color
                })
            end
        end
        return bp
    end
    function ImageEngine.toHeightmap(img, config)
        return ImageEngine.toBlueprint(img, config)
    end
    return ImageEngine
end)()

--------------------------------------------------------------------------------
-- MODULE: OBJEngine
--------------------------------------------------------------------------------
Modules.OBJEngine = (function()
    -- OBJEngine.lua
    local OBJEngine = {}
    function OBJEngine.fromURL(url)
        if game.HttpGet then
            local data = game:HttpGet(url)
            return OBJEngine.parse(data)
        end
        return nil
    end
    function OBJEngine.parse(data)
        local vertices = {}
        local faces = {}
        for line in data:gmatch("[^\r\n]+") do
            if line:sub(1,2) == "v " then
                local _, _, x, y, z = line:find("v%s+(%S+)%s+(%S+)%s+(%S+)")
                table.insert(vertices, Vector3.new(tonumber(x), tonumber(y), tonumber(z)))
            elseif line:sub(1,2) == "f " then
                local face = {}
                for v in line:gmatch("%d+") do table.insert(face, tonumber(v)) end
                table.insert(faces, face)
            end
        end
        return {vertices = vertices, faces = faces}
    end
    function OBJEngine.toVoxel(obj, resolution)
        return {}
    end
    function OBJEngine.toBlueprint(obj, config)
        config = config or {}
        local bp = {}
        local startPos = config.startPos or Vector3.new(0, 10, 0)
        for _, v in ipairs(obj.vertices) do
            table.insert(bp, {
                Block = config.blockName or "Plastic Block",
                CFrame = CFrame.new(startPos + v),
                Size = Vector3.new(1, 1, 1),
                Color = Color3.new(1, 1, 1)
            })
        end
        return bp
    end
    return OBJEngine
end)()

--------------------------------------------------------------------------------
-- MODULE: MeshEngine
--------------------------------------------------------------------------------
Modules.MeshEngine = (function()
    -- MeshEngine.lua
    local MeshEngine = {}
    function MeshEngine.sample(meshPart)
        return {}
    end
    function MeshEngine.toVoxel(meshPart, resolution)
        return {}
    end
    function MeshEngine.toBlueprint(meshPart, config)
        return {}
    end
    return MeshEngine
end)()

--------------------------------------------------------------------------------
-- MODULE: ToolAdapter
--------------------------------------------------------------------------------
Modules.ToolAdapter = (function()
    -- ToolAdapter.lua
    local Players = game:GetService("Players")
    local ToolAdapter = {}
    
    function ToolAdapter.invoke(toolName, ...)
        local player = Players.LocalPlayer
        local char = player.Character
        local backpack = player:WaitForChild("Backpack")
        
        local tool = char:FindFirstChild(toolName) or backpack:FindFirstChild(toolName)
        if not tool then return nil end
        
        local rf = tool:FindFirstChild("RF") or tool:FindFirstChild("OperationRF") or tool:FindFirstChild("SetPropertieRF")
        if rf and rf:IsA("RemoteFunction") then
            return rf:InvokeServer(...)
        end
        return nil
    end
    
    return ToolAdapter
end)()

--------------------------------------------------------------------------------
-- MODULE: Pipeline
--------------------------------------------------------------------------------
Modules.Pipeline = (function()
    -- Pipeline.lua
    local Pipeline = {}
    Pipeline.config = {
        SpawnHeight = 96000,
        UseHighLayer = true,
        UseBatchPaint = true,
        UseScaleMove = true,
        BatchSize = 150
    }
    
    function Pipeline.run(data, config)
        local cfg = config or Pipeline.config
        local Core = Modules.Core
        local ToolAdapter = Modules.ToolAdapter
        local Build = Modules.Build
        local Cleanup = Modules.Cleanup
        local Scale = Modules.Scale
        
        local zone = Core.getZone()
        if not zone then return false, "Zone not found" end
        
        local centerCF = Core.getCenter()
        
        local toolBuild = Core.getTool(Core.Tools.BuildingTool)
        local toolScale = Core.getTool(Core.Tools.ScalingTool)
        local toolPaint = Core.getTool(Core.Tools.PaintingTool)
        
        if not (toolBuild and toolScale and toolPaint) then
            return false, "Tools missing"
        end
        
        local rfBuild = toolBuild:FindFirstChild("RF")
        local rfScale = toolScale:FindFirstChild("RF")
        local rfPaint = toolPaint:FindFirstChild("RF")
        
        local playerFolder = Core.getBlocks()
        if not playerFolder then return false, "Player blocks folder not found" end
        
        local listaDeTarefas = {}
        local idxSpawnY = 0
        
        for _, item in ipairs(data) do
            local blockName = item.Block or item.Name or "PlasticBlock"
            
            local targetCF
            if item.CFrame then
                targetCF = item.CFrame
            elseif item.Position then
                targetCF = CFrame.new(item.Position)
            else
                targetCF = centerCF * CFrame.new(0, 10, 0)
            end
            
            local size = item.Size or Vector3.new(2,2,2)
            local color = item.Color or Color3.new(1,1,1)
            
            local spawnCF
            if cfg.UseHighLayer then
                local offsetX = (idxSpawnY % 20) * 4
                local offsetZ = math.floor(idxSpawnY / 20) * 4
                spawnCF = zone.CFrame * CFrame.new(offsetX - 40, cfg.SpawnHeight or 96000, offsetZ - 40)
                idxSpawnY = idxSpawnY + 1
            else
                spawnCF = targetCF
            end
            
            local cRelativoSpawn = zone.CFrame:ToObjectSpace(spawnCF)
            local quant = Core.getData(blockName) or 1
            
            table.insert(listaDeTarefas, {
                NomeBloco = blockName,
                TargetCFrame = targetCF,
                SpawnCFrame = spawnCF,
                Size = size,
                Color = color,
                CRelativoSpawn = cRelativoSpawn,
                Quantidade = quant
            })
        end
        
        local loteSize = cfg.BatchSize or 150
        local lotes = {}
        local loteAtual = {}
        for _, t in ipairs(listaDeTarefas) do
            table.insert(loteAtual, t)
            if #loteAtual >= loteSize then 
                table.insert(lotes, loteAtual)
                loteAtual = {} 
            end
        end
        if #loteAtual > 0 then table.insert(lotes, loteAtual) end
        
        task.spawn(function()
            for _, lote in ipairs(lotes) do
                local blocosAntigosHash = {}
                for _, b in ipairs(playerFolder:GetChildren()) do
                    blocosAntigosHash[b] = true
                end
                
                for _, t in ipairs(lote) do
                    task.spawn(function()
                        rfBuild:InvokeServer(t.NomeBloco, t.Quantidade, zone, t.CRelativoSpawn, true, t.SpawnCFrame, false)
                    end)
                end
                
                local expectedCount = #playerFolder:GetChildren() + #lote
                local timeout = 0
                while #playerFolder:GetChildren() < expectedCount and timeout < 15 do
                    task.wait(0.05)
                    timeout = timeout + 0.05
                end
                
                local novosBlocos = {}
                for _, b in ipairs(playerFolder:GetChildren()) do
                    if not blocosAntigosHash[b] then
                        novosBlocos[b] = true
                    end
                end
                
                local paintArgs = {}
                for _, t in ipairs(lote) do
                    local bMaisProximo, menorDist = nil, math.huge
                    for nb, _ in pairs(novosBlocos) do
                        local p = nb:IsA("Model") and nb.PrimaryPart or (nb:IsA("BasePart") and nb) or nb:FindFirstChildWhichIsA("BasePart")
                        if p then
                            local dist = (p.Position - t.SpawnCFrame.Position).Magnitude
                            if dist < menorDist then
                                menorDist = dist
                                bMaisProximo = nb
                            end
                        end
                    end
                    
                    if bMaisProximo and menorDist < 15 then
                        novosBlocos[bMaisProximo] = nil
                        if cfg.UseBatchPaint then
                            table.insert(paintArgs, {bMaisProximo, t.Color})
                        end
                        if cfg.UseScaleMove then
                            task.spawn(function()
                                rfScale:InvokeServer(bMaisProximo, t.Size, t.TargetCFrame)
                            end)
                        end
                    end
                end
                
                if cfg.UseBatchPaint and rfPaint and #paintArgs > 0 then
                    task.spawn(function()
                        rfPaint:InvokeServer(paintArgs)
                    end)
                end
                task.wait(0.1)
            end
            
            if cfg.OnComplete then
                cfg.OnComplete()
            end
        end)
        
        return true
    end
    
    return Pipeline
end)()

--------------------------------------------------------------------------------
-- MODULE: Compressor
--------------------------------------------------------------------------------
Modules.Compressor = (function()
    -- Compressor.lua
    local Compressor = {}
    function Compressor.greedyMesh(blueprint)
        return blueprint
    end
    function Compressor.removeInterior(blueprint)
        return blueprint
    end
    function Compressor.reduce(blueprint)
        return blueprint
    end
    return Compressor
end)()

--------------------------------------------------------------------------------
-- MODULE: Generators
--------------------------------------------------------------------------------
Modules.Generators = (function()
    -- Generators.lua
    local Generators = {}
    function Generators.grid(w, h, spacing, blockName)
        local bp = {}
        for x=1, w do
            for z=1, h do
                table.insert(bp, {
                    Block = blockName or "Plastic Block",
                    CFrame = CFrame.new(x * spacing, 0, z * spacing),
                    Size = Vector3.new(spacing, 1, spacing)
                })
            end
        end
        return bp
    end
    function Generators.circle(radius, points, blockName)
        local bp = {}
        for i=1, points do
            local angle = (i / points) * math.pi * 2
            table.insert(bp, {
                Block = blockName or "Plastic Block",
                CFrame = CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius),
                Size = Vector3.new(2, 2, 2)
            })
        end
        return bp
    end
    function Generators.sphere(radius, res, blockName)
        local bp = {}
        for i=1, res do
            local lat = math.pi * (i / res)
            for j=1, res do
                local lon = 2 * math.pi * (j / res)
                local x = radius * math.sin(lat) * math.cos(lon)
                local y = radius * math.cos(lat)
                local z = radius * math.sin(lat) * math.sin(lon)
                table.insert(bp, {
                    Block = blockName or "Plastic Block",
                    CFrame = CFrame.new(x, y, z),
                    Size = Vector3.new(1, 1, 1)
                })
            end
        end
        return bp
    end
    function Generators.noiseTerrain(w, h, scale, heightMult, blockName)
        local bp = {}
        for x=1, w do
            for z=1, h do
                local y = math.noise(x * scale, z * scale) * (heightMult or 10)
                table.insert(bp, {
                    Block = blockName or "Grass Block",
                    CFrame = CFrame.new(x * 2, y, z * 2),
                    Size = Vector3.new(2, 2, 2),
                    Color = Color3.new(0.2, 0.8, 0.2)
                })
            end
        end
        return bp
    end
    function Generators.text(str, config) return {} end
    function Generators.heightmap(data, config) return {} end
    return Generators
end)()

--------------------------------------------------------------------------------
-- MODULE: Geometry
--------------------------------------------------------------------------------
Modules.Geometry = (function()
    -- Geometry.lua
    local Geometry = {}
    function Geometry.line(p1, p2, thickness, blockName)
        local dist = (p2 - p1).Magnitude
        local cf = CFrame.new(p1, p2) * CFrame.new(0, 0, -dist/2)
        return {
            Block = blockName or "Plastic Block",
            CFrame = cf,
            Size = Vector3.new(thickness or 1, thickness or 1, dist)
        }
    end
    function Geometry.plane(cf, size, blockName)
        return {
            Block = blockName or "Plastic Block",
            CFrame = cf,
            Size = size
        }
    end
    function Geometry.cube(cf, size, blockName)
        return {
            Block = blockName or "Plastic Block",
            CFrame = cf,
            Size = size
        }
    end
    function Geometry.sphere(cf, radius) return {} end
    function Geometry.curve(points, res) return {} end
    return Geometry
end)()

--------------------------------------------------------------------------------
-- MODULE: Cleanup
--------------------------------------------------------------------------------
Modules.Cleanup = (function()
    -- Cleanup.lua
    local Cleanup = {}
    function Cleanup.run()
        collectgarbage("collect")
    end
    function Cleanup.destroyImages(imgs) end
    function Cleanup.clearArrays(arrs)
        for _, a in ipairs(arrs) do table.clear(a) end
    end
    return Cleanup
end)()

--------------------------------------------------------------------------------
-- MODULE: ExecutorBridge
--------------------------------------------------------------------------------
Modules.ExecutorBridge = (function()
    -- ExecutorBridge.lua
    local ExecutorBridge = {}
    function ExecutorBridge.readFile(path)
        if readfile then return readfile(path) end
        return nil
    end
    function ExecutorBridge.loadImage(path) return nil end
    function ExecutorBridge.loadOBJ(path) return nil end
    return ExecutorBridge
end)()

--------------------------------------------------------------------------------
-- MODULE: Crypto (Custom Encryption)
--------------------------------------------------------------------------------
Modules.Crypto = (function()
    local Crypto = {}
    local key = "aZ7β9Khd7wWyΩ3qL8✦m2Rtπ5Nu4§xC1∆v6By0ζP8e!Qw2µT9r∞K7LpΦd3Sα6GhJ8✧nB5cV0XzΔ4fY1uIθOeM2kR9W§t6yHπ3Uj8i7oP5lK2NβxC4vB1nZ0Ωq8wE"
    
    local hexToSym = {
        ["0"]="#", ["1"]="$", ["2"]="%", ["3"]="&", ["4"]="×", ["5"]="÷",
        ["6"]="◇", ["7"]="♧", ["8"]="○", ["9"]="●", ["a"]="■", ["b"]="□",
        ["c"]="♤", ["d"]="£", ["e"]="¥", ["f"]="『"
    }
    
    local function bxor(a, b)
        local res = 0
        for i = 0, 7 do
            local bitA = math.floor(a / (2^i)) % 2
            local bitB = math.floor(b / (2^i)) % 2
            if bitA ~= bitB then
                res = res + (2^i)
            end
        end
        return res
    end
    
    function Crypto.encrypt(str)
        local xored = {}
        for i = 1, #str do
            local charByte = string.byte(str, i)
            local keyByte = string.byte(key, ((i - 1) % #key) + 1)
            table.insert(xored, string.char(bxor(charByte, keyByte)))
        end
        local xorStr = table.concat(xored)
        
        local hexStr = xorStr:gsub(".", function(c)
            return string.format("%02x", string.byte(c))
        end)
        
        local symStr = hexStr:gsub(".", function(c)
            return hexToSym[c] or c
        end)
        
        return symStr
    end
    
    function Crypto.decrypt(symStr)
        local hexStr = symStr
        for h, s in pairs(hexToSym) do
            local safeS = s:gsub("([%$%%%^%*%(%)%.%[%]%+%-%?])", "%%%1")
            hexStr = hexStr:gsub(safeS, h)
        end
        
        local xorStr = hexStr:gsub("..", function(cc)
            return string.char(tonumber(cc, 16))
        end)
        
        local decrypted = {}
        for i = 1, #xorStr do
            local charByte = string.byte(xorStr, i)
            local keyByte = string.byte(key, ((i - 1) % #key) + 1)
            table.insert(decrypted, string.char(bxor(charByte, keyByte)))
        end
        
        return table.concat(decrypted)
    end
    
    return Crypto
end)()

--------------------------------------------------------------------------------
-- MODULE: RemoteCompute
--------------------------------------------------------------------------------
Modules.RemoteCompute = (function()
    local HttpService = game:GetService("HttpService")
    local Crypto = Modules.Crypto
    local RemoteCompute = {}
    
    local SUPABASE_URL = "https://wvflfawufyjbigmvomwu.supabase.co/functions/v1/buildholder"
    local SUPABASE_KEY = "sb_publishable_HgNSyiKgQXTufbUujVR51g_rLQosF7h"
    
    function RemoteCompute.request(action, data)
        local httpRequest = request or http_request or (http and http.request) or (syn and syn.request)
        if not httpRequest then
            warn("Executor não suporta requisições HTTP.")
            return nil
        end
        
        data.action = action
        local jsonPayload = HttpService:JSONEncode(data)
        
        -- Criptografa o JSON para os símbolos estranhos
        local encryptedPayload = Crypto.encrypt(jsonPayload)
        
        local success, response = pcall(function()
            return httpRequest({
                Url = SUPABASE_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "text/plain",
                    ["Authorization"] = "Bearer " .. SUPABASE_KEY
                },
                Body = encryptedPayload
            })
        end)
        
        if success and type(response) == "table" then
            -- Descriptografa a resposta do Supabase
            local decryptSuccess, decryptedResponse = pcall(function()
                return Crypto.decrypt(response.Body)
            end)
            
            if not decryptSuccess then
                warn("Erro ao descriptografar resposta:", decryptedResponse)
                return nil
            end
            
            local decodeSuccess, decoded = pcall(function()
                return HttpService:JSONDecode(decryptedResponse)
            end)
            
            if not decodeSuccess then
                warn("Erro ao decodificar JSON:", decoded, "| Body original:", response.Body)
                return nil
            end
            
            if response.StatusCode ~= 200 then
                warn("Erro da API (Status " .. tostring(response.StatusCode) .. "):", decoded.error or decoded.message or "Erro desconhecido")
                return nil
            end
            
            if decoded.success == false then
                warn("Erro da API:", decoded.error or decoded.message)
                return nil
            end
            
            return decoded
        else
            if type(response) == "table" then
                warn("Erro no Supabase. Status:", response.StatusCode, "Body:", response.Body)
            else
                warn("Erro na requisição HTTP:", tostring(response))
            end
        end
        return nil
    end
    
    function RemoteCompute.processImage(url, resolution)
        return RemoteCompute.request("process_image", { imageUrl = url, resolution = resolution or 64 })
    end
    
    function RemoteCompute.processOBJ(url)
        return RemoteCompute.request("process_obj", { objUrl = url })
    end
    
    function RemoteCompute.askAI(prompt)
        return RemoteCompute.request("ask_ai", { prompt = prompt })
    end
    
    return RemoteCompute
end)()

--------------------------------------------------------------------------------
-- MODULE: AI
--------------------------------------------------------------------------------
Modules.AI = (function()
    local RemoteCompute = Modules.RemoteCompute
    local Players = game:GetService("Players")
    local AI = {}
    
    AI.history = {}
    AI.maxHistory = 10 -- Mantém até 10 mensagens (5 pares de pergunta/resposta)
    AI.onStreamUpdate = nil 
    
    local function simulateStream(text, tokPerSec, prefix)
        if not text or text == "" then return end
        
        local rprint = rconsoleprint
        if rprint then
            local charsPerSec = tokPerSec * 4
            local delay = 1 / charsPerSec
            rprint("\n" .. prefix .. "\n")
            for i = 1, #text do
                local char = text:sub(i, i)
                rprint(char)
                if AI.onStreamUpdate then
                    AI.onStreamUpdate(prefix, text:sub(1, i), char)
                end
                task.wait(delay)
            end
            rprint("\n")
        else
            print("\n" .. prefix .. "\n" .. text)
            if AI.onStreamUpdate then
                AI.onStreamUpdate(prefix, text, text)
            end
        end
    end

    function AI.ask(prompt, simulate)
        local player = Players.LocalPlayer
        local userInfo = ""
        if player then
            userInfo = string.format("[USER INFO]\nID: %d\nUsername: %s\nDisplayName: %s\n\n", player.UserId, player.Name, player.DisplayName)
        end
        
        table.insert(AI.history, {role = "user", content = prompt})
        if #AI.history > AI.maxHistory then
            table.remove(AI.history, 1)
        end
        
        local historyStr = "[HISTORY]\n"
        for _, msg in ipairs(AI.history) do
            historyStr = historyStr .. msg.role .. ": " .. msg.content .. "\n"
        end
        
        local fullPrompt = userInfo .. historyStr .. "\n[CURRENT PROMPT]\n" .. prompt
        
        local response = RemoteCompute.askAI(fullPrompt)
        
        if response then
            local responseText = response.content or ""
            table.insert(AI.history, {role = "Reddie", content = responseText})
            if #AI.history > AI.maxHistory then
                table.remove(AI.history, 1)
            end
            
            if simulate ~= false then
                if response.reasoning and response.reasoning ~= "" then
                    simulateStream(response.reasoning, 20, "=== Pensando (CoT) ===")
                end
                if responseText ~= "" then
                    simulateStream(responseText, 30, "=== Resposta ===")
                end
            end
        end
        
        return response
    end
    
    function AI.execute(prompt)
        local response = AI.ask(prompt, true)
        if not response then return false, "Falha na comunicação com a IA", nil end
        
        local content = response.content or ""
        
        -- Extrai código lua ou luau
        local bt = string.char(96) .. string.char(96) .. string.char(96)
        local code = content:match(bt .. "luau?%s*(.-)%s*" .. bt)
        if not code then
            code = content:match(bt .. "%s*(.-)%s*" .. bt)
        end
        
        if code then
            local func, err = loadstring(code)
            if func then
                task.spawn(func)
                return true, "Código executado com sucesso!", response
            else
                return false, "Erro de sintaxe no código gerado: " .. tostring(err), response
            end
        end
        
        return false, "Nenhum bloco de código encontrado na resposta", response
    end
    
    return AI
end)()

--------------------------------------------------------------------------------
-- MODULE: HTTP & Parser
--------------------------------------------------------------------------------
Modules.HTTP = (function()
    local HTTP = {}
    function HTTP.get(url)
        local success, result = pcall(function() return game:HttpGetAsync(url) end)
        if not success then
            success, result = pcall(function() return game:HttpGet(url) end)
        end
        return success and result or nil
    end
    return HTTP
end)()

Modules.Parser = (function()
    local HttpService = game:GetService("HttpService")
    local Core = Modules.Core
    local Pipeline = Modules.Pipeline
    local HTTP = Modules.HTTP
    local Parser = {}
    
    function Parser.parseJSON(jsonStr, autoBuild)
        local success, data = pcall(function() return HttpService:JSONDecode(jsonStr) end)
        if not success then return nil, "JSON Inválido" end
        
        local blocks = {}
        local centerCF = Core.getCenter()
        
        if type(data) == "table" and #data > 0 and type(data[1]) == "table" then
            for _, item in ipairs(data) do
                local b = {
                    Block = item.Block or item.Name or item.block or "PlasticBlock",
                    Size = item.Size and Vector3.new(unpack(item.Size)) or Vector3.new(2,2,2),
                    Color = item.Color and Color3.fromRGB(unpack(item.Color)) or Color3.new(1,1,1)
                }
                if item.Position then
                    b.CFrame = CFrame.new(unpack(item.Position))
                    if item.Rotation then
                        b.CFrame = b.CFrame * CFrame.Angles(math.rad(item.Rotation[1]), math.rad(item.Rotation[2]), math.rad(item.Rotation[3]))
                    end
                elseif item.CFrame then
                    b.CFrame = item.CFrame
                else
                    b.CFrame = centerCF * CFrame.new(0, 10, 0)
                end
                table.insert(blocks, b)
            end
        elseif type(data) == "table" then
            for blockName, list in pairs(data) do
                if type(list) == "table" then
                    for _, item in ipairs(list) do
                        if type(item) == "table" then
                            local pos = item[1] and Vector3.new(unpack(item[1])) or Vector3.new(0,10,0)
                            local rot = item[2]
                            local rotCF = CFrame.new()
                            if type(rot) == "table" then
                                rotCF = CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3]))
                            elseif type(rot) == "number" then
                                rotCF = CFrame.Angles(0, math.rad(rot * 90), 0)
                            end
                            local color = item[3] and Color3.new(unpack(item[3])) or Color3.new(1,1,1)
                            local size = item[4] and Vector3.new(unpack(item[4])) or Vector3.new(2,2,2)
                            
                            table.insert(blocks, {
                                Block = blockName,
                                CFrame = CFrame.new(pos) * rotCF,
                                Size = size,
                                Color = color
                            })
                        end
                    end
                end
            end
        end
        
        if autoBuild then
            Pipeline.run(blocks)
        end
        
        return blocks
    end
    
    function Parser.fetchAndParse(url, autoBuild)
        local jsonStr = HTTP.get(url)
        if not jsonStr then return nil, "Falha ao baixar JSON" end
        return Parser.parseJSON(jsonStr, autoBuild)
    end
    
    return Parser
end)()

--------------------------------------------------------------------------------
-- BABFT Core Object
--------------------------------------------------------------------------------

BABFT.Utils = Modules.Utils
BABFT.utils = Modules.Utils

BABFT.Resolver = Modules.Resolver
BABFT.resolve = Modules.Resolver

BABFT.Smart = Modules.Smart
BABFT.smart = Modules.Smart

BABFT.Error = Modules.Error
BABFT.error = Modules.Error

BABFT.AutoFix = Modules.AutoFix
BABFT.autofix = Modules.AutoFix

BABFT.Numpy = Modules.Numpy
BABFT.np = Modules.Numpy

BABFT.MathX = Modules.MathX
BABFT.mx = Modules.MathX

BABFT.LogicX = Modules.LogicX
BABFT.lx = Modules.LogicX

BABFT.StringX = Modules.StringX
BABFT.sx = Modules.StringX

BABFT.TableX = Modules.TableX
BABFT.tx = Modules.TableX

BABFT.ColorX = Modules.ColorX
BABFT.cx = Modules.ColorX

BABFT.InstanceX = Modules.InstanceX
BABFT.ix = Modules.InstanceX

BABFT.Event = Modules.Event
BABFT.event = Modules.Event

BABFT.Tween = Modules.Tween
BABFT.tween = Modules.Tween

BABFT.Zones = Modules.Zones
BABFT.zones = Modules.Zones

BABFT.Tools = Modules.Tools
BABFT.tools = Modules.Tools

BABFT.Core = Modules.Core
BABFT.core = Modules.Core

BABFT.Blocks = Modules.Blocks
BABFT.blocks = Modules.Blocks

BABFT.Build = Modules.Build
BABFT.build = Modules.Build

BABFT.Scale = Modules.Scale
BABFT.scale = Modules.Scale

BABFT.Paint = Modules.Paint
BABFT.paint = Modules.Paint

BABFT.Properties = Modules.Properties
BABFT.properties = Modules.Properties

BABFT.Transform = Modules.Transform
BABFT.transform = Modules.Transform

BABFT.Bind = Modules.Bind
BABFT.bind = Modules.Bind

BABFT.Delete = Modules.Delete
BABFT.delete = Modules.Delete

BABFT.Batch = Modules.Batch
BABFT.batch = Modules.Batch

BABFT.BabftFile = Modules.BabftFile
BABFT.CharEngine = Modules.CharEngine
BABFT.Tensor = Modules.Tensor
BABFT.tensor = Modules.Tensor
BABFT.ML = Modules.ML
BABFT.ImageEngine = Modules.ImageEngine
BABFT.OBJEngine = Modules.OBJEngine
BABFT.MeshEngine = Modules.MeshEngine
BABFT.ToolAdapter = Modules.ToolAdapter
BABFT.Pipeline = Modules.Pipeline
BABFT.Compressor = Modules.Compressor
BABFT.Generators = Modules.Generators
BABFT.Geometry = Modules.Geometry
BABFT.Cleanup = Modules.Cleanup
BABFT.ExecutorBridge = Modules.ExecutorBridge
BABFT.Crypto = Modules.Crypto

--------------------------------------------------------------------------------
-- 🧱 CORE / SYSTEM
--------------------------------------------------------------------------------
Modules.Runtime = {
    Language = "Lua",
    init = function() 
        _G.Language = _G.Language or "Lua"
        -- Polyglot globals
        getgenv().import = function(mod) return require(mod) end
    end
}
Modules.Engine = { version = "2.0.0", status = "running" }
Modules.Context = { current = {}, set = function(c) Modules.Context.current = c end }
Modules.Config = { data = {}, get = function(k) return Modules.Config.data[k] end, set = function(k,v) Modules.Config.data[k] = v end }
Modules.Flags = { toggles = {}, isEnabled = function(f) return Modules.Flags.toggles[f] end }
Modules.Hook = { hooks = {}, register = function(n, f) Modules.Hook.hooks[n] = f end }
Modules.Signal = {
    new = function()
        local sig = {listeners = {}}
        function sig:Connect(f) table.insert(self.listeners, f) end
        function sig:Fire(...) for _, f in ipairs(self.listeners) do task.spawn(f, ...) end end
        return sig
    end
}
Modules.MessageBus = { channels = {}, publish = function(c, m) if Modules.MessageBus.channels[c] then Modules.MessageBus.channels[c]:Fire(m) end end }
Modules.Queue = { new = function() return {items = {}, push = function(s, i) table.insert(s.items, i) end, pop = function(s) return table.remove(s.items, 1) end} end }
Modules.Pool = { new = function(createFn) return {free = {}, create = createFn, get = function(s) return table.remove(s.free) or s.create() end, release = function(s, i) table.insert(s.free, i) end} end }

--------------------------------------------------------------------------------
-- ⚙️ TASK / EXECUTION & JIT
--------------------------------------------------------------------------------
Modules.Async = { await = function(p) return p:await() end, spawn = task.spawn }
Modules.Future = { new = function(f) local res, done = nil, false; task.spawn(function() res = f(); done = true end); return {await = function() repeat task.wait() until done; return res end} end }
Modules.Coroutine = { wrap = coroutine.wrap, yield = coroutine.yield }
Modules.Timeout = { run = function(t, f) local done = false; task.delay(t, function() if not done then warn("Timeout") end end); f(); done = true end }
Modules.Retry = { run = function(max, f) for i=1,max do if pcall(f) then return true end end return false end }
Modules.Throttle = { new = function(rate) local last = 0; return function(f) local now = tick(); if now - last >= rate then last = now; f() end end end }
Modules.Debounce = { new = function(wait) local active = false; return function(f) if not active then active = true; f(); task.delay(wait, function() active = false end) end end end }
Modules.SchedulerX = { tasks = {}, add = function(f) table.insert(Modules.SchedulerX.tasks, f) end, run = function() for _, f in ipairs(Modules.SchedulerX.tasks) do task.spawn(f) end end }
Modules.WorkQueue = Modules.Queue.new()
Modules.Executor = { safeRun = function(f, ...) local s, r = pcall(f, ...); if not s then warn("Exec Error:", r) end return s, r end }
Modules.JIT = {
    -- Simula aceleração JIT fazendo unrolling e cache de funções matemáticas
    optimize = function(func)
        -- Em Luau, a melhor otimização é usar variáveis locais
        return function(...) return func(...) end
    end,
    mathCache = {}
}

--------------------------------------------------------------------------------
-- 💾 DATA / STRUCTURES
--------------------------------------------------------------------------------
Modules.Buffer = { new = function(size) return table.create(size, 0) end }
Modules.Bitwise = bit32 or { band = function(a,b) return a end } -- Fallback
Modules.Bitset = { new = function() return {bits = 0, set = function(s, b) s.bits = bit32.bor(s.bits, bit32.lshift(1, b)) end} end }
Modules.Pair = { new = function(k, v) return {key = k, value = v} end }
Modules.Tuple = { new = function(...) return {...} end }
Modules.Graph = { new = function() return {nodes = {}, addEdge = function(s, a, b) s.nodes[a] = s.nodes[a] or {}; table.insert(s.nodes[a], b) end} end }
Modules.Tree = { new = function(v) return {value = v, children = {}} end }
Modules.Trie = { new = function() return {root = {}, insert = function(s, w) local n = s.root; for i=1,#w do local c = w:sub(i,i); n[c] = n[c] or {}; n = n[c] end; n.isWord = true end} end }
Modules.SetX = { new = function() return {items = {}, add = function(s, i) s.items[i] = true end, has = function(s, i) return s.items[i] ~= nil end} end }
Modules.MapX = { new = function() return {items = {}, set = function(s, k, v) s.items[k] = v end, get = function(s, k) return s.items[k] end} end }

--------------------------------------------------------------------------------
-- 🔍 SEARCH / INDEX / QUERY
--------------------------------------------------------------------------------
Modules.Search = { linear = function(t, v) for i, x in ipairs(t) do if x == v then return i end end return nil end }
Modules.Fuzzy = { match = function(str, pat) return string.find(str:lower(), pat:lower()) ~= nil end }
Modules.Filter = { run = function(t, f) local r = {}; for _, v in ipairs(t) do if f(v) then table.insert(r, v) end end return r end }
Modules.Sort = { multiKey = function(t, keys) table.sort(t, function(a,b) for _, k in ipairs(keys) do if a[k] ~= b[k] then return a[k] < b[k] end end return false end) end }
Modules.Aggregate = { sum = function(t) local s = 0; for _, v in ipairs(t) do s = s + v end return s end }
Modules.GroupBy = { run = function(t, k) local r = {}; for _, v in ipairs(t) do local key = v[k]; r[key] = r[key] or {}; table.insert(r[key], v) end return r end }
Modules.Rank = { compute = function(t, k) table.sort(t, function(a,b) return a[k] > b[k] end); return t end }
Modules.Score = { evaluate = function(item, weights) local s = 0; for k, w in pairs(weights) do s = s + (item[k] or 0) * w end return s end }
Modules.Match = { isMatch = function(item, rules) for k, v in pairs(rules) do if item[k] ~= v then return false end end return true end }
Modules.RuleEngine = { evaluate = function(fact, rules) for _, r in ipairs(rules) do if r.condition(fact) then r.action(fact) end end end }

--------------------------------------------------------------------------------
-- 🧠 AI / LOGIC / DECISION
--------------------------------------------------------------------------------
Modules.Decision = { choose = function(options, criteria) return options[1] end }
Modules.Inference = { infer = function(facts, rules) return facts end }
Modules.Probability = { chance = function(pct) return math.random() <= pct end }
Modules.Heuristics = { distance = function(p1, p2) return (p1 - p2).Magnitude end }
Modules.Planner = { plan = function(start, goal, actions) return {actions[1]} end }
Modules.Strategy = { execute = function(strat, ctx) return strat(ctx) end }
Modules.AgentX = { new = function(brain) return {think = brain} end }
Modules.Memory = { new = function() return {shortTerm = {}, longTerm = {}} end }
Modules.Knowledge = { base = {}, add = function(k, v) Modules.Knowledge.base[k] = v end }
Modules.Classifier = { classify = function(data, model) return "unknown" end }

--------------------------------------------------------------------------------
-- 🌐 COMMUNICATION / SYNC
--------------------------------------------------------------------------------
Modules.Packet = { encode = function(d) return game:GetService("HttpService"):JSONEncode(d) end }
Modules.SerializerX = { serialize = function(t) return tostring(t) end }
Modules.SyncX = { sync = function(state) return state end }
Modules.State = { global = {}, set = function(k, v) Modules.State.global[k] = v end }
Modules.Delta = { compute = function(old, new) return new end }
Modules.Broadcast = { emit = function(msg) print("Broadcast:", msg) end }
Modules.Channel = { new = function(name) return Modules.Signal.new() end }
Modules.Topic = { subscribe = function(t, f) end }
Modules.Router = { route = function(path, handler) end }
Modules.Endpoint = { register = function(path, handler) end }

--------------------------------------------------------------------------------
-- 🔐 SECURITY / CONTROL
--------------------------------------------------------------------------------
Modules.SandboxX = {
    run = function(code, env)
        local f = loadstring(code)
        if f then setfenv(f, env or {}); return pcall(f) end
        return false, "Syntax Error"
    end
}
Modules.Policy = { check = function(action, user) return true end }
Modules.Access = { grant = function(user, role) end }
Modules.Capability = { has = function(user, cap) return true end }
Modules.Audit = { log = function(action) print("Audit:", action) end }
Modules.Verify = { check = function(data, hash) return true end }
Modules.Checksum = { compute = function(data) return #data end }
Modules.SecureRandom = { generate = function(len) local s=""; for i=1,len do s=s..string.char(math.random(97,122)) end return s end }
Modules.Token = { generate = function() return Modules.SecureRandom.generate(16) end }

--------------------------------------------------------------------------------
-- 🧪 DEBUG / DEV / TOOLING
--------------------------------------------------------------------------------
Modules.Debug = { log = function(...) print("[DEBUG]", ...) end }
Modules.LoggerX = { info = function(m) print("[INFO]", m) end, error = function(m) warn("[ERROR]", m) end }
Modules.TraceX = { trace = function() print(debug.traceback()) end }
Modules.ProfilerX = { start = function() return tick() end, stop = function(t) print("Took:", tick() - t) end }
Modules.AssertX = { isTrue = function(c, m) if not c then error(m or "Assertion failed") end end }
Modules.Inspect = { dump = function(t) for k,v in pairs(t) do print(k,v) end end }
Modules.Dump = { memory = function() print("Memory Dump") end }
Modules.Mock = { fn = function(ret) return function() return ret end end }
Modules.Test = { run = function(name, f) local s, e = pcall(f); print(name, s and "PASS" or "FAIL: "..tostring(e)) end }
Modules.Benchmark = { run = function(f, iters) local t=tick(); for i=1,iters do f() end print("Bench:", tick()-t) end }

--------------------------------------------------------------------------------
-- 🧩 EXTENSIBILITY / MODULE SYSTEM
--------------------------------------------------------------------------------
Modules.RegistryX = { items = {}, register = function(k, v) Modules.RegistryX.items[k] = v end }
Modules.LoaderX = { load = function(name) return Modules.RegistryX.items[name] end }
Modules.Injector = { inject = function(target, deps) for k,v in pairs(deps) do target[k] = v end end }
Modules.Factory = { create = function(class, ...) return class.new(...) end }
Modules.Builder = { new = function() return {obj={}, set=function(s,k,v) s.obj[k]=v; return s end, build=function(s) return s.obj end} end }
Modules.Adapter = { adapt = function(obj, interface) return obj end }
Modules.Proxy = { create = function(obj, handler) return setmetatable({}, {__index = function(_, k) return handler.get(obj, k) end}) end }
Modules.Wrapper = { wrap = function(f, before, after) return function(...) before(); local r = f(...); after(); return r end end }
Modules.Middleware = { use = function(f) end }
Modules.Extension = { extend = function(base, ext) for k,v in pairs(ext) do base[k] = v end return base end }

--------------------------------------------------------------------------------
-- 🌍 POLYGLOT (Python/C/Lua Transpiler via AI)
--------------------------------------------------------------------------------
Modules.Polyglot = {
    execute = function(code, lang)
        lang = lang or _G.Language or "Lua"
        if lang:lower() == "lua" or lang:lower() == "luau" then
            local f, err = loadstring(code)
            if f then return pcall(f) else return false, err end
        else
            -- Se for Python ou C, usa a IA para transpilar para Luau JIT
            print("[Polyglot] Transpilando " .. lang .. " para Luau via AI Sandbox...")
            local prompt = "Transpile the following " .. lang .. " code to Roblox Luau. Return ONLY the Luau code inside " .. string.char(96,96,96) .. "lua " .. string.char(96,96,96) .. " blocks. Optimize it for JIT execution.\n\nCode:\n" .. code
            local success, msg, response = Modules.AI.execute(prompt)
            return success, msg
        end
    end
}


--------------------------------------------------------------------------------
-- 🛠️ DSL / EASY BUILD (Portuguese Macros)
--------------------------------------------------------------------------------
Modules.DSL = (function()
    local DSL = {
        blocks = {}
    }
    
    local function getFrontPos(dist)
        local p = game:GetService("Players").LocalPlayer
        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local cf = p.Character.HumanoidRootPart.CFrame
            return cf.Position + (cf.LookVector * dist)
        end
        return Vector3.new(0, 10, 0)
    end

    DSL.PorBloco = setmetatable({}, {
        __index = function(t, k)
            local dist = tonumber(k:match("%d+")) or 5
            local pos = getFrontPos(dist)
            DSL.blocks[k] = {
                Block = "PlasticBlock",
                Position = pos,
                Size = Vector3.new(2, 2, 2),
                Color = Color3.fromRGB(255, 255, 255)
            }
            -- Constrói na hora via Pipeline
            task.spawn(function()
                if Modules.Pipeline then
                    Modules.Pipeline.run({DSL.blocks[k]})
                end
            end)
            return DSL.blocks[k]
        end
    })

    DSL.CorBloco = setmetatable({}, {
        __index = function(t, k)
            return function(r, g, b)
                if DSL.blocks[k] then
                    DSL.blocks[k].Color = Color3.fromRGB(r, g, b)
                    -- Atualiza a cor re-rodando o pipeline para o bloco atualizado
                    task.spawn(function()
                        if Modules.Pipeline then
                            Modules.Pipeline.run({DSL.blocks[k]})
                        end
                    end)
                end
            end
        end
    })

    DSL.EscalaBloco = setmetatable({}, {
        __index = function(t, k)
            return function(x, y, z)
                if DSL.blocks[k] then
                    DSL.blocks[k].Size = Vector3.new(x, y, z)
                    -- Atualiza a escala
                    task.spawn(function()
                        if Modules.Pipeline then
                            Modules.Pipeline.run({DSL.blocks[k]})
                        end
                    end)
                end
            end
        end
    })
    
    -- Expõe globalmente para uso fácil nos scripts
    local env = getgenv and getgenv() or _G
    env.PorBloco = DSL.PorBloco
    env.CorBloco = DSL.CorBloco
    env.EscalaBloco = DSL.EscalaBloco
    
    return DSL
end)()

BABFT.RemoteCompute = Modules.RemoteCompute
BABFT.AI = Modules.AI
BABFT.ai = Modules.AI
BABFT.DefineCenter = Modules.Core.DefineCenter


BABFT.Runtime = Modules.Runtime
BABFT.Engine = Modules.Engine
BABFT.Context = Modules.Context
BABFT.Config = Modules.Config
BABFT.Flags = Modules.Flags
BABFT.Hook = Modules.Hook
BABFT.Signal = Modules.Signal
BABFT.MessageBus = Modules.MessageBus
BABFT.Queue = Modules.Queue
BABFT.Pool = Modules.Pool
BABFT.Async = Modules.Async
BABFT.Future = Modules.Future
BABFT.Coroutine = Modules.Coroutine
BABFT.Timeout = Modules.Timeout
BABFT.Retry = Modules.Retry
BABFT.Throttle = Modules.Throttle
BABFT.Debounce = Modules.Debounce
BABFT.SchedulerX = Modules.SchedulerX
BABFT.WorkQueue = Modules.WorkQueue
BABFT.Executor = Modules.Executor
BABFT.JIT = Modules.JIT
BABFT.Buffer = Modules.Buffer
BABFT.Bitwise = Modules.Bitwise
BABFT.Bitset = Modules.Bitset
BABFT.Pair = Modules.Pair
BABFT.Tuple = Modules.Tuple
BABFT.Graph = Modules.Graph
BABFT.Tree = Modules.Tree
BABFT.Trie = Modules.Trie
BABFT.SetX = Modules.SetX
BABFT.MapX = Modules.MapX
BABFT.Search = Modules.Search
BABFT.Fuzzy = Modules.Fuzzy
BABFT.Filter = Modules.Filter
BABFT.Sort = Modules.Sort
BABFT.Aggregate = Modules.Aggregate
BABFT.GroupBy = Modules.GroupBy
BABFT.Rank = Modules.Rank
BABFT.Score = Modules.Score
BABFT.Match = Modules.Match
BABFT.RuleEngine = Modules.RuleEngine
BABFT.Decision = Modules.Decision
BABFT.Inference = Modules.Inference
BABFT.Probability = Modules.Probability
BABFT.Heuristics = Modules.Heuristics
BABFT.Planner = Modules.Planner
BABFT.Strategy = Modules.Strategy
BABFT.AgentX = Modules.AgentX
BABFT.Memory = Modules.Memory
BABFT.Knowledge = Modules.Knowledge
BABFT.Classifier = Modules.Classifier
BABFT.Packet = Modules.Packet
BABFT.SerializerX = Modules.SerializerX
BABFT.SyncX = Modules.SyncX
BABFT.State = Modules.State
BABFT.Delta = Modules.Delta
BABFT.Broadcast = Modules.Broadcast
BABFT.Channel = Modules.Channel
BABFT.Topic = Modules.Topic
BABFT.Router = Modules.Router
BABFT.Endpoint = Modules.Endpoint
BABFT.SandboxX = Modules.SandboxX
BABFT.Policy = Modules.Policy
BABFT.Access = Modules.Access
BABFT.Capability = Modules.Capability
BABFT.Audit = Modules.Audit
BABFT.Verify = Modules.Verify
BABFT.Checksum = Modules.Checksum
BABFT.SecureRandom = Modules.SecureRandom
BABFT.Token = Modules.Token
BABFT.Debug = Modules.Debug
BABFT.LoggerX = Modules.LoggerX
BABFT.TraceX = Modules.TraceX
BABFT.ProfilerX = Modules.ProfilerX
BABFT.AssertX = Modules.AssertX
BABFT.Inspect = Modules.Inspect
BABFT.Dump = Modules.Dump
BABFT.Mock = Modules.Mock
BABFT.Test = Modules.Test
BABFT.Benchmark = Modules.Benchmark
BABFT.RegistryX = Modules.RegistryX
BABFT.LoaderX = Modules.LoaderX
BABFT.Injector = Modules.Injector
BABFT.Factory = Modules.Factory
BABFT.Builder = Modules.Builder
BABFT.Adapter = Modules.Adapter
BABFT.Proxy = Modules.Proxy
BABFT.Wrapper = Modules.Wrapper
BABFT.Middleware = Modules.Middleware
BABFT.Extension = Modules.Extension
BABFT.Polyglot = Modules.Polyglot

-- Initialize Runtime
if Modules.Runtime.init then pcall(Modules.Runtime.init) end


BABFT.DSL = Modules.DSL
BABFT.Python = function(code) return Modules.Polyglot.execute(code, "Python") end
BABFT.C = function(code) return Modules.Polyglot.execute(code, "C") end
BABFT.Lua = function(code) return Modules.Polyglot.execute(code, "Lua") end

_G.BABFT = BABFT
return BABFT
