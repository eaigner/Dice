

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

local function Dice_GetLastRoll()
  local player = UnitName("player")
  local last = HANDLE.rolls[player]

  if last then
    return last.roll
  else
    return INITIAL_ROLL
  end
end

local function Dice_SetLastRoll(v)
  local player = UnitName("player")
  HANDLE.rolls[player] = {
    name=player,
    roll=v,
    min=1,
    max=v,
  }
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

local function Dice_SetButtonsEnabled(enabled)
  for k, button in pairs(HANDLE.Buttons) do
    if enabled then button:Enable() else button:Disable() end
  end
end

local function Dice_TempDisableButtons(secs)
  Dice_SetButtonsEnabled(false)
  C_Timer.After(0.25, function()
    Dice_SetButtonsEnabled(true)
  end)
end

local function Dice_UpdateTable(rows)
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
    local fplayer = FramePool_Get(scrollChild)
    fplayer:SetPoint("TOPLEFT", 4, top)
    fplayer:SetText(v.name)
    fplayer:Show()

    local froll = FramePool_Get(scrollChild)
    froll:SetPoint("TOPLEFT", w * 0.7, top)
    froll:SetText(v.roll)
    froll:Show()

    tinsert(textFrames, fplayer)
    tinsert(textFrames, froll)

    top = top - rowHeight
  end

  -- Put all row frames back in the pool
  for i, frame in pairs(textFrames) do
    FramePool_Put(scrollChild, frame)
  end

  local h = math.abs(top)

  scrollChild:SetSize(w, h)
end

local function Dice_NextRoll()
  local lastRoll = Dice_GetLastRoll()

  RandomRoll(1, lastRoll)
  Dice_TempDisableButtons(1)
end

local function Dice_Restart()
  Dice_SetLastRoll(INITIAL_ROLL)
  Dice_NextRoll()
end

local function Dice_CaptureRoll(name, roll, min, max)
  HANDLE.rolls[name] = {
    name=name,
    roll=roll,
    min=min,
    max=max,
  }
  
  local sortedRolls = Dice_SortedRolls()

  Dice_UpdateTable(sortedRolls)
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
    -- for i=1,10 do
    --   local r = math.floor(math.random() * roll)
    --   Dice_CaptureRoll(name..i, r, min, max)
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
  local frame = CreateFrame("FRAME", "DiceFrame", UIParent, "UIPanelDialogTemplate")
  frame:SetSize(240, 300)
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
  local restartBtn = Dice_CreateButton("Restart", frame)
  restartBtn:SetPoint("BOTTOMLEFT", 8, 8)
  restartBtn:SetSize(115, 22)
  restartBtn:SetScript('OnClick', Dice_Restart)

  local rollBtn = Dice_CreateButton("Next Roll", frame)
  rollBtn:SetPoint("BOTTOMRIGHT", -4, 8)
  rollBtn:SetSize(116, 22)
  rollBtn:SetScript('OnClick', Dice_NextRoll)

  handle.Frame = frame
  handle.Buttons = {rollBtn, restartBtn}
end

Dice_Create(HANDLE)

SlashCmdList["DICE"] = function(msg)
   HANDLE.Frame:Show()
end 
