
local HANDLE = {
  last=5000
}

local function Dice_SetButtonsEnabled(enabled)
  for k, button in pairs(HANDLE.buttons) do
    if enabled then button:Enable() else button:Disable() end
  end
end

local function Dice_TempDisableButtons(secs)
  Dice_SetButtonsEnabled(false)
  C_Timer.After(0.5, function()
    Dice_SetButtonsEnabled(true)
  end)
end

local function Dice_NextRoll()
  RandomRoll(1, HANDLE.last)
  Dice_TempDisableButtons(1)
end

local function Dice_Restart()
  HANDLE.last = 5000
  Dice_NextRoll()
end

local function Dice_CaptureRoll(name, roll, min, max)
  HANDLE.last = roll
end

local function Dice_ParseChat(msg)
  local rx = "^(.+) rolls (%d+) %((%d+)%-(%d+)%)$"
  local name, roll, min, max = msg:match(rx)

  if name then
    Dice_CaptureRoll(name, roll, min, max)
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

  -- frame:Hide()

  -- Register for chat events
  frame:RegisterEvent("CHAT_MSG_SYSTEM")
  frame:SetScript("OnEvent", Dice_OnEvent)

  local restartBtn = Dice_CreateButton("Restart", frame)
  restartBtn:SetPoint("BOTTOMLEFT", 10, 11)
  restartBtn:SetSize(110, 22)
  restartBtn:SetScript('OnClick', Dice_Restart)

  local rollBtn = Dice_CreateButton("Next Roll", frame)
  rollBtn:SetPoint("BOTTOMRIGHT", -8, 11)
  rollBtn:SetSize(110, 22)
  rollBtn:SetScript('OnClick', Dice_NextRoll)

  handle.frame = frame
  handle.buttons = {rollBtn, restartBtn}
end

Dice_Create(HANDLE)