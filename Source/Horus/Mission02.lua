dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission02

--- 
-- @type Mission02
-- @extends KD.Mission#Mission
Mission02 = {
  className = "Mission02",
}

---
-- @type Mission02.State
-- @extends KD.Mission#MissionState
Mission02.State = {
}

---
-- @param #Mission02 self
function Mission02:Mission02()

  --self:SetTraceLevel(3)
  self.playerTestOn = true
  self.testPlayerGroupName = "Test"
  self.testPlayerUnitName = "Test"

  self.state:AddStates(Mission02.State)
  
  self.playerPrefix = "Dodge"
  self.singlePlayerGroupMode = false
  
end

---
-- @param #Mission02 self
function Mission02:OnStart()
  
  self:MessageAll(MessageLength.Long, "Mission 2: Assist with a hostage rescue in enemy territory.")
  self:MessageAll(MessageLength.Long, "Read the mission brief enroute to WP1")
  
end

---
-- @param #Mission02 self
function Mission02:OnGameLoop()
  
end

---
-- @param #Mission02 self
-- @param Wrapper.Unit#UNIT unit
function Mission02:OnUnitSpawn(unit)

end

---
-- @param #Mission02 self
-- @param Wrapper.Unit#UNIT unit
function Mission02:OnPlayerSpawn(unit)

end

---
-- @param #Mission02 self
-- @param Wrapper.Unit#UNIT unit
function Mission02:OnUnitDead(unit)

end

Mission02 = createClass(Mission, Mission02)
Horus_Mission02 = Mission02
