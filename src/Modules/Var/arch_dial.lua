--[[
    DialogueSequence.lua
    A system for creating and managing structured dialogue sequences
]]

local DialogueSequence = {}
DialogueSequence.__index = DialogueSequence

-- Internal helper to create a new sequence step
local function createStep(stepType, content, duration)
    return {
        type = stepType,    -- Type of step (dialogue, wait, or custom action)
        content = content,  -- Text content or function for custom actions
        duration = duration -- Duration for waits or timed dialogues
    }
end

-- Create a new dialogue sequence
function DialogueSequence.new(dialogueManager)
    local self = setmetatable({}, DialogueSequence)
    self.steps = {}        -- Sequence of dialogue steps
    self.dia = dialogueManager
    self.currentIndex = 1  -- Current step in the sequence
    self.isPlaying = false
    self.onComplete = nil  -- Callback for sequence completion
    return self
end

-- Add dialogue that stays until next step
function DialogueSequence:say(text)
    table.insert(self.steps, createStep("say", text))
    return self -- Enable method chaining
end

-- Add dialogue with specific duration
function DialogueSequence:sayFor(text, duration)
    table.insert(self.steps, createStep("sayFor", text, duration))
    return self
end

-- Add a wait period
function DialogueSequence:wait(duration)
    table.insert(self.steps, createStep("wait", nil, duration))
    return self
end

-- Add a custom action (function to execute)
function DialogueSequence:do_(action)
    table.insert(self.steps, createStep("action", action))
    return self
end

-- Add a branch point with conditions
function DialogueSequence:branch(conditions)
    -- conditions is a table of {condition = function(), sequence = DialogueSequence}
    table.insert(self.steps, createStep("branch", conditions))
    return self
end

-- Set completion callback
function DialogueSequence:onFinish(callback)
    self.onComplete = callback
    return self
end

-- Execute a single step
function DialogueSequence:executeStep(step)
    if step.type == "say" then
        self.dia.ShowText_Forever(step.content)
    elseif step.type == "sayFor" then
        self.dia.ShowText_ForDuration(step.content, step.duration)
    elseif step.type == "wait" then
        task.wait(step.duration)
    elseif step.type == "action" then
        step.content() -- Execute custom function
    elseif step.type == "branch" then
        for _, branch in ipairs(step.content) do
            if branch.condition() then
                branch.sequence:play()
                break
            end
        end
    end
end

-- Play the sequence
function DialogueSequence:play()
    if self.isPlaying then return end
    self.isPlaying = true

    task.spawn(function()
        while self.currentIndex <= #self.steps and self.isPlaying do
            local step = self.steps[self.currentIndex]
            self:executeStep(step)
            self.currentIndex = self.currentIndex + 1
        end

        if self.onComplete and self.isPlaying then
            self.onComplete()
        end

        self.isPlaying = false
    end)
end

-- Stop the sequence
function DialogueSequence:stop()
    self.isPlaying = false
    self.currentIndex = 1
    self.dia.HideDialogue()
end

return DialogueSequence