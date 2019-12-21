
local HANDLE = {}

local function Deathroll_NewRoll(name, roll, min, max)
  local msg = string.format("%s rolls %d (%d-%d)", name, roll, min, max)
  
  print(msg)
end

local function Deathroll_ParseChat(msg)
  local rx = "^(.+) rolls (%d+) %((%d+)%-(%d+)%)$"
  local name, roll, min, max = msg:match(rx)

  if name then
    Deathroll_NewRoll(name, roll, min, max)
  end
end

local function Deathroll_OnEvent(frame, event, arg1, ...)
  if event == "CHAT_MSG_SYSTEM" then
    Deathroll_ParseChat(arg1)
  end
end

local function Deathroll_Create(handle)
  handle.frame = CreateFrame("FRAME")
  handle.frame:RegisterEvent("CHAT_MSG_SYSTEM")
  handle.frame:SetScript("OnEvent", Deathroll_OnEvent)
end

Deathroll_Create(HANDLE)