-- Vision Forge Workflow: timer lines, Start buttons and "time is up" pop-ups

local NOT_STARTED = -999999000

function Initialize()
  fetchAt = os.time()
  res = SKIN:ReplaceVariables('#@#')
  notifiedPath = res .. 'notified.txt'
  notified = {}
  local f = io.open(notifiedPath, 'r')
  if f then
    for line in f:lines() do if line ~= '' then notified[line] = true end end
    f:close()
  end
  mode = { -1, -1, -1 }
  starting = {}
end

-- called by the WebParser FinishAction each time fresh data arrives
function OnFetch()
  fetchAt = os.time()
  starting = {}
end

local function val(name)
  local m = SKIN:GetMeasure(name)
  if not m then return '' end
  return m:GetStringValue() or ''
end

local function fmt(sec)
  sec = math.max(0, math.floor(sec + 0.5))
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  if h > 0 and m > 0 then return h .. 'h ' .. m .. 'm' end
  if h > 0 then return h .. 'h' end
  if m > 0 then return m .. 'm' end
  return '<1m'
end

local function psArg(s)
  -- quote for the PowerShell command line
  s = tostring(s or ''):gsub('"', "'")
  return '"' .. s .. '"'
end

local function saveNotified()
  local f = io.open(notifiedPath, 'w')
  if not f then return end
  for k in pairs(notified) do f:write(k, '\n') end
  f:close()
end

local function popup(title, body)
  local param = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ' ..
    psArg(res .. 'Notify.ps1') .. ' ' .. psArg(title) .. ' ' .. psArg(body)
  SKIN:Bang('!SetOption', 'MeasureNotify', 'Parameter', param)
  SKIN:Bang('!UpdateMeasure', 'MeasureNotify')
  SKIN:Bang('!CommandMeasure', 'MeasureNotify', 'Run')
end

-- timer area: 0 nothing, 1 Start button, 2 running line, 3 "no time set"
local function setMode(i, m)
  if mode[i] == m then return end
  mode[i] = m
  SKIN:Bang(m == 1 and '!ShowMeterGroup' or '!HideMeterGroup', 'TimerStart' .. i)
  SKIN:Bang(m == 2 and '!ShowMeterGroup' or '!HideMeterGroup', 'TimerBar' .. i)
  SKIN:Bang(m == 3 and '!ShowMeterGroup' or '!HideMeterGroup', 'TimerNone' .. i)
end

local DOT = { ['To do'] = '255,95,87', ['In process'] = '255,197,61', ['Done'] = '52,199,89' }

local function clean(v)
  v = tostring(v or '')
  if v == 'null' then return '' end
  v = v:gsub('^"', ''):gsub('"$', '')
  v = v:gsub('\\"', '"')
  return v
end

local lastErr = ''
function Update()
  local ok, err = pcall(Tick)
  if not ok and tostring(err) ~= lastErr then
    lastErr = tostring(err)
    print('Vision Forge timers error: ' .. lastErr)
  end
  return ''
end

function Tick()
  local now = os.time()
  local due = {}
  for i = 1, 3 do
    local p = 'MeasureR' .. i
    local name   = val(p .. 'Name')
    local status = val(p .. 'Status')
    local mins   = tonumber(val(p .. 'Mins')) or 0
    local secs   = tonumber(val(p .. 'Secs')) or NOT_STARTED - 1
    local key    = val(p .. 'Key')
    local id     = val(p .. 'Id')
    local person = clean(val(p .. 'Person'))

    SKIN:Bang('!SetVariable', 'R' .. i .. 'Person', person)
    SKIN:Bang('!SetVariable', 'R' .. i .. 'Dot', DOT[status] or '255,255,255')
    SKIN:Bang(person == '' and '!HideMeter' or '!ShowMeter', 'MeterR' .. i .. 'PersonIcon')

    if name == '' or status == 'Done' then
      setMode(i, 0)
    elseif mins <= 0 then
      setMode(i, 3)
    elseif secs <= NOT_STARTED then
      SKIN:Bang('!SetVariable', 'T' .. i .. 'Start', starting[i] and 'Starting...' or ('Start  (' .. fmt(mins * 60) .. ')'))
      setMode(i, 1)
    else
      local total = mins * 60
      local left = secs - (now - fetchAt)
      local frac = math.max(0, math.min(1, left / total))
      local color, text, tcolor
      if left <= 0 then
        color = '255,95,87'; text = '+' .. fmt(-left) .. ' over'; tcolor = '255,179,174,255'
      else
        color = (frac > 0.5 and '52,199,89') or (frac > 0.2 and '255,197,61') or '255,95,87'
        text = fmt(left) .. ' left'; tcolor = '255,255,255,175'
      end
      SKIN:Bang('!SetVariable', 'T' .. i .. 'Used', string.format('%.4f', left <= 0 and 1 or (1 - frac)))
      SKIN:Bang('!SetVariable', 'T' .. i .. 'Color', color)
      SKIN:Bang('!SetVariable', 'T' .. i .. 'Text', text)
      SKIN:Bang('!SetVariable', 'T' .. i .. 'TextColor', tcolor)
      setMode(i, 2)

      local nk = id .. '|' .. key
      if left <= 0 and key ~= '' and not notified[nk] then
        notified[nk] = true
        table.insert(due, name)
      end
    end
  end

  if #due > 0 then
    saveNotified()
    if #due == 1 then
      popup('Vision Forge', due[1] .. ' time is up')
    else
      popup('Vision Forge', table.concat(due, ', ') .. ' time is up')
    end
  end

  SKIN:Bang('!UpdateMeterGroup', 'TimerStart1'); SKIN:Bang('!UpdateMeterGroup', 'TimerStart2'); SKIN:Bang('!UpdateMeterGroup', 'TimerStart3')
  SKIN:Bang('!UpdateMeterGroup', 'TimerBar1'); SKIN:Bang('!UpdateMeterGroup', 'TimerBar2'); SKIN:Bang('!UpdateMeterGroup', 'TimerBar3')
  SKIN:Bang('!UpdateMeterGroup', 'Row1'); SKIN:Bang('!UpdateMeterGroup', 'Row2'); SKIN:Bang('!UpdateMeterGroup', 'Row3')
  SKIN:Bang('!Redraw')
end

-- Start button
function Start(i)
  if mode[i] ~= 1 or starting[i] then return end
  local id = val('MeasureR' .. i .. 'Id')
  if id == '' then return end
  starting[i] = true
  SKIN:Bang('!SetVariable', 'T' .. i .. 'Start', 'Starting...')
  SKIN:Bang('!UpdateMeterGroup', 'TimerStart' .. i)
  SKIN:Bang('!Redraw')
  local param = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ' ..
    psArg(res .. 'StartTimer.ps1') .. ' ' .. psArg(SKIN:GetVariable('SupabaseURL')) .. ' ' ..
    psArg(SKIN:GetVariable('SupabaseKey')) .. ' ' .. psArg(id)
  SKIN:Bang('!SetOption', 'MeasureStart', 'Parameter', param)
  SKIN:Bang('!UpdateMeasure', 'MeasureStart')
  SKIN:Bang('!CommandMeasure', 'MeasureStart', 'Run')
end
