dofile(baseDir .. "KD/KDObject.lua")

---
-- @module KD.Events

--- 
-- @type Events
-- @extends KD.KDObject#KDObject
Events = {
  className = "Events",
}

---
-- @type Event
Event = { }

-- Keep track of event IDs
local _eventCount = 0

function Event:NextEvent()
  local event = _eventCount 
  _eventCount = _eventCount +1
  return event
end

---
-- @function [parent=#Events] New
-- @param #Events self
-- @return #Events

--- 
-- @param #Events self
function Events:Events()

  self.eventHandlers = {}
  
end

---
-- @param #MissionEvents self
-- @param #Event event
-- @param #function handler
function Events:HandleEvent(event, handler)
  self:Assert(event, "Arg `event` was nil")
  self:Assert(handler, "Arg `handler` was nil")
  
  -- events can have multiple handlers
  if self.eventHandlers[event] == nil then
    self.eventHandlers[event] = {}
  end
  
  local localHandlers = self.eventHandlers[event]
  localHandlers[#localHandlers + 1] = handler
  
  self:Trace(3, "Event handler added. Total=" .. #self.eventHandlers .. " Event=" .. #localHandlers)
end

---
-- @param #MissionEvents self
-- @param #Event event
function Events:FireEvent(event, arg)
  self:Assert(event, "Arg `event` was nil")
  
  local localHandlers = self.eventHandlers[event]
  if localHandlers then
  
    for i = 1, #localHandlers do
    
      local eventHandler = localHandlers[i]
      if eventHandler then
        eventHandler(arg)
      end
      
    end
    
  end
end

Events = createClass(KDObject, Events)
