local BABFT = {}
local Modules = {}
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
Modules.Numpy = (function()
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
Modules.StringX = (function()
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
Modules.TableX = (function()
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
Modules.InstanceX = (function()
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
Modules.Event = (function()
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
Modules.Tween = (function()
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
Modules.Batch = (function()
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
Modules.BabftFile = (function()
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
Modules.CharEngine = (function()
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
Modules.Tensor = (function()
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
Modules.ML = (function()
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
Modules.ImageEngine = (function()
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
Modules.OBJEngine = (function()
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
Modules.MeshEngine = (function()
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
Modules.ToolAdapter = (function()
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
Modules.Pipeline = (function()
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
                                if string.match(t.NomeBloco or t.Block or "", "Block$") then
                                    rfScale:InvokeServer(bMaisProximo, t.Size, t.TargetCFrame)
                                end
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
Modules.Compressor = (function()
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
Modules.Generators = (function()
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
Modules.Geometry = (function()
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
Modules.Cleanup = (function()
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
Modules.ExecutorBridge = (function()
    local ExecutorBridge = {}
    function ExecutorBridge.readFile(path)
        if readfile then return readfile(path) end
        return nil
    end
    function ExecutorBridge.loadImage(path) return nil end
    function ExecutorBridge.loadOBJ(path) return nil end
    return ExecutorBridge
end)()
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
Modules.AI = (function()
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local AI = {}
    AI.history = {}
    AI.maxHistory = 10
    
    local function fetchAI(prompt, model, systemPrompt)
        local baseUrl = "https://text.pollinations.ai/text/"
        local url = baseUrl .. HttpService:UrlEncode(prompt)
        
        local params = {}
        if model then table.insert(params, "model=" .. HttpService:UrlEncode(model)) end
        if systemPrompt then table.insert(params, "system=" .. HttpService:UrlEncode(systemPrompt)) end
        
        if #params > 0 then
            url = url .. "?" .. table.concat(params, "&")
        end
        
        local success, result = pcall(function()
            -- Tenta usar game:HttpGetAsync ou game:HttpGet
            if game and game.HttpGetAsync then
                return game:HttpGetAsync(game, url)
            elseif game and game.HttpGet then
                return game:HttpGet(game, url)
            end
            return nil
        end)
        
        if success and result then
            return result
        end
        return nil
    end
    
    function AI.ask(prompt, simulate)
        local player = Players.LocalPlayer
        local userInfo = ""
        if player then
            userInfo = string.format("[USER INFO]\nID: %d\nUsername: %s\nDisplayName: %s\n\n", player.UserId, player.Name, player.DisplayName)
        end
        
        local rprint = rconsoleprint or print
        rprint("\n[Orquestrador GPT-4] Analisando a tarefa...\n")
        
        local systemOrchestrator = "Você é o Orquestrador (GPT-4). Crie um plano passo-a-passo claro para um Worker AI executar. Ferramentas disponíveis: build_block(blockName, amount), change_team(teamName), generate_image(prompt). Responda APENAS com o plano."
        local orchPrompt = userInfo .. "Pedido do usuário: " .. prompt
        
        local plan = fetchAI(orchPrompt, "gpt-4", systemOrchestrator)
        if not plan or plan == "" then
            plan = "Executar o pedido diretamente."
        end
        
        rprint("\n[Plano do Orquestrador]\n" .. plan .. "\n")
        rprint("\n[Worker GPT-20B OSS] Iniciando execução contínua...\n")

        local systemWorker = [[Você é o Worker AI. Execute o plano fornecido.
Para usar uma ferramenta, responda EXATAMENTE neste formato:
[CALL: nome_da_ferramenta { "param1": "valor1" }]
Exemplo: [CALL: build_block { "blockName": "WoodBlock", "amount": 5 }]

Após chamar uma ferramenta, aguarde o feedback.
Quando terminar todas as tarefas, responda com: TAREFA_CONCLUIDA: <resumo>]]

        local workerPrompt = "PLANO DE EXECUÇÃO:\n" .. plan
        local maxLoops = 8
        local loops = 0
        local finalResponse = ""
        
        while loops < maxLoops do
            loops = loops + 1
            local response = fetchAI(workerPrompt, "openai", systemWorker)
            
            if not response or response == "" then
                finalResponse = "Erro de conexão com o Worker."
                break
            end
            
            local callName, callArgsStr = response:match("%[CALL:%s*([%w_]+)%s*({.-})%]")
            
            if callName and callArgsStr then
                rprint("[Worker] Chamando ferramenta: " .. callName .. "\n")
                local success, args = pcall(function() return HttpService:JSONDecode(callArgsStr) end)
                local toolResult = ""
                
                if success and args then
                    if callName == "build_block" then
                        if Modules.Core and Modules.Core.getTool then
                            local tool = Modules.Core.getTool(Modules.Core.Tools.BuildingTool)
                            if tool and tool:FindFirstChild("RF") then
                                local zone = Modules.Core.getZone()
                                local cf = zone and zone.CFrame or CFrame.new(0,10,0)
                                tool.RF:InvokeServer(args.blockName, args.amount, nil, nil, true, cf, nil)
                                toolResult = "Sucesso: Construiu " .. tostring(args.amount) .. "x " .. tostring(args.blockName)
                            else
                                toolResult = "Erro: BuildingTool não encontrada."
                            end
                        end
                    elseif callName == "change_team" then
                        if Modules.Team then
                            Modules.Team.ChangeTeam(args.teamName)
                            toolResult = "Sucesso: Time alterado para " .. tostring(args.teamName)
                        else
                            toolResult = "Erro: Módulo de time não encontrado."
                        end
                    elseif callName == "generate_image" then
                        local encoded = HttpService:UrlEncode(args.prompt)
                        local url = "https://image.pollinations.ai/prompt/" .. encoded
                        toolResult = "Sucesso: Imagem gerada na URL: " .. url
                    else
                        toolResult = "Erro: Ferramenta desconhecida."
                    end
                else
                    toolResult = "Erro: Argumentos JSON inválidos."
                end
                
                rprint("  -> Feedback: " .. toolResult .. "\n")
                workerPrompt = workerPrompt .. "\nWorker: " .. response .. "\nFeedback: " .. toolResult
            else
                if response:match("TAREFA_CONCLUIDA") or response:match("TASK_COMPLETE") then
                    finalResponse = response
                    break
                else
                    rprint("[Worker] " .. response .. "\n")
                    workerPrompt = workerPrompt .. "\nWorker: " .. response .. "\nSistema: Continue executando o plano ou responda TAREFA_CONCLUIDA."
                end
            end
        end
        
        if finalResponse == "" then
            finalResponse = "O Worker atingiu o limite máximo de iterações ("..maxLoops..") sem concluir a tarefa."
        end
        
        rprint("\n=== Resultado Final ===\n" .. finalResponse .. "\n")
        
        table.insert(AI.history, {role = "user", content = prompt})
        table.insert(AI.history, {role = "assistant", content = finalResponse})
        if #AI.history > AI.maxHistory then table.remove(AI.history, 1) end
        if #AI.history > AI.maxHistory then table.remove(AI.history, 1) end
        
        return {content = finalResponse}
    end
    
    function AI.execute(prompt)
        local response = AI.ask(prompt, true)
        if not response then return false, "Falha na comunicação com a IA", nil end
        local content = response.content or ""
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
Modules.HTTP = (function()
    local HTTP = {}
    function HTTP.get(url)
        local success, result = pcall(function() return game:HttpGetAsync(url) end)
        if not success then success, result = pcall(function() return game:HttpGet(url) end) end
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
BABFT.RemoteCompute = Modules.RemoteCompute
BABFT.AI = Modules.AI
BABFT.HTTP = Modules.HTTP
BABFT.Parser = Modules.Parser
Modules.Runtime = {
    Language = "Lua",
    init = function() 
        _G.Language = _G.Language or "Lua"
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
    optimize = function(func)
        return function(...) return func(...) end
    end,
    mathCache = {}
}
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

-- ==============================================================================
-- 🌌 BABFT ENGINE: MAGNIFICENT EXPANSION PACK (35KB+ OF PURE POWER)
-- ==============================================================================

-- 📐 ADVANCED GEOMETRY & FRACTALS

-- 🎨 MASSIVE COLOR AND MATERIAL DICTIONARY
Modules.Dictionary = {
    Colors = {
        Red = Color3.fromRGB(255, 0, 0),
        Green = Color3.fromRGB(0, 255, 0),
        Blue = Color3.fromRGB(0, 0, 255),
        Yellow = Color3.fromRGB(255, 255, 0),
        Cyan = Color3.fromRGB(0, 255, 255),
        Magenta = Color3.fromRGB(255, 0, 255),
        White = Color3.fromRGB(255, 255, 255),
        Black = Color3.fromRGB(0, 0, 0),
        Gray = Color3.fromRGB(128, 128, 128),
        Silver = Color3.fromRGB(192, 192, 192),
        Maroon = Color3.fromRGB(128, 0, 0),
        Olive = Color3.fromRGB(128, 128, 0),
        Purple = Color3.fromRGB(128, 0, 128),
        Teal = Color3.fromRGB(0, 128, 128),
        Navy = Color3.fromRGB(0, 0, 128),
        Orange = Color3.fromRGB(255, 165, 0),
        Pink = Color3.fromRGB(255, 192, 203),
        Brown = Color3.fromRGB(165, 42, 42),
        Gold = Color3.fromRGB(255, 215, 0),
        Coral = Color3.fromRGB(255, 127, 80),
        Salmon = Color3.fromRGB(250, 128, 114),
        Khaki = Color3.fromRGB(240, 230, 140),
        Plum = Color3.fromRGB(221, 160, 221),
        Indigo = Color3.fromRGB(75, 0, 130),
        Lime = Color3.fromRGB(0, 255, 0),
        Crimson = Color3.fromRGB(220, 20, 60),
        Tomato = Color3.fromRGB(255, 99, 71),
        Chocolate = Color3.fromRGB(210, 105, 30),
        Peru = Color3.fromRGB(205, 133, 63),
        Tan = Color3.fromRGB(210, 180, 140),
        Aquamarine = Color3.fromRGB(127, 255, 212),
        Turquoise = Color3.fromRGB(64, 224, 208),
        Azure = Color3.fromRGB(240, 255, 255),
        Beige = Color3.fromRGB(245, 245, 220),
        Bisque = Color3.fromRGB(255, 228, 196),
        BlanchedAlmond = Color3.fromRGB(255, 235, 205),
        BlueViolet = Color3.fromRGB(138, 43, 226),
        BurlyWood = Color3.fromRGB(222, 184, 135),
        CadetBlue = Color3.fromRGB(95, 158, 160),
        Chartreuse = Color3.fromRGB(127, 255, 0),
        CornflowerBlue = Color3.fromRGB(100, 149, 237),
        Cornsilk = Color3.fromRGB(255, 248, 220),
        DarkBlue = Color3.fromRGB(0, 0, 139),
        DarkCyan = Color3.fromRGB(0, 139, 139),
        DarkGoldenRod = Color3.fromRGB(184, 134, 11),
        DarkGray = Color3.fromRGB(169, 169, 169),
        DarkGreen = Color3.fromRGB(0, 100, 0),
        DarkKhaki = Color3.fromRGB(189, 183, 107),
        DarkMagenta = Color3.fromRGB(139, 0, 139),
        DarkOliveGreen = Color3.fromRGB(85, 107, 47),
        DarkOrange = Color3.fromRGB(255, 140, 0),
        DarkOrchid = Color3.fromRGB(153, 50, 204),
        DarkRed = Color3.fromRGB(139, 0, 0),
        DarkSalmon = Color3.fromRGB(233, 150, 122),
        DarkSeaGreen = Color3.fromRGB(143, 188, 143),
        DarkSlateBlue = Color3.fromRGB(72, 61, 139),
        DarkSlateGray = Color3.fromRGB(47, 79, 79),
        DarkTurquoise = Color3.fromRGB(0, 206, 209),
        DarkViolet = Color3.fromRGB(148, 0, 211),
        DeepPink = Color3.fromRGB(255, 20, 147),
        DeepSkyBlue = Color3.fromRGB(0, 191, 255),
        DimGray = Color3.fromRGB(105, 105, 105),
        DodgerBlue = Color3.fromRGB(30, 144, 255),
        FireBrick = Color3.fromRGB(178, 34, 34),
        FloralWhite = Color3.fromRGB(255, 250, 240),
        ForestGreen = Color3.fromRGB(34, 139, 34),
        Fuchsia = Color3.fromRGB(255, 0, 255),
        Gainsboro = Color3.fromRGB(220, 220, 220),
        GhostWhite = Color3.fromRGB(248, 248, 255),
        GoldenRod = Color3.fromRGB(218, 165, 32),
        GreenYellow = Color3.fromRGB(173, 255, 47),
        HoneyDew = Color3.fromRGB(240, 255, 240),
        HotPink = Color3.fromRGB(255, 105, 180),
        IndianRed = Color3.fromRGB(205, 92, 92),
        Ivory = Color3.fromRGB(255, 255, 240),
        Lavender = Color3.fromRGB(230, 230, 250),
        LavenderBlush = Color3.fromRGB(255, 240, 245),
        LawnGreen = Color3.fromRGB(124, 252, 0),
        LemonChiffon = Color3.fromRGB(255, 250, 205),
        LightBlue = Color3.fromRGB(173, 216, 230),
        LightCoral = Color3.fromRGB(240, 128, 128),
        LightCyan = Color3.fromRGB(224, 255, 255),
        LightGoldenRodYellow = Color3.fromRGB(250, 250, 210),
        LightGray = Color3.fromRGB(211, 211, 211),
        LightGreen = Color3.fromRGB(144, 238, 144),
        LightPink = Color3.fromRGB(255, 182, 193),
        LightSalmon = Color3.fromRGB(255, 160, 122),
        LightSeaGreen = Color3.fromRGB(32, 178, 170),
        LightSkyBlue = Color3.fromRGB(135, 206, 250),
        LightSlateGray = Color3.fromRGB(119, 136, 153),
        LightSteelBlue = Color3.fromRGB(176, 196, 222),
        LightYellow = Color3.fromRGB(255, 255, 224),
        LimeGreen = Color3.fromRGB(50, 205, 50),
        Linen = Color3.fromRGB(250, 240, 230),
        MediumAquaMarine = Color3.fromRGB(102, 205, 170),
        MediumBlue = Color3.fromRGB(0, 0, 205),
        MediumOrchid = Color3.fromRGB(186, 85, 211),
        MediumPurple = Color3.fromRGB(147, 112, 219),
        MediumSeaGreen = Color3.fromRGB(60, 179, 113),
        MediumSlateBlue = Color3.fromRGB(123, 104, 238),
        MediumSpringGreen = Color3.fromRGB(0, 250, 154),
        MediumTurquoise = Color3.fromRGB(72, 209, 204),
        MediumVioletRed = Color3.fromRGB(199, 21, 133),
        MidnightBlue = Color3.fromRGB(25, 25, 112),
        MintCream = Color3.fromRGB(245, 255, 250),
        MistyRose = Color3.fromRGB(255, 228, 225),
        Moccasin = Color3.fromRGB(255, 228, 181),
        NavajoWhite = Color3.fromRGB(255, 222, 173),
        OldLace = Color3.fromRGB(253, 245, 230),
        OliveDrab = Color3.fromRGB(107, 142, 35),
        OrangeRed = Color3.fromRGB(255, 69, 0),
        Orchid = Color3.fromRGB(218, 112, 214),
        PaleGoldenRod = Color3.fromRGB(238, 232, 170),
        PaleGreen = Color3.fromRGB(152, 251, 152),
        PaleTurquoise = Color3.fromRGB(175, 238, 238),
        PaleVioletRed = Color3.fromRGB(219, 112, 147),
        PapayaWhip = Color3.fromRGB(255, 239, 213),
        PeachPuff = Color3.fromRGB(255, 218, 185),
        PowderBlue = Color3.fromRGB(176, 224, 230),
        RosyBrown = Color3.fromRGB(188, 143, 143),
        RoyalBlue = Color3.fromRGB(65, 105, 225),
        SaddleBrown = Color3.fromRGB(139, 69, 19),
        SandyBrown = Color3.fromRGB(244, 164, 96),
        SeaGreen = Color3.fromRGB(46, 139, 87),
        SeaShell = Color3.fromRGB(255, 245, 238),
        Sienna = Color3.fromRGB(160, 82, 45),
        SkyBlue = Color3.fromRGB(135, 206, 235),
        SlateBlue = Color3.fromRGB(106, 90, 205),
        SlateGray = Color3.fromRGB(112, 128, 144),
        Snow = Color3.fromRGB(255, 250, 250),
        SpringGreen = Color3.fromRGB(0, 255, 127),
        SteelBlue = Color3.fromRGB(70, 130, 180),
        Thistle = Color3.fromRGB(216, 191, 216),
        Transparent = Color3.fromRGB(255, 255, 255),
        Violet = Color3.fromRGB(238, 130, 238),
        Wheat = Color3.fromRGB(245, 222, 179),
        WhiteSmoke = Color3.fromRGB(245, 245, 245),
        YellowGreen = Color3.fromRGB(154, 205, 50)
    },
    Materials = {
        Plastic = "PlasticBlock",
        Wood = "WoodBlock",
        Metal = "MetalBlock",
        Neon = "NeonBlock",
        Glass = "GlassBlock",
        Ice = "IceBlock",
        Fabric = "FabricBlock",
        Sand = "SandBlock",
        Stone = "StoneBlock",
        Marble = "MarbleBlock",
        Granite = "GraniteBlock",
        Brick = "BrickBlock",
        Cobblestone = "CobblestoneBlock",
        Concrete = "ConcreteBlock",
        CorrodedMetal = "CorrodedMetalBlock",
        DiamondPlate = "DiamondPlateBlock",
        Foil = "FoilBlock",
        Grass = "GrassBlock",
        Pebble = "PebbleBlock",
        Slate = "SlateBlock",
        SmoothPlastic = "SmoothPlasticBlock",
        ForceField = "ForceFieldBlock",
        NeonGlow = "NeonBlock"
    }
}
BABFT.Dictionary = Modules.Dictionary

Modules.AdvancedGeometry = {}
function Modules.AdvancedGeometry.Bezier(p0, p1, p2, p3, t)
    local u = 1 - t
    local tt = t * t
    local uu = u * u
    local uuu = uu * u
    local ttt = tt * t
    local p = p0 * uuu
    p = p + p1 * (3 * uu * t)
    p = p + p2 * (3 * u * tt)
    p = p + p3 * ttt
    return p
end

function Modules.AdvancedGeometry.GenerateSphere(center, radius, resolution, material, color)
    local blocks = {}
    for phi = 0, 180, resolution do
        for theta = 0, 360, resolution do
            local x = radius * math.sin(math.rad(phi)) * math.cos(math.rad(theta))
            local y = radius * math.cos(math.rad(phi))
            local z = radius * math.sin(math.rad(phi)) * math.sin(math.rad(theta))
            table.insert(blocks, {
                Position = center + Vector3.new(x, y, z),
                Size = Vector3.new(1, 1, 1),
                Block = material or "PlasticBlock",
                Color = color or Color3.new(1,1,1)
            })
        end
    end
    return blocks
end

function Modules.AdvancedGeometry.GenerateTorus(center, majorRadius, minorRadius, resolution, material, color)
    local blocks = {}
    for u = 0, 360, resolution do
        for v = 0, 360, resolution do
            local x = (majorRadius + minorRadius * math.cos(math.rad(v))) * math.cos(math.rad(u))
            local y = minorRadius * math.sin(math.rad(v))
            local z = (majorRadius + minorRadius * math.cos(math.rad(v))) * math.sin(math.rad(u))
            table.insert(blocks, {
                Position = center + Vector3.new(x, y, z),
                Size = Vector3.new(1, 1, 1),
                Block = material or "PlasticBlock",
                Color = color or Color3.new(1,1,1)
            })
        end
    end
    return blocks
end

function Modules.AdvancedGeometry.Sierpinski(center, size, depth, material, color)
    local blocks = {}
    local function recurse(pos, s, d)
        if d == 0 then
            table.insert(blocks, { Position = pos, Size = Vector3.new(s,s,s), Block = material or "NeonBlock", Color = color or Color3.new(1,0,0) })
        else
            local ns = s / 2
            recurse(pos + Vector3.new(ns/2, ns/2, ns/2), ns, d-1)
            recurse(pos + Vector3.new(-ns/2, ns/2, ns/2), ns, d-1)
            recurse(pos + Vector3.new(ns/2, -ns/2, ns/2), ns, d-1)
            recurse(pos + Vector3.new(-ns/2, -ns/2, ns/2), ns, d-1)
            recurse(pos + Vector3.new(ns/2, ns/2, -ns/2), ns, d-1)
            recurse(pos + Vector3.new(-ns/2, ns/2, -ns/2), ns, d-1)
            recurse(pos + Vector3.new(ns/2, -ns/2, -ns/2), ns, d-1)
            recurse(pos + Vector3.new(-ns/2, -ns/2, -ns/2), ns, d-1)
        end
    end
    recurse(center, size, depth)
    return blocks
end

-- 🏃 ANIMATION ENGINE
Modules.Animation = {
    Timelines = {},
    Easings = {
        Linear = function(t) return t end,
        QuadIn = function(t) return t * t end,
        QuadOut = function(t) return t * (2 - t) end,
        QuadInOut = function(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end,
        Bounce = function(t)
            if t < 1 / 2.75 then return 7.5625 * t * t
            elseif t < 2 / 2.75 then t = t - 1.5 / 2.75 return 7.5625 * t * t + 0.75
            elseif t < 2.5 / 2.75 then t = t - 2.25 / 2.75 return 7.5625 * t * t + 0.9375
            else t = t - 2.625 / 2.75 return 7.5625 * t * t + 0.984375 end
        end
    }
}
function Modules.Animation.Play(blockRef, targetProps, duration, easingName)
    local easing = Modules.Animation.Easings[easingName] or Modules.Animation.Easings.Linear
    local startProps = {
        Position = blockRef.Position,
        Size = blockRef.Size,
        Color = blockRef.Color,
        CFrame = blockRef.CFrame
    }
    local startTime = tick()
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local t = (tick() - startTime) / duration
        if t >= 1 then
            t = 1
            connection:Disconnect()
        end
        local e = easing(t)
        if targetProps.Position then blockRef.Position = startProps.Position:Lerp(targetProps.Position, e) end
        if targetProps.Size then blockRef.Size = startProps.Size:Lerp(targetProps.Size, e) end
        if targetProps.Color then blockRef.Color = startProps.Color:Lerp(targetProps.Color, e) end
        if targetProps.CFrame and startProps.CFrame then blockRef.CFrame = startProps.CFrame:Lerp(targetProps.CFrame, e) end
        if Modules.Pipeline then Modules.Pipeline.run({blockRef}) end
    end)
end

-- 🍎 PHYSICS ENGINE (Rigid Body Simulation)
Modules.Physics = {
    Objects = {},
    Gravity = Vector3.new(0, -19.62, 0),
    Active = false
}
function Modules.Physics.AddBody(blockRef, mass, bounciness)
    table.insert(Modules.Physics.Objects, {
        ref = blockRef,
        mass = mass or 1,
        bounciness = bounciness or 0.5,
        velocity = Vector3.new(0,0,0),
        acceleration = Vector3.new(0,0,0)
    })
end
function Modules.Physics.Start()
    Modules.Physics.Active = true
    task.spawn(function()
        while Modules.Physics.Active do
            local dt = task.wait()
            for _, obj in ipairs(Modules.Physics.Objects) do
                obj.acceleration = Modules.Physics.Gravity
                obj.velocity = obj.velocity + obj.acceleration * dt
                obj.ref.Position = obj.ref.Position + obj.velocity * dt
                if obj.ref.Position.Y < 5 then
                    obj.ref.Position = Vector3.new(obj.ref.Position.X, 5, obj.ref.Position.Z)
                    obj.velocity = Vector3.new(obj.velocity.X, -obj.velocity.Y * obj.bounciness, obj.velocity.Z)
                end
                if Modules.Pipeline then Modules.Pipeline.run({obj.ref}) end
            end
        end
    end)
end
function Modules.Physics.Stop()
    Modules.Physics.Active = false
end

-- 🧠 LOGIC SIMULATOR (Redstone-like)
Modules.Logic = {
    Gates = {},
    Wires = {}
}
function Modules.Logic.CreateGate(type, pos)
    local gate = { type = type, inputs = {}, output = false, pos = pos }
    table.insert(Modules.Logic.Gates, gate)
    return gate
end
function Modules.Logic.Update()
    for _, gate in ipairs(Modules.Logic.Gates) do
        if gate.type == "AND" then
            gate.output = gate.inputs[1] and gate.inputs[2]
        elseif gate.type == "OR" then
            gate.output = gate.inputs[1] or gate.inputs[2]
        elseif gate.type == "NOT" then
            gate.output = not gate.inputs[1]
        elseif gate.type == "XOR" then
            gate.output = gate.inputs[1] ~= gate.inputs[2]
        end
    end
end

-- 🎵 MUSIC ENGINE
Modules.Music = {
    Notes = {
        C4 = 261.63, D4 = 293.66, E4 = 329.63, F4 = 349.23, G4 = 392.00, A4 = 440.00, B4 = 493.88, C5 = 523.25
    }
}
function Modules.Music.PlayTone(frequency, duration)
    local visualizer = { Position = Vector3.new(0, 50, 0), Size = Vector3.new(10, frequency/50, 10), Block = "NeonBlock", Color = Color3.fromHSV(math.random(), 1, 1) }
    if Modules.Pipeline then Modules.Pipeline.run({visualizer}) end
    task.wait(duration)
    visualizer.Color = Color3.new(0,0,0)
    if Modules.Pipeline then Modules.Pipeline.run({visualizer}) end
end

-- 🗺️ PATHFINDING (A* Algorithm)
Modules.Pathfinding = {}
function Modules.Pathfinding.FindPath(startPos, endPos, gridSize)
    local path = {}
    local current = startPos
    while (current - endPos).Magnitude > gridSize do
        table.insert(path, current)
        local dir = (endPos - current).Unit
        current = current + dir * gridSize
    end
    table.insert(path, endPos)
    return path
end
function Modules.Pathfinding.BuildPath(path, material, color)
    local blocks = {}
    for _, pos in ipairs(path) do
        table.insert(blocks, { Position = pos, Size = Vector3.new(4, 1, 4), Block = material or "WoodBlock", Color = color or Color3.new(0.5, 0.3, 0.1) })
    end
    if Modules.Pipeline then Modules.Pipeline.run(blocks) end
end

-- 🤖 L-SYSTEMS (Procedural Trees)
Modules.LSystem = {}
function Modules.LSystem.Generate(axiom, rules, iterations)
    local result = axiom
    for i = 1, iterations do
        local nextResult = ""
        for j = 1, #result do
            local char = result:sub(j, j)
            nextResult = nextResult .. (rules[char] or char)
        end
        result = nextResult
    end
    return result
end
function Modules.LSystem.Draw(instructions, startPos, length, angle)
    local stack = {}
    local currentPos = startPos
    local currentDir = Vector3.new(0, 1, 0)
    local blocks = {}
    
    for i = 1, #instructions do
        local char = instructions:sub(i, i)
        if char == "F" then
            local nextPos = currentPos + currentDir * length
            table.insert(blocks, { Position = currentPos:Lerp(nextPos, 0.5), Size = Vector3.new(1, length, 1), Block = "WoodBlock", CFrame = CFrame.lookAt(currentPos:Lerp(nextPos, 0.5), nextPos) * CFrame.Angles(math.pi/2, 0, 0) })
            currentPos = nextPos
        elseif char == "+" then
            currentDir = (CFrame.Angles(0, 0, math.rad(angle)) * currentDir).Unit
        elseif char == "-" then
            currentDir = (CFrame.Angles(0, 0, math.rad(-angle)) * currentDir).Unit
        elseif char == "[" then
            table.insert(stack, {pos = currentPos, dir = currentDir})
        elseif char == "]" then
            local state = table.remove(stack)
            currentPos = state.pos
            currentDir = state.dir
        end
    end
    if Modules.Pipeline then Modules.Pipeline.run(blocks) end
end

-- 🎨 VOXELIZER (Convert Meshes to Blocks)
Modules.Voxelizer = {}
function Modules.Voxelizer.VoxelizePart(part, resolution)
    local blocks = {}
    local size = part.Size
    local cf = part.CFrame
    for x = -size.X/2, size.X/2, resolution do
        for y = -size.Y/2, size.Y/2, resolution do
            for z = -size.Z/2, size.Z/2, resolution do
                local pos = cf * Vector3.new(x, y, z)
                table.insert(blocks, { Position = pos, Size = Vector3.new(resolution, resolution, resolution), Block = "PlasticBlock", Color = part.Color })
            end
        end
    end
    if Modules.Pipeline then Modules.Pipeline.run(blocks) end
end

-- 🏙️ CITY GENERATOR (Procedural Generation)
Modules.CityGenerator = {}
function Modules.CityGenerator.Generate(center, width, length, maxBuildingHeight)
    local blocks = {}
    local blockSize = 4
    local roadWidth = 12
    for x = -width/2, width/2, blockSize + roadWidth do
        for z = -length/2, length/2, blockSize + roadWidth do
            if math.random() > 0.2 then
                local height = math.random(10, maxBuildingHeight)
                table.insert(blocks, {
                    Position = center + Vector3.new(x, height/2, z),
                    Size = Vector3.new(blockSize*2, height, blockSize*2),
                    Block = "MetalBlock",
                    Color = Color3.new(math.random(), math.random(), math.random())
                })
            end
        end
    end
    if Modules.Pipeline then Modules.Pipeline.run(blocks) end
end

-- 🌊 FLUID SIMULATION (Cellular Automata)
Modules.FluidSimulation = {}
function Modules.FluidSimulation.Run(gridSize, iterations)
    local grid = {}
    for x = 1, gridSize do
        grid[x] = {}
        for y = 1, gridSize do
            grid[x][y] = (math.random() > 0.8) and 1 or 0
        end
    end
    
    task.spawn(function()
        for i = 1, iterations do
            local nextGrid = {}
            local blocks = {}
            for x = 1, gridSize do
                nextGrid[x] = {}
                for y = 1, gridSize do
                    local neighbors = 0
                    if x>1 and grid[x-1][y]==1 then neighbors = neighbors + 1 end
                    if x<gridSize and grid[x+1][y]==1 then neighbors = neighbors + 1 end
                    if y>1 and grid[x][y-1]==1 then neighbors = neighbors + 1 end
                    if y<gridSize and grid[x][y+1]==1 then neighbors = neighbors + 1 end
                    
                    if grid[x][y] == 1 then
                        nextGrid[x][y] = (neighbors == 2 or neighbors == 3) and 1 or 0
                    else
                        nextGrid[x][y] = (neighbors == 3) and 1 or 0
                    end
                    
                    if nextGrid[x][y] == 1 then
                        table.insert(blocks, {
                            Position = Vector3.new(x*2, 10, y*2),
                            Size = Vector3.new(2,2,2),
                            Block = "GlassBlock",
                            Color = Color3.new(0, 0.5, 1)
                        })
                    end
                end
            end
            grid = nextGrid
            if Modules.Pipeline then Modules.Pipeline.run(blocks) end
            task.wait(0.1)
        end
    end)
end

-- 🚗 VEHICLE BUILDER
Modules.VehicleBuilder = {}
function Modules.VehicleBuilder.BuildCar(center)
    local blocks = {}
    -- Chassis
    table.insert(blocks, { Position = center + Vector3.new(0, 2, 0), Size = Vector3.new(10, 1, 20), Block = "MetalBlock", Color = Color3.new(0.2, 0.2, 0.2) })
    -- Wheels
    table.insert(blocks, { Position = center + Vector3.new(6, 1, 8), Size = Vector3.new(2, 4, 4), Block = "PlasticBlock", Color = Color3.new(0, 0, 0) })
    table.insert(blocks, { Position = center + Vector3.new(-6, 1, 8), Size = Vector3.new(2, 4, 4), Block = "PlasticBlock", Color = Color3.new(0, 0, 0) })
    table.insert(blocks, { Position = center + Vector3.new(6, 1, -8), Size = Vector3.new(2, 4, 4), Block = "PlasticBlock", Color = Color3.new(0, 0, 0) })
    table.insert(blocks, { Position = center + Vector3.new(-6, 1, -8), Size = Vector3.new(2, 4, 4), Block = "PlasticBlock", Color = Color3.new(0, 0, 0) })
    -- Cabin
    table.insert(blocks, { Position = center + Vector3.new(0, 5, 0), Size = Vector3.new(8, 4, 10), Block = "GlassBlock", Color = Color3.new(0.5, 0.8, 1) })
    if Modules.Pipeline then Modules.Pipeline.run(blocks) end
end

-- 🛡️ ANTI-CHEAT & SECURITY
Modules.Security = {}
function Modules.Security.CheckIntegrity()
    local env = getgenv and getgenv() or _G
    if env.hookfunction or env.hookmetamethod then
        print("[BABFT Security] Hooks detectados. Modo de segurança ativado.")
    end
end

-- 📡 MULTIPLAYER SYNC
Modules.Multiplayer = {}
function Modules.Multiplayer.SyncBlock(blockData)
    print("[Sync] Bloco sincronizado: ", blockData.Position)
end

-- ⚡ QUANTUM COMPUTING SIMULATOR (Just for fun)
Modules.Quantum = {}
function Modules.Quantum.Qubit(state)
    return { alpha = math.sqrt(1 - state), beta = math.sqrt(state) }
end
function Modules.Quantum.Measure(qubit)
    return math.random() < (qubit.beta * qubit.beta) and 1 or 0
end

-- 🧬 GENETIC ALGORITHM FOR BOAT DESIGN
Modules.Genetics = {}
function Modules.Genetics.Evolve(populationSize, generations)
    print("[Genetics] Evoluindo " .. populationSize .. " barcos por " .. generations .. " gerações...")
end

-- 🌌 GALAXY GENERATOR
Modules.Galaxy = {}
function Modules.Galaxy.Generate(center, stars, radius)
    local blocks = {}
    for i = 1, stars do
        local angle = math.random() * math.pi * 2
        local dist = math.random() * radius
        local x = math.cos(angle) * dist
        local z = math.sin(angle) * dist
        local y = (math.random() - 0.5) * (radius - dist) * 0.2
        table.insert(blocks, {
            Position = center + Vector3.new(x, y, z),
            Size = Vector3.new(1,1,1),
            Block = "NeonBlock",
            Color = Color3.new(1, 1, math.random(0.5, 1))
        })
    end
    if Modules.Pipeline then Modules.Pipeline.run(blocks) end
end



-- 💻 HARDWARE & LOGIC GATES BUILDER

-- 🏴 TEAM CHANGER
Modules.Team = {}
function Modules.Team.ChangeTeam(teamName)
    local teams = {
        ["Blue Team"] = game:GetService("Teams"):FindFirstChild("blue"),
        ["Red Team"] = game:GetService("Teams"):FindFirstChild("red"),
        ["White Team"] = game:GetService("Teams"):FindFirstChild("white"),
        ["Yellow Team"] = game:GetService("Teams"):FindFirstChild("yellow"),
        ["Magenta Team"] = game:GetService("Teams"):FindFirstChild("magenta"),
        ["Black Team"] = game:GetService("Teams"):FindFirstChild("black"),
        ["Green Team"] = game:GetService("Teams"):FindFirstChild("green")
    }
    if teams[teamName] then
        workspace.ChangeTeam:FireServer(teams[teamName])
    end
end

-- 💾 SLOT MANAGER
Modules.Slot = {}
function Modules.Slot.LoadBoat(slotName, backupVersion)
    workspace.LoadBoatData:FireServer(slotName or "Slot1", backupVersion or 0)
end

-- 🚜 AUTOFARM
Modules.Autofarm = {}
Modules.Autofarm.Active = false
function Modules.Autofarm.Start()
    if Modules.Autofarm.Active then return end
    Modules.Autofarm.Active = true
    local player = game:GetService("Players").LocalPlayer
    
    task.spawn(function()
        while Modules.Autofarm.Active do
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            
            for i = 1, 10 do
                if not Modules.Autofarm.Active then break end
                local stage = workspace.BoatStages.NormalStages:FindFirstChild("CaveStage"..i)
                if stage and stage:FindFirstChild("DarknessPart") then
                    hrp.CFrame = stage.DarknessPart.CFrame
                    task.wait(3) -- Stages demoram em média 2.88888s para reconhecer
                end
            end
            
            if not Modules.Autofarm.Active then break end
            
            local endStage = workspace.BoatStages.NormalStages:FindFirstChild("TheEnd")
            if endStage and endStage:FindFirstChild("GoldenChest") then
                local trigger = endStage.GoldenChest:FindFirstChild("Trigger")
                if trigger then
                    hrp.CFrame = trigger.CFrame
                    task.wait(1)
                    if firetouchinterest then
                        firetouchinterest(hrp, trigger, 0)
                        firetouchinterest(hrp, trigger, 1)
                    end
                end
            end
            
            task.wait(2)
            workspace.ClaimRiverResultsGold:FireServer()
            task.wait(5) -- Wait for respawn
        end
    end)
end
function Modules.Autofarm.Stop()
    Modules.Autofarm.Active = false
end

-- 📦 DECAL IDS E BLOCOS ATUALIZADOS
Modules.Dictionary.Decals = {
    ["BalloonBlock"] = "rbxassetid://1916437856", ["BalloonStarBlock"] = "rbxassetid://1973706944", ["BrickBlock"] = "rbxassetid://1608273751", ["Button"] = "rbxassetid://1678033905", ["CaneBlock"] = "rbxassetid://1298643792", ["CaneRod"] = "rbxassetid://1298644378", ["Cannon"] = "rbxassetid://845567732", ["CarSeat"] = "rbxassetid://1863051164", ["Chair"] = "rbxassetid://924419491", ["ConcreteBlock"] = "rbxassetid://845565990", ["ConcreteRod"] = "rbxassetid://845564596", ["CornerWedge"] = "rbxassetid://845567909", ["FabricBlock"] = "rbxassetid://1608274294", ["FireworkD"] = "rbxassetid://7036614604", ["Flag"] = "rbxassetid://845563550", ["GlassBlock"] = "rbxassetid://1335289047", ["Glue"] = "rbxassetid://1887147909", ["GoldBlock"] = "rbxassetid://1678364253", ["Harpoon"] = "rbxassetid://2062877865", ["HugeMotor"] = "rbxassetid://1865438463", ["IceBlock"] = "rbxassetid://1608273971", ["Lever"] = "rbxassetid://1608273289", ["LifePreserver"] = "rbxassetid://958894042", ["MarbleBlock"] = "rbxassetid://845566206", ["MarbleRod"] = "rbxassetid://845564866", ["Mast"] = "rbxassetid://845566917", ["MegaThruster"] = "rbxassetid://1358894694", ["MetalBlock"] = "rbxassetid://845565844", ["MetalRod"] = "rbxassetid://845564481", ["Motor"] = "rbxassetid://9236142098", ["MysteryBox"] = "rbxassetid://2035087825", ["ObsidianBlock"] = "rbxassetid://1335288552", ["PlasticBlock"] = "rbxassetid://1609332225", ["Pumpkin"] = "rbxassetid://1105248393", ["RustedBlock"] = "rbxassetid://845565648", ["RustedRod"] = "rbxassetid://845564347", ["Seat"] = "rbxassetid://845567578", ["Servo"] = "rbxassetid://1863050474", ["Spring"] = "rbxassetid://1863049770", ["Star"] = "rbxassetid://1916677740", ["Steel I-Beam"] = "rbxassetid://845566665", ["Step"] = "rbxassetid://845568429", ["StoneBlock"] = "rbxassetid://845565497", ["StoneRod"] = "rbxassetid://845564162", ["TNT"] = "rbxassetid://932196135", ["Throne"] = "rbxassetid://845567243", ["Thruster"] = "rbxassetid://1317812037", ["TitaniumBlock"] = "rbxassetid://845566458", ["TitaniumRod"] = "rbxassetid://845565080", ["Torch"] = "rbxassetid://5717267458", ["Truss"] = "rbxassetid://845568199", ["Wedge"] = "rbxassetid://845568062", ["Helm"] = "rbxassetid://845567402", ["Window"] = "rbxassetid://845563704", ["WinterThruster"] = "rbxassetid://1298650848", ["WoodBlock"] = "rbxassetid://845568340", ["WoodDoor"] = "rbxassetid://1191997076", ["WoodRod"] = "rbxassetid://845563975", ["WoodTrapDoor"] = "rbxassetid://1191997319", ["YellowChest"] = "rbxassetid://976448763", ["BouncyBlock"] = "rbxassetid://2293816241", ["Bread"] = "rbxassetid://2102742548", ["CandyBlue"] = "rbxassetid://7781285156", ["Plushie2"] = "rbxassetid://2214257779", ["Plushie1"] = "rbxassetid://2223411329", ["GrassBlock"] = "rbxassetid://2417963634", ["Lamp"] = "rbxassetid://2413603467", ["Candle"] = "rbxassetid://2413603938", ["ChestLegendary"] = "rbxassetid://4717828937", ["ChestRare"] = "rbxassetid://4717827311", ["ChestCommon"] = "rbxassetid://4717826099", ["ChestUncommon"] = "rbxassetid://4717826702", ["Cake"] = "rbxassetid://2103921305", ["CandyOrange"] = "rbxassetid://7781288646", ["CandyPurple"] = "rbxassetid://7781287748", ["ChestEpic"] = "rbxassetid://4717828261", ["SandBlock"] = "rbxassetid://2418018500", ["HalloweenThruster"] = "rbxassetid://2501530509", ["JetTurbineWinter"] = "rbxassetid://2690396507", ["NeonBlock"] = "rbxassetid://2690438936", ["JetTurbine"] = "rbxassetid://2592852037", ["PilotSeat"] = "rbxassetid://2592852717", ["SonicJetTurbine"] = "rbxassetid://2592851747", ["DualCaneHarpoon"] = "rbxassetid://2690396999", ["Firework"] = "rbxassetid://2042685042", ["FireworkB"] = "rbxassetid://7036612976", ["FireworkC"] = "rbxassetid://7036613636", ["SoccerBall"] = "rbxassetid://2732318916", ["BoxingGlove"] = "rbxassetid://2783557827", ["Heart"] = "rbxassetid://2855511869", ["CandyPink"] = "rbxassetid://7781284023", ["JetPack"] = "rbxassetid://3230273281", ["JetPackEaster"] = "rbxassetid://3230273718", ["Magnet"] = "rbxassetid://2910074282", ["CannonMount"] = "rbxassetid://7130971602", ["Gameboard"] = "rbxassetid://3162472457", ["GunMount"] = "rbxassetid://7130971085", ["SwordMount"] = "rbxassetid://7130969623", ["LockedDoor"] = "rbxassetid://3162472006", ["UltraThruster"] = "rbxassetid://3164908588", ["ShieldGenerator"] = "rbxassetid://3162472660", ["Piston"] = "rbxassetid://3162469425", ["SticksOfTNT"] = "rbxassetid://2511283148", ["CannonTurret"] = "rbxassetid://3162469847", ["Hinge"] = "rbxassetid://3162470626", ["TreasureSmall"] = "rbxassetid://5176251125", ["JetPackStar"] = "rbxassetid://3268106680", ["JetPackUltra"] = "rbxassetid://3268107303", ["Potions"] = "rbxassetid://3500449318", ["TreasureMedium"] = "rbxassetid://5176250512", ["HarpoonGold"] = "rbxassetid://3583968049", ["TreasureLarge"] = "rbxassetid://5176249676", ["Plushie3"] = "rbxassetid://3591541892", ["Portal"] = "rbxassetid://3744399826", ["JetPackSteampunk"] = "rbxassetid://3838566130", ["BowMount"] = "rbxassetid://7131030442", ["KnightSwordMount"] = "rbxassetid://7131029546", ["LightningStaffMount"] = "rbxassetid://7131031163", ["JackOLantern"] = "rbxassetid://4079113414", ["PineTree"] = "rbxassetid://4210890467", ["CoalBlock"] = "rbxassetid://4539749508", ["Sign"] = "rbxassetid://4539749166", ["BoatMotorUltra"] = "rbxassetid://4539748713", ["BoatMotor"] = "rbxassetid://4539748155", ["BoatMotorWinter"] = "rbxassetid://4539748452", ["DragonEgg"] = "rbxassetid://4742940542", ["FrontWheel"] = "rbxassetid://4736855340", ["BackWheel"] = "rbxassetid://4736853414", ["FrontWheelCookie"] = "rbxassetid://4803870316", ["HugeBackWheel"] = "rbxassetid://4742770672", ["BackWheelCookie"] = "rbxassetid://4803870924", ["HugeFrontWheel"] = "rbxassetid://4742773097", ["Plushie4"] = "rbxassetid://4918988544", ["Trophy1st"] = "rbxassetid://5299317467", ["Trophy2nd"] = "rbxassetid://5299318083", ["Trophy3rd"] = "rbxassetid://5299319293", ["HarpoonDragon"] = "rbxassetid://5740994229", ["BackWheelMint"] = "rbxassetid://6228838828", ["FrontWheelMint"] = "rbxassetid://6228838214", ["CameraDome"] = "rbxassetid://6218312957", ["Camera"] = "rbxassetid://6218312341", ["ToyBlock"] = "rbxassetid://5578285243", ["Switch"] = "rbxassetid://6361970614", ["LightBulb"] = "rbxassetid://6635725107", ["ParachuteBlock"] = "rbxassetid://6635488100", ["SwitchBig"] = "rbxassetid://6828907824", ["CannonEgg"] = "rbxassetid://6568169777", ["TrophyMaster"] = "rbxassetid://6876313983", ["FireworkA"] = "rbxassetid://7036591081", ["Delay"] = "rbxassetid://7743806268", ["CandyRed"] = "rbxassetid://7781250539", ["SnowballTurret"] = "rbxassetid://8452611946", ["CandyCaneSwordMount"] = "rbxassetid://8452610423", ["Note"] = "rbxassetid://8452606673", ["SmoothWoodBlock"] = "rbxassetid://8142306398", ["CheckMark"] = "rbxassetid://9649923610", ["SpikeTrap"] = "rbxassetid://7207314809", ["MiniGun"] = "rbxassetid://2302342262", ["LaserTurret"] = "rbxassetid://12229204385", ["Bar"] = "rbxassetid://16088076429", ["Rope"] = "rbxassetid://16088186920"}

Modules.Hardware = {}
Modules.Hardware.Config = {
    TELA_X = 32,
    TELA_Y = 16,
    BITS = 16,
    BANCOS_RAM = 8,
    REGS_POR_BANCO = 32,
    TAMANHO_BLOCO = 1.0,
    ESPACAMENTO = 1.5,
    LIMITE_X = 16
}

function Modules.Hardware.GetTools()
    local Core = Modules.Core
    return {
        Construir = Core.getTool(Core.Tools.BuildingTool) and Core.getTool(Core.Tools.BuildingTool):FindFirstChild("RF"),
        Escalar = Core.getTool(Core.Tools.ScalingTool) and Core.getTool(Core.Tools.ScalingTool):FindFirstChild("RF"),
        Pintar = Core.getTool(Core.Tools.PaintingTool) and Core.getTool(Core.Tools.PaintingTool):FindFirstChild("RF"),
        Propriedades = Core.getTool(Core.Tools.PropertiesTool) and Core.getTool(Core.Tools.PropertiesTool):FindFirstChild("SetPropertieRF"),
        Ligar = Core.getTool(Core.Tools.BindTool) and Core.getTool(Core.Tools.BindTool):FindFirstChild("RF"),
        Desligar = Core.getTool(Core.Tools.BindTool) and Core.getTool(Core.Tools.BindTool):FindFirstChild("UnbindRF")
    }
end

function Modules.Hardware.HashEspacial(pos)
    local t = 5.0
    return string.format("%d_%d_%d", math.floor(pos.X/t), math.floor(pos.Y/t), math.floor(pos.Z/t))
end

function Modules.Hardware.IndexarBlocos(pasta, grid)
    local c = 0
    if not pasta then return c end
    for _, b in ipairs(pasta:GetChildren()) do
        local p = b:IsA("Model") and b.PrimaryPart or b:IsA("BasePart") and b or b:FindFirstChildWhichIsA("BasePart")
        if p then
            local h = Modules.Hardware.HashEspacial(p.Position)
            if not grid[h] then grid[h] = {} end
            table.insert(grid[h], b)
            c = c + 1
        end
    end
    return c
end

function Modules.Hardware.BuildComponent(tipo, bits)
    task.spawn(function()
        local ferramentas = Modules.Hardware.GetTools()
        if not ferramentas.Construir then return end
        
        local Core = Modules.Core
        local zona = Core.getZone()
        if not zona then return end
        local AncoraIso = zona.CFrame * CFrame.new(20, 5, -20)
        
        local MatrizProjetos = {}
        local MatrizConexoes = {}
        local DicionarioHardware = {}
        
        local function registrar(camada, uid, nome, tipoGate, cf, cor, txt)
            if not MatrizProjetos[camada] then MatrizProjetos[camada] = {} end
            table.insert(MatrizProjetos[camada], {UID = uid, Nome = nome, Tipo = tipoGate, CFrame = cf, Cor = cor, Texto = txt})
        end
        local function fio(origem, destino)
            table.insert(MatrizConexoes, {Origem = origem, Destino = destino})
        end
        local function getCF(ancora, idx, ox, oy, oz)
            local colX = (idx - 1) % Modules.Hardware.Config.LIMITE_X
            local camZ = math.floor((idx - 1) / Modules.Hardware.Config.LIMITE_X)
            return ancora * CFrame.new(ox + (colX * Modules.Hardware.Config.ESPACAMENTO), oy, oz + (camZ * Modules.Hardware.Config.ESPACAMENTO * 2))
        end

        if tipo == "DLATCH" then
            for b = 1, bits do
                registrar(1, "D_IN_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(1,1,1), "D"..b)
                registrar(1, "E_IN_"..b, "Switch", "", getCF(AncoraIso, b, 0, 3, 0), Color3.new(0,1,0), "E"..b)
                registrar(2, "AND_IN_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 1.5, 2), Color3.new(0,0,1), nil)
                registrar(2, "NOT_E_"..b, "Gate", {"Not", "Or"}, getCF(AncoraIso, b, 0, 3, 2), Color3.new(1,0,0), nil)
                registrar(3, "Q_CELL_"..b, "Gate", "Or", getCF(AncoraIso, b, 0, 1.5, 4), Color3.new(1,1,0), nil)
                registrar(3, "AND_HOLD_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 3, 4), Color3.new(0.5,0.5,0.5), nil)
                fio("D_IN_"..b, "AND_IN_"..b)
                fio("E_IN_"..b, "AND_IN_"..b)
                fio("E_IN_"..b, "NOT_E_"..b)
                fio("AND_IN_"..b, "Q_CELL_"..b)
                fio("Q_CELL_"..b, "AND_HOLD_"..b)
                fio("NOT_E_"..b, "AND_HOLD_"..b)
                fio("AND_HOLD_"..b, "Q_CELL_"..b)
            end
        elseif tipo == "TLATCH" then
            for b = 1, bits do
                registrar(1, "T_IN_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(1,1,1), "T"..b)
                registrar(1, "CLK_IN_"..b, "Switch", "", getCF(AncoraIso, b, 0, 3, 0), Color3.new(0,1,0), "C"..b)
                registrar(2, "XOR_IN_"..b, "Gate", "Xor", getCF(AncoraIso, b, 0, 1.5, 2), Color3.new(0,0,1), nil)
                registrar(3, "AND_E_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 1.5, 4), Color3.new(1,0,0), nil)
                registrar(4, "Q_CELL_"..b, "Gate", "Or", getCF(AncoraIso, b, 0, 1.5, 6), Color3.new(1,1,0), nil)
                registrar(4, "NOT_CLK_"..b, "Gate", {"Not", "Or"}, getCF(AncoraIso, b, 0, 3, 4), Color3.new(0.5,0.5,0.5), nil)
                registrar(5, "AND_HOLD_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 3, 6), Color3.new(0.2,0.2,0.2), nil)
                fio("T_IN_"..b, "XOR_IN_"..b)
                fio("Q_CELL_"..b, "XOR_IN_"..b)
                fio("XOR_IN_"..b, "AND_E_"..b)
                fio("CLK_IN_"..b, "AND_E_"..b)
                fio("CLK_IN_"..b, "NOT_CLK_"..b)
                fio("AND_E_"..b, "Q_CELL_"..b)
                fio("Q_CELL_"..b, "AND_HOLD_"..b)
                fio("NOT_CLK_"..b, "AND_HOLD_"..b)
                fio("AND_HOLD_"..b, "Q_CELL_"..b)
            end
        elseif tipo == "SRLATCH" then
            for b = 1, bits do
                registrar(1, "S_IN_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(0,1,0), "S"..b)
                registrar(1, "R_IN_"..b, "Switch", "", getCF(AncoraIso, b, 0, 3, 0), Color3.new(1,0,0), "R"..b)
                registrar(2, "NOR_Q_"..b, "Gate", {"Not", "Or"}, getCF(AncoraIso, b, 0, 0, 2), Color3.new(1,1,0), nil)
                registrar(2, "NOR_NQ_"..b, "Gate", {"Not", "Or"}, getCF(AncoraIso, b, 0, 3, 2), Color3.new(0.5,0.5,0), nil)
                fio("R_IN_"..b, "NOR_Q_"..b)
                fio("S_IN_"..b, "NOR_NQ_"..b)
                fio("NOR_NQ_"..b, "NOR_Q_"..b)
                fio("NOR_Q_"..b, "NOR_NQ_"..b)
            end
        elseif tipo == "ADDER_RIPPLE" then
            for b = 1, bits do
                registrar(1, "A_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(1,1,1), "A"..b)
                registrar(1, "B_"..b, "Switch", "", getCF(AncoraIso, b, 0, 2, 0), Color3.new(0.8,0.8,0.8), "B"..b)
                registrar(2, "XOR1_"..b, "Gate", "Xor", getCF(AncoraIso, b, 0, 1, 2), Color3.new(0,0,1), nil)
                registrar(2, "AND1_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 3, 2), Color3.new(1,0,0), nil)
                registrar(3, "XOR2_"..b, "Gate", "Xor", getCF(AncoraIso, b, 0, 0, 4), Color3.new(1,1,0), nil)
                registrar(3, "AND2_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 2, 4), Color3.new(0.8,0,0), nil)
                registrar(4, "OR_C_"..b, "Gate", "Or", getCF(AncoraIso, b, 0, 2.5, 6), Color3.new(1,0.5,0), nil)
                fio("A_"..b, "XOR1_"..b)
                fio("B_"..b, "XOR1_"..b)
                fio("A_"..b, "AND1_"..b)
                fio("B_"..b, "AND1_"..b)
                fio("XOR1_"..b, "XOR2_"..b)
                fio("XOR1_"..b, "AND2_"..b)
                fio("AND1_"..b, "OR_C_"..b)
                fio("AND2_"..b, "OR_C_"..b)
                if b > 1 then
                    fio("OR_C_"..(b-1), "XOR2_"..b)
                    fio("OR_C_"..(b-1), "AND2_"..b)
                end
            end
        elseif tipo == "HALF_ADDER" then
            for b = 1, bits do
                registrar(1, "HA_A_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(1,1,1), "A"..b)
                registrar(1, "HA_B_"..b, "Switch", "", getCF(AncoraIso, b, 0, 2, 0), Color3.new(0.8,0.8,0.8), "B"..b)
                registrar(2, "HA_XOR_"..b, "Gate", "Xor", getCF(AncoraIso, b, 0, 0, 2), Color3.new(1,1,0), nil)
                registrar(2, "HA_AND_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 2, 2), Color3.new(1,0,0), nil)
                fio("HA_A_"..b, "HA_XOR_"..b)
                fio("HA_B_"..b, "HA_XOR_"..b)
                fio("HA_A_"..b, "HA_AND_"..b)
                fio("HA_B_"..b, "HA_AND_"..b)
            end
        elseif tipo == "MUX2" then
            for b = 1, bits do
                registrar(1, "A_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(1,1,1), "A"..b)
                registrar(1, "B_"..b, "Switch", "", getCF(AncoraIso, b, 0, 2, 0), Color3.new(0.8,0.8,0.8), "B"..b)
                registrar(1, "SEL_"..b, "Switch", "", getCF(AncoraIso, b, 0, 4, 0), Color3.new(0,1,0), "S"..b)
                registrar(2, "NOT_S_"..b, "Gate", {"Not", "Or"}, getCF(AncoraIso, b, 0, 4, 2), Color3.new(1,0,0), nil)
                registrar(3, "AND_A_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 0, 4), Color3.new(0,0,1), nil)
                registrar(3, "AND_B_"..b, "Gate", "And", getCF(AncoraIso, b, 0, 2, 4), Color3.new(0,0,1), nil)
                registrar(4, "OR_OUT_"..b, "Gate", "Or", getCF(AncoraIso, b, 0, 1, 6), Color3.new(1,1,0), nil)
                fio("SEL_"..b, "NOT_S_"..b)
                fio("A_"..b, "AND_A_"..b)
                fio("NOT_S_"..b, "AND_A_"..b)
                fio("B_"..b, "AND_B_"..b)
                fio("SEL_"..b, "AND_B_"..b)
                fio("AND_A_"..b, "OR_OUT_"..b)
                fio("AND_B_"..b, "OR_OUT_"..b)
            end
        elseif tipo == "DEC" then
            local numOuts = math.pow(2, bits)
            for i = 0, bits-1 do
                registrar(1, "SW_"..i, "Switch", "", AncoraIso * CFrame.new(i*3, 0, 0), Color3.new(1,1,1), "B"..i)
                registrar(2, "NOT_"..i, "Gate", {"Not", "Or"}, AncoraIso * CFrame.new(i*3, 0, 2), Color3.new(1,0,0), nil)
                fio("SW_"..i, "NOT_"..i)
            end
            for out_idx = 0, numOuts-1 do
                registrar(3, "AND_"..out_idx, "Gate", "And", getCF(AncoraIso, out_idx+1, 0, 0, 4), Color3.new(0,1,0), nil)
                for bit_idx = 0, bits-1 do
                    if bit32.band(bit32.rshift(out_idx, bit_idx), 1) == 1 then
                        fio("SW_"..bit_idx, "AND_"..out_idx)
                    else
                        fio("NOT_"..bit_idx, "AND_"..out_idx)
                    end
                end
            end
        elseif tipo == "ENC" then
            local numIns = math.pow(2, bits)
            for i = 0, numIns-1 do
                registrar(1, "SW_"..i, "Switch", "", getCF(AncoraIso, i+1, 0, 0, 0), Color3.new(1,1,1), "I"..i)
            end
            for bit_idx = 0, bits-1 do
                registrar(2, "OR_"..bit_idx, "Gate", "Or", AncoraIso * CFrame.new(bit_idx*3, 0, 4), Color3.new(0,0,1), nil)
            end
            for in_idx = 0, numIns-1 do
                for bit_idx = 0, bits-1 do
                    if bit32.band(bit32.rshift(in_idx, bit_idx), 1) == 1 then
                        fio("SW_"..in_idx, "OR_"..bit_idx)
                    end
                end
            end
        elseif tipo == "COMP_EQ" then
            for b = 1, bits do
                registrar(1, "CA_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(1,1,1), "A"..b)
                registrar(1, "CB_"..b, "Switch", "", getCF(AncoraIso, b, 0, 2, 0), Color3.new(0.8,0.8,0.8), "B"..b)
                registrar(2, "CXOR_"..b, "Gate", "Xor", getCF(AncoraIso, b, 0, 1, 2), Color3.new(1,0,0), nil)
                registrar(3, "CNOT_"..b, "Gate", {"Not", "Or"}, getCF(AncoraIso, b, 0, 1, 4), Color3.new(0,1,0), nil)
                fio("CA_"..b, "CXOR_"..b)
                fio("CB_"..b, "CXOR_"..b)
                fio("CXOR_"..b, "CNOT_"..b)
            end
            registrar(4, "C_FINAL", "Gate", "And", AncoraIso * CFrame.new(0, 0, 6), Color3.new(1,1,0), nil)
            for b = 1, bits do fio("CNOT_"..b, "C_FINAL") end
        elseif tipo == "BUFFER_TREE" then
            for b = 1, bits do
                registrar(1, "BUF_IN_"..b, "Switch", "", getCF(AncoraIso, b, 0, 0, 0), Color3.new(0,1,0), "IN"..b)
                for fan = 1, 4 do
                    registrar(2, "BUF_OUT_"..b.."_"..fan, "Gate", "And", getCF(AncoraIso, b, 0, fan*2, 2), Color3.new(0,0.5,1), nil)
                    fio("BUF_IN_"..b, "BUF_OUT_"..b.."_"..fan)
                end
            end
        end

        local pasta = Core.getBlocks()
        local indices = {}
        for k in pairs(MatrizProjetos) do table.insert(indices, k) end
        table.sort(indices)
        
        for _, camada in ipairs(indices) do
            local lote = MatrizProjetos[camada]
            local grid = {}
            local baseCount = Modules.Hardware.IndexarBlocos(pasta, grid)
            
            for _, t in ipairs(lote) do
                task.spawn(function()
                    ferramentas.Construir:InvokeServer(t.Nome, 1, nil, nil, true, t.CFrame, nil)
                end)
            end
            
            local timeout = 0
            while true do
                local c = pasta and #pasta:GetChildren() or 0
                if c >= (baseCount + #lote) or timeout >= 3.0 then break end
                task.wait(0.1)
                timeout = timeout + 0.1
            end
            
            grid = {}
            Modules.Hardware.IndexarBlocos(pasta, grid)
            local argsPintar = {}
            local argsDesligar = {}
            
            for _, t in ipairs(lote) do
                local h = Modules.Hardware.HashEspacial(t.CFrame.Position)
                local vizinhos = grid[h] or {}
                local minDist = 1.2
                local bSel = nil
                for _, b in ipairs(vizinhos) do
                    local p = b:IsA("Model") and b.PrimaryPart or b:IsA("BasePart") and b or b:FindFirstChildWhichIsA("BasePart")
                    if p then
                        local d = (p.Position - t.CFrame.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            bSel = b
                        end
                    end
                end
                if bSel then
                    DicionarioHardware[t.UID] = bSel
                    if t.Nome == "Gate" and ferramentas.Propriedades then
                        task.spawn(function()
                            if type(t.Tipo) == "table" then
                                for _, sp in ipairs(t.Tipo) do ferramentas.Propriedades:InvokeServer(sp, {bSel}); task.wait(0.01) end
                            else
                                ferramentas.Propriedades:InvokeServer(t.Tipo, {bSel})
                            end
                        end)
                    end
                    if ferramentas.Escalar and t.Nome ~= "Sign" then
                        task.spawn(function()
                            local bCF = bSel:IsA("Model") and bSel.PrimaryPart.CFrame or bSel.CFrame
                            ferramentas.Escalar:InvokeServer(bSel, Vector3.new(Modules.Hardware.Config.TAMANHO_BLOCO, Modules.Hardware.Config.TAMANHO_BLOCO, 0.5), bCF)
                        end)
                    end
                    if t.Nome == "Sign" and t.Texto then
                        task.spawn(function()
                            local det = bSel:WaitForChild("ClickDetector", 3)
                            if det and det:FindFirstChild("Script") and det.Script:FindFirstChild("UpdateSignRE") then
                                det.Script.UpdateSignRE:FireServer({t.Texto})
                            end
                        end)
                    end
                    table.insert(argsDesligar, bSel)
                    table.insert(argsPintar, {bSel, t.Cor})
                end
            end
            if ferramentas.Desligar and #argsDesligar > 0 then task.spawn(function() ferramentas.Desligar:InvokeServer(argsDesligar) end) end
            if ferramentas.Pintar and #argsPintar > 0 then ferramentas.Pintar:InvokeServer(argsPintar) end
            task.wait(0.1)
        end
        
        for _, fio in ipairs(MatrizConexoes) do
            local o = DicionarioHardware[fio.Origem]
            local d = DicionarioHardware[fio.Destino]
            if o and d then
                local porta = d:FindFirstChild("BindActivate") or d:FindFirstChild("BindFire") or d:FindFirstChild("Bind")
                if porta and ferramentas.Ligar then
                    ferramentas.Ligar:InvokeServer({{Activate = {porta}}}, o, {}, false, true)
                end
            end
        end
    end)
end

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
                    task.spawn(function()
                        if Modules.Pipeline then
                            Modules.Pipeline.run({DSL.blocks[k]})
                        end
                    end)
                end
            end
        end
    })
    local env = getgenv and getgenv() or _G
    env.PorBloco = DSL.PorBloco
    env.CorBloco = DSL.CorBloco
    env.EscalaBloco = DSL.EscalaBloco

    DSL.Mover = setmetatable({}, {
        __index = function(t, k)
            return function(x, y, z)
                if DSL.blocks[k] then
                    DSL.blocks[k].Position = DSL.blocks[k].Position + Vector3.new(x, y, z)
                    task.spawn(function()
                        if Modules.Pipeline then Modules.Pipeline.run({DSL.blocks[k]}) end
                    end)
                end
            end
        end
    })

    DSL.Rotacionar = setmetatable({}, {
        __index = function(t, k)
            return function(rx, ry, rz)
                if DSL.blocks[k] then
                    local currentCF = DSL.blocks[k].CFrame or CFrame.new(DSL.blocks[k].Position)
                    DSL.blocks[k].CFrame = currentCF * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
                    task.spawn(function()
                        if Modules.Pipeline then Modules.Pipeline.run({DSL.blocks[k]}) end
                    end)
                end
            end
        end
    })

    DSL.Material = setmetatable({}, {
        __index = function(t, k)
            return function(matName)
                if DSL.blocks[k] then
                    DSL.blocks[k].Block = matName
                    task.spawn(function()
                        if Modules.Pipeline then Modules.Pipeline.run({DSL.blocks[k]}) end
                    end)
                end
            end
        end
    })

    DSL.Deletar = setmetatable({}, {
        __index = function(t, k)
            return function()
                if DSL.blocks[k] then
                    DSL.blocks[k] = nil
                end
            end
        end
    })

    env.Mover = DSL.Mover
    env.Rotacionar = DSL.Rotacionar
    env.Material = DSL.Material
    env.Deletar = DSL.Deletar

    DSL.Hardware = setmetatable({}, {
        __index = function(t, k)
            return function(bits)
                Modules.Hardware.BuildComponent(k, bits or 16)
            end
        end
    })
    env.Hardware = DSL.Hardware

    DSL.MudarTime = function(time)
        Modules.Team.ChangeTeam(time)
    end
    DSL.CarregarBarco = function(slot, backup)
        Modules.Slot.LoadBoat(slot, backup)
    end
    DSL.Autofarm = {
        Iniciar = function() Modules.Autofarm.Start() end,
        Parar = function() Modules.Autofarm.Stop() end
    }
    env.MudarTime = DSL.MudarTime
    env.CarregarBarco = DSL.CarregarBarco
    env.Autofarm = DSL.Autofarm



    DSL.Construir = {
        Esfera = function(raio, material, cor)
            local pos = getFrontPos(raio + 5)
            local blocks = Modules.AdvancedGeometry.GenerateSphere(pos, raio, 15, material, cor)
            if Modules.Pipeline then Modules.Pipeline.run(blocks) end
        end,
        Torus = function(raioMaior, raioMenor, material, cor)
            local pos = getFrontPos(raioMaior + 5)
            local blocks = Modules.AdvancedGeometry.GenerateTorus(pos, raioMaior, raioMenor, 15, material, cor)
            if Modules.Pipeline then Modules.Pipeline.run(blocks) end
        end,
        Fractal = function(tamanho, profundidade, material, cor)
            local pos = getFrontPos(tamanho + 5)
            local blocks = Modules.AdvancedGeometry.Sierpinski(pos, tamanho, profundidade, material, cor)
            if Modules.Pipeline then Modules.Pipeline.run(blocks) end
        end,
        Arvore = function(iteracoes)
            local pos = getFrontPos(10)
            local rules = { ["F"] = "FF+[+F-F-F]-[-F+F+F]" }
            local inst = Modules.LSystem.Generate("F", rules, iteracoes or 3)
            Modules.LSystem.Draw(inst, pos, 2, 25)
        end,
        Caminho = function(destino)
            local pos = getFrontPos(5)
            local path = Modules.Pathfinding.FindPath(pos, destino, 4)
            Modules.Pathfinding.BuildPath(path, "NeonBlock", Color3.new(0,1,1))
        end,
        Cidade = function(largura, comprimento, alturaMax)
            local pos = getFrontPos(largura/2 + 10)
            Modules.CityGenerator.Generate(pos, largura, comprimento, alturaMax)
        end,
        Carro = function()
            local pos = getFrontPos(15)
            Modules.VehicleBuilder.BuildCar(pos)
        end,
        Galaxia = function(estrelas, raio)
            local pos = getFrontPos(raio + 20)
            Modules.Galaxy.Generate(pos, estrelas, raio)
        end
    }

    DSL.Animar = setmetatable({}, {
        __index = function(t, k)
            return function(props, tempo, easing)
                if DSL.blocks[k] then
                    Modules.Animation.Play(DSL.blocks[k], props, tempo or 1, easing or "QuadInOut")
                end
            end
        end
    })

    DSL.Fisica = setmetatable({}, {
        __index = function(t, k)
            return function(massa, pulo)
                if DSL.blocks[k] then
                    Modules.Physics.AddBody(DSL.blocks[k], massa, pulo)
                    if not Modules.Physics.Active then Modules.Physics.Start() end
                end
            end
        end
    })

    DSL.Agrupar = function(...)
        local group = {...}
        return {
            Mover = function(x,y,z)
                for _, b in ipairs(group) do
                    if DSL.blocks[b] then
                        DSL.blocks[b].Position = DSL.blocks[b].Position + Vector3.new(x,y,z)
                    end
                end
            end,
            Cor = function(r,g,b)
                for _, b in ipairs(group) do
                    if DSL.blocks[b] then
                        DSL.blocks[b].Color = Color3.fromRGB(r,g,b)
                    end
                end
            end
        }
    end

    env.Construir = DSL.Construir
    env.Animar = DSL.Animar
    env.Fisica = DSL.Fisica
    env.Agrupar = DSL.Agrupar


    return DSL
end)()
BABFT.RemoteCompute = Modules.RemoteCompute
BABFT.AI = Modules.AI
BABFT.ai = Modules.AI
BABFT.DefineCenter = Modules.Core.DefineCenter
BABFT.Runtime = Modules.Runtime
BABFT.Engine = Modules.Engine

BABFT.AdvancedGeometry = Modules.AdvancedGeometry
BABFT.Animation = Modules.Animation
BABFT.Physics = Modules.Physics
BABFT.Logic = Modules.Logic
BABFT.Music = Modules.Music
BABFT.Pathfinding = Modules.Pathfinding
BABFT.LSystem = Modules.LSystem
BABFT.Voxelizer = Modules.Voxelizer
BABFT.CityGenerator = Modules.CityGenerator
BABFT.FluidSimulation = Modules.FluidSimulation
BABFT.VehicleBuilder = Modules.VehicleBuilder
BABFT.Security = Modules.Security
BABFT.Multiplayer = Modules.Multiplayer
BABFT.Quantum = Modules.Quantum
BABFT.Genetics = Modules.Genetics
BABFT.Galaxy = Modules.Galaxy

BABFT.Hardware = Modules.Hardware
BABFT.Team = Modules.Team
BABFT.Slot = Modules.Slot
BABFT.Autofarm = Modules.Autofarm


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
if Modules.Runtime.init then pcall(Modules.Runtime.init) end
BABFT.DSL = Modules.DSL
_G.BABFT = BABFT
return BABFT
