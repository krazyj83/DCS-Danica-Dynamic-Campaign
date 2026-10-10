-- ============================================================================
-- Danica Dynamic Campaign - minimal JSON encoder/decoder (pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- DCS has net.lua2json, but its availability in the mission sandbox has
-- changed between versions. A small local encoder keeps saves working on any
-- DCS build and in offline tests.
--
-- Rules: a table whose keys are exactly 1..n is a JSON array; any other table
-- is an object and its keys are written as strings. Empty tables become {}.
-- ============================================================================

DCC = DCC or {}
local J = {}
DCC.json = J

local escapes = { ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
                  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }

local function escapeStr(s)
  return '"' .. s:gsub('[%c"\\]', function(c)
    return escapes[c] or string.format("\\u%04x", c:byte())
  end) .. '"'
end

local function isArray(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  if n == 0 then return false end
  for i = 1, n do if t[i] == nil then return false end end
  return true
end

local function encode(v, out, indent, depth)
  local tv = type(v)
  if tv == "nil" then out[#out + 1] = "null"
  elseif tv == "boolean" then out[#out + 1] = tostring(v)
  elseif tv == "number" then
    if v ~= v or v == math.huge or v == -math.huge then out[#out + 1] = "null"
    elseif v == math.floor(v) and math.abs(v) < 1e15 then out[#out + 1] = string.format("%d", v)
    else out[#out + 1] = string.format("%.17g", v) end -- 17 digits: exact round trip
  elseif tv == "string" then out[#out + 1] = escapeStr(v)
  elseif tv == "table" then
    local nl = indent and ("\n" .. string.rep(indent, depth + 1)) or ""
    local close = indent and ("\n" .. string.rep(indent, depth)) or ""
    if isArray(v) then
      out[#out + 1] = "["
      for i = 1, #v do
        if i > 1 then out[#out + 1] = "," end
        out[#out + 1] = nl
        encode(v[i], out, indent, depth + 1)
      end
      out[#out + 1] = close .. "]"
    else
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = tostring(k) end
      table.sort(keys)
      out[#out + 1] = "{"
      for i, k in ipairs(keys) do
        if i > 1 then out[#out + 1] = "," end
        local val = v[k]
        if val == nil then val = v[tonumber(k)] end
        out[#out + 1] = nl .. escapeStr(k) .. (indent and ": " or ":")
        encode(val, out, indent, depth + 1)
      end
      out[#out + 1] = (#keys > 0 and close or "") .. "}"
    end
  else
    error("dcc_json: cannot encode type " .. tv)
  end
end

function J.encode(v, pretty)
  local out = {}
  encode(v, out, pretty and "  " or nil, 0)
  return table.concat(out)
end

-- ---------------------------------------------------------------------------
-- Decoder (recursive descent)
-- ---------------------------------------------------------------------------
local function skip(s, i)
  local _, e = s:find("^[ \n\r\t]*", i)
  return e + 1
end

local decodeValue

local function decodeString(s, i)
  local out, j = {}, i + 1
  while true do
    local c = s:sub(j, j)
    if c == "" then error("dcc_json: unterminated string") end
    if c == '"' then return table.concat(out), j + 1 end
    if c == "\\" then
      local n = s:sub(j + 1, j + 1)
      local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
      if n == "u" then
        local code = tonumber(s:sub(j + 2, j + 5), 16)
        out[#out + 1] = code < 128 and string.char(code) or "?"
        j = j + 6
      else
        out[#out + 1] = map[n] or n
        j = j + 2
      end
    else
      out[#out + 1] = c
      j = j + 1
    end
  end
end

function decodeValue(s, i)
  i = skip(s, i)
  local c = s:sub(i, i)
  if c == "{" then
    local obj = {}
    i = skip(s, i + 1)
    if s:sub(i, i) == "}" then return obj, i + 1 end
    while true do
      local key
      key, i = decodeString(s, skip(s, i))
      i = skip(s, i)
      if s:sub(i, i) ~= ":" then error("dcc_json: expected ':' at " .. i) end
      obj[key], i = decodeValue(s, i + 1)
      i = skip(s, i)
      local d = s:sub(i, i)
      if d == "}" then return obj, i + 1 end
      if d ~= "," then error("dcc_json: expected ',' or '}' at " .. i) end
      i = i + 1
    end
  elseif c == "[" then
    local arr = {}
    i = skip(s, i + 1)
    if s:sub(i, i) == "]" then return arr, i + 1 end
    while true do
      arr[#arr + 1], i = decodeValue(s, i)
      i = skip(s, i)
      local d = s:sub(i, i)
      if d == "]" then return arr, i + 1 end
      if d ~= "," then error("dcc_json: expected ',' or ']' at " .. i) end
      i = i + 1
    end
  elseif c == '"' then
    return decodeString(s, i)
  elseif s:sub(i, i + 3) == "true" then return true, i + 4
  elseif s:sub(i, i + 4) == "false" then return false, i + 5
  elseif s:sub(i, i + 3) == "null" then return nil, i + 4
  else
    local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
    if not num or num == "" then error("dcc_json: unexpected character at " .. i) end
    return tonumber(num), i + #num
  end
end

function J.decode(s)
  local v = decodeValue(s, 1)
  return v
end
