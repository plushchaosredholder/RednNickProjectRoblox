-- BABFT_Bundle.lua
-- Biblioteca Unificada para Build A Boat For Treasure

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
    		s += select(i, ...)
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
    -- ColorX.lua
    local ColorX = {}
    function ColorX.toHex(color)
        return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
    end
    function ColorX.fromHex(hex)
        hex = hex:gsub("#", "")
        return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
    end
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
    function ColorX.gradient2D(colors, x, y) return colors[1] end
    function ColorX.palette(colors, n) return colors end
    function ColorX.quantize(color, palette) return color end
    function ColorX.dither(img, palette) return img end
    function ColorX.noiseColor(x, y, z) return Color3.new(math.noise(x,y,z), math.noise(y,z,x), math.noise(z,x,y)) end
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
    
    function Core.GetTool(name)
    	return Core.Character:FindFirstChild(name) or Core.Backpack:FindFirstChild(name)
    end
    
    function Core.getTool(name)
    	return Core.GetTool(name)
    end
    
    function Core.GetData(name)
    	local value = Core.Data:FindFirstChild(name)
    	return value and value.Value or nil
    end
    
    function Core.getData(name)
    	return Core.GetData(name)
    end
    
    function Core.GetBlocks()
    	return workspace:WaitForChild("Blocks"):WaitForChild(Core.Player.Name)
    end
    
    function Core.getBlocks()
    	return Core.GetBlocks()
    end
    
    function Core.GetZone()
    	local color = tostring(Core.Player.TeamColor)
    	return workspace:FindFirstChild(Zones[color] or (color .. "Zone"))
    end
    
    function Core.getZone()
    	return Core.GetZone()
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
    
    function Build.place(name, pos, targetCF, anchored, secondPlacement)
    	local tool = Core.getTool(Core.Tools.BuildingTool)
    	if not tool then
    		return nil, "BuildingTool not found"
    	end
    
    	local resolved = Resolver.resolve(name, name) or name
    	local ok, result = Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(
    			resolved,
    			Core.getData(resolved) or Core.getData(name),
    			Core.getZone(),
    			AutoFix.cframe(pos),
    			anchored ~= false,
    			AutoFix.cframe(targetCF),
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
    			Core.getData(fallbackName),
    			Core.getZone(),
    			AutoFix.cframe(pos),
    			anchored ~= false,
    			AutoFix.cframe(targetCF),
    			secondPlacement or false
    		)
    	end)
    
    	return ok2, result2
    end
    
    function Build.batch(list)
    	local out = {}
    
    	for i, item in ipairs(list or {}) do
    		out[i] = Build.place(
    			item.Name or item[1],
    			item.Position or item.Pos or item[2],
    			item.TargetCF or item.CFrame or item[3],
    			item.Anchored,
    			item.SecondPlacement
    		)
    	end
    
    	return out
    end
    
    function Build.smartPlace(name, pos, targetCF)
    	return Build.place(name, pos, targetCF, true, false)
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
    local AutoFix = Modules.AutoFix
    local Error = Modules.Error
    
    local Scale = {}
    
    function Scale.set(block, size, cf)
    	local tool = Core.getTool(Core.Tools.ScalingTool)
    	if not tool then
    		return nil, "ScalingTool not found"
    	end
    
    	return Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(
    			block,
    			AutoFix.vector(size),
    			AutoFix.cframe(cf)
    		)
    	end)
    end
    
    function Scale.batch(list)
    	local out = {}
    
    	for i, item in ipairs(list or {}) do
    		out[i] = Scale.set(
    			item.Block or item[1],
    			item.Size or item[2],
    			item.CFrame or item.TargetCF or item[3]
    		)
    	end
    
    	return out
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
    		return tool:WaitForChild("RF"):InvokeServer(Utils.toList(block))
    	end)
    end
    
    function Delete.batch(list)
    	local tool = Core.getTool(Core.Tools.DeleteTool)
    	if not tool then
    		return nil, "DeleteTool not found"
    	end
    
    	local payload = Utils.toList(list)
    	return Error.safe(function()
    		return tool:WaitForChild("RF"):InvokeServer(payload)
    	end)
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
        self.config = config or {mode = "chunked", chunkSize = 50}
        self.tasks = {}
        return self
    end
    
    function Batch:add(task)
        table.insert(self.tasks, task)
    end
    
    function Batch:run()
        if self.config.mode == "instant" then
            for _, t in ipairs(self.tasks) do t() end
        elseif self.config.mode == "chunked" then
            for i=1, #self.tasks, self.config.chunkSize do
                for j=i, math.min(i+self.config.chunkSize-1, #self.tasks) do
                    self.tasks[j]()
                end
                task.wait()
            end
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
        for line in text:gmatch("[^\\r\\n]+") do
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
        for line in data:gmatch("[^\\r\\n]+") do
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
        
        local rf = tool:FindFirstChild("RF")
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
        SpawnHeight = 980000,
        UseHighLayer = true,
        UseBatchPaint = true,
        UseScaleMove = true
    }
    
    function Pipeline.run(data, config)
        local cfg = config or Pipeline.config
        local ToolAdapter = Modules.ToolAdapter
        local Build = Modules.Build
        local Cleanup = Modules.Cleanup
        
        -- 1. Preprocess & 2. Spawn Alto
        local spawnData = {}
        for i, item in ipairs(data) do
            local targetCF = item.CFrame or CFrame.new(item.Position or Vector3.zero)
            local spawnCF = targetCF
            if cfg.UseHighLayer then
                spawnCF = targetCF + Vector3.new(0, cfg.SpawnHeight, 0)
            end
            table.insert(spawnData, {
                Block = item.Block,
                CFrame = spawnCF
            })
        end
        
        -- 3. Snapshot
        local beforeBlocks = {}
        for _, b in ipairs(workspace:GetDescendants()) do
            if b:IsA("BasePart") then beforeBlocks[b] = true end
        end
        
        local placedBlocks = Build.batch(spawnData)
        
        -- 4. Detect new blocks
        local newBlocks = {}
        for _, b in ipairs(placedBlocks) do
            table.insert(newBlocks, b)
        end
        
        -- 5. Match & 6. Scale + Move
        local paints = {}
        for i, block in ipairs(newBlocks) do
            local item = data[i]
            if item then
                local targetCF = item.CFrame or CFrame.new(item.Position or Vector3.zero)
                local size = item.Size or Vector3.new(2,2,2)
                
                if cfg.UseScaleMove then
                    ToolAdapter.invoke("ScalingTool", block, size, targetCF)
                end
                
                if item.Color then
                    table.insert(paints, {block, item.Color})
                end
            end
        end
        
        -- 7. Paint Batch
        if cfg.UseBatchPaint and #paints > 0 then
            ToolAdapter.invoke("PaintingTool", paints)
        end
        
        -- 8. Cleanup
        if Cleanup and Cleanup.run then
            Cleanup.run()
        end
        
        return newBlocks
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
    function Generators.sphere(radius, res, blockName) return {} end
    function Generators.noiseTerrain(w, h, scale, blockName) return {} end
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
    function Geometry.line(p1, p2, thickness) return {} end
    function Geometry.plane(p, normal, size) return {} end
    function Geometry.cube(cf, size) return {} end
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
-- MODULE: RemoteCompute
--------------------------------------------------------------------------------
Modules.RemoteCompute = (function()
    -- RemoteCompute.lua
    local RemoteCompute = {}
    function RemoteCompute.send(data) end
    function RemoteCompute.receive() return nil end
    return RemoteCompute
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
BABFT.Compressor =BABFT.Generators = Modules.Generators
BABFT.Geometry = Modules.Geometry
BABFT.Cleanup = Modules.Cleanup
BABFT.ExecutorBridge = Modules.ExecutorBridge
BABFT.RemoteCompute = Modules.RemoteCompute

return BABFT
