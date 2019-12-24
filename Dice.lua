
local HANDLE = {
  last=5000
}

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

  for k, v in pairs(rows) do
    local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 4, top)
    label:SetText(v .. ": " .. time())

    top = top - rowHeight
  end

  local h = math.abs(top)

  scrollChild:SetSize(w, h)
end

local function Dice_NextRoll()
  RandomRoll(1, HANDLE.last)

  -- TODO: rm
  -- Dice_UpdateTable({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "X", "Y", "Z"})

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
