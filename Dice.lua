

SLASH_DICE1 = "/dice"

local INITIAL_ROLL = 10000

local HANDLE = {
  rolls={}
}

local function FramePool_Init(parent)
  if not parent.FramePool then
    parent.FramePool = {}
  end
end

local function FramePool_All(parent)
  FramePool_Init(parent)
  return parent.FramePool
end

local function FramePool_Put(parent, frame)
  FramePool_Init(parent)
  tinsert(parent.FramePool, frame)
end

local function FramePool_Get(parent)
  FramePool_Init(parent)
  local frame = tremove(parent.FramePool)
  if frame then
    return frame
  else
    return parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  end
end

local function Dice_GetLastValue(key, default)
  local player = UnitName("player")
  local last = HANDLE.rolls[player]

  if last then
    local v = last[key]
    if v then
      return v
    end
  end

  return default
end

local function Dice_SortedRolls()
  local rolls = {}
  for k, v in pairs(HANDLE.rolls) do
    tinsert(rolls, v)
  end
  table.sort(rolls, function (left, right)
      return left.roll > right.roll
  end)
  return rolls
end

local function Dice_SetEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
end

local function Dice_UpdateTable()
  local rows = Dice_SortedRolls()

  local scrollFrame = HANDLE.Frame.ScrollFrame
  local scrollChild = scrollFrame.Child
  local w = scrollFrame:GetWidth()
  local top = -4
  local rowHeight = 18

  -- Hide all previous row frames
  for i, frame in pairs(FramePool_All(scrollChild)) do
    frame:Hide()
  end

  -- Make new row frames if necessary or reuse from pool
  local textFrames = {}

  for k, v in pairs(rows) do

    local color = ""

    -- Set color to red for eliminated players
    if v.roll <= 1 then
      color = "|cffff0000"
    end

    local fplayer = FramePool_Get(scrollChild)
    fplayer:SetPoint("TOPLEFT", 4, top)
    fplayer:SetText(string.format("%s%s", color, v.name))
    fplayer:Show()

    local froll = FramePool_Get(scrollChild)
    froll:SetPoint("TOPLEFT", w * 0.4, top)
    froll:SetText(string.format("%d (%d-%d)", v.roll, v.min, v.max))
    froll:Show()

    local sago = math.floor(time() - v.ts)

    local fround = FramePool_Get(scrollChild)
    fround:SetPoint("TOPLEFT", w * 0.8, top)
    fround:SetText(string.format("Round %d", v.round))
    fround:Show()

    tinsert(textFrames, fplayer)
    tinsert(textFrames, froll)
    tinsert(textFrames, fround)

    top = top - rowHeight
  end

  -- Put all row frames back in the pool
  for i, frame in pairs(textFrames) do
    FramePool_Put(scrollChild, frame)
  end

  local h = math.abs(top)

  scrollChild:SetSize(w, h)
end

local function Dice_CanRoll()
    -- Don't allow rolling if we already hit 1
  if Dice_GetLastValue("roll", INITIAL_ROLL) <= 1 then
    return false
  end

  local minRound = nil

  for k, v in pairs(HANDLE.rolls) do
    -- Do not include 1 rolls (losers)
    if v.roll > 1 then
      if minRound then
        minRound = math.min(minRound, v.round)
      else
        minRound = v.round
      end
    end
  end

  -- Always allow rolls if no round started yet
  if not minRound then
    return true
  end

  local myRound = Dice_GetLastValue("round", 0)

  return myRound <= minRound
end

local function Dice_NextRoll()
  local lastRoll = Dice_GetLastValue("roll", INITIAL_ROLL)

  RandomRoll(1, lastRoll)
end

local function Dice_Clear()
  HANDLE.rolls = {}
  Dice_UpdateTable()
  Dice_SetEnabled(HANDLE.RollButton, true)
end

local function Dice_CaptureRoll(name, roll, min, max)
  local prev = HANDLE.rolls[name]
  local round = 0

  if prev then
    round = prev.round
  end

  round = round + 1

  HANDLE.rolls[name] = {
    name=name,
    roll=roll,
    min=min,
    max=max,
    ts=time(),
    round=round
  }

  Dice_UpdateTable()
  Dice_SetEnabled(HANDLE.RollButton, Dice_CanRoll())
end

local function Dice_ParseChat(msg)
  local rx = "^(.+) rolls (%d+) %((%d+)%-(%d+)%)$"
  local name, sroll, smin, smax = msg:match(rx)
  local roll = tonumber(sroll)
  local min = tonumber(smin)
  local max = tonumber(smax)

  if name then

    Dice_CaptureRoll(name, roll, min, max)

    -- For testing purposes only
    -- for i=1,3 do
    --   Dice_CaptureRoll(name..i, roll-i, min, max-1)
    -- end
  end
end

local function Dice_OnEvent(frame, event, arg1, ...)
  if event == "CHAT_MSG_SYSTEM" then
    Dice_ParseChat(arg1)
  end
end

local function Dice_CreateButton(text, parent)
  local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  btn:SetText(text)
  btn:SetNormalFontObject("GameFontNormal")
  btn:SetHighlightFontObject("GameFontHighlight")
  return btn
end

local function Dice_Create(handle)
  local w = 400
  local h = 300
  local frame = CreateFrame("FRAME", "DiceFrame", UIParent, "UIPanelDialogTemplate")
  frame:SetSize(w, h)
  frame:SetPoint("CENTER")

  -- Dialog title
  frame.Title:SetText("Dice")

  -- Make frame draggable
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  -- Register for chat events
  frame:RegisterEvent("CHAT_MSG_SYSTEM")
  frame:SetScript("OnEvent", Dice_OnEvent)

  -- Scrollable Frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", DiceFrameDialogBG, "TOPLEFT", 4, -4)
  scrollFrame:SetPoint("BOTTOMRIGHT", DiceFrameDialogBG, "BOTTOMRIGHT", -22, 22)
  -- scrollFrame:SetClipsChildren(true)

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)

  scrollFrame:SetScrollChild(scrollChild)

  scrollFrame.Child = scrollChild
  frame.ScrollFrame = scrollFrame

  -- Buttons
  local bw = (w - 12) / 2
  local x = 8
  local clearBtn = Dice_CreateButton("Clear", frame)
  clearBtn:SetPoint("BOTTOMLEFT", x, 8)
  clearBtn:SetSize(bw, 22)
  clearBtn:SetScript('OnClick', Dice_Clear)

  local rollBtn = Dice_CreateButton("Next Roll", frame)
  rollBtn:SetPoint("BOTTOMLEFT", x + bw, 8)
  rollBtn:SetSize(bw, 22)
  rollBtn:SetScript('OnClick', Dice_NextRoll)

  handle.Frame = frame
  handle.ClearButton = clearBtn
  handle.RollButton = rollBtn
end

Dice_Create(HANDLE)

SlashCmdList["DICE"] = function(msg)
   HANDLE.Frame:Show()
end 

-- DEBUG
-- HANDLE.Frame:Show()
