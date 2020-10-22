dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission02

--- 
-- @type Mission02
-- @extends KD.Mission#Mission
Mission02 = {
  className = "Mission02",
  
  enemyApcIndex = -1,
  enemyApcMaxCount = 3,
  enemyApcSpawnDelay = 4 * 60,
  enemyApcsMinLife = 10
}

---
-- @type Mission02.State
-- @extends KD.Mission#MissionState
Mission02.State = {
  TerroristsLanding     = State:NextState(),
  AirfieldSecured       = State:NextState(),
  TerroristsArrived     = State:NextState(),
  HostagesEscaping      = State:NextState(),
  HostagesEscaped       = State:NextState(),
}

---
-- @param #Mission02 self
function Mission02:Mission02()

  --self:SetTraceLevel(3)
  self.playerTestOn = true
  self.testPlayerGroupName = "Test"
  self.testPlayerUnitName = "Test"
  
  self.playerPrefix = "Dodge"
  self.singlePlayerGroupMode = false

  self.state:AddStates(Mission02.State)
  
  self.terroristsZone = self:NewMooseZone("Terrorists")
  self.escapeZone = self:NewMooseZone("Escape")
  self.rescueGroup = self:GetMooseGroup("Rescue")
  self.terroristsGroup = self:GetMooseGroup("Terrorists")
  self.enemyJets = self:GetMooseGroup("Enemy Jets")
  
  self.enemyApcs = {}
  self.scouts = {}
  for i = 1, self.enemyApcMaxCount do
    self.enemyApcs[i] = self:GetMooseGroup("Enemy APCs #00" .. i)
    self.scouts[i] = self:GetMooseGroup("Scouts #00" .. i)
  end
  
  self.state:TriggerOnce(
    Mission02.State.TerroristsLanding,
    function() return self:AreAnyUnitsInZone(self.terroristsZone, self.playerUnits) end,
    function() self:OnTerroristsLanding() end
  )
  
  self.state:TriggerOnce(
    Mission02.State.AirfieldSecured,
    function() return self:IsAirfieldSecured() end,
    function() self:OnAirfieldSecured() end
  )
  
  self.state:TriggerOnce(
    Mission02.State.TerroristsArrived,
    function() return self.terroristsGroup:GetVelocityKNOTS() < 1 end,
    function() self:OnTerroristsArrived() end
  )
  
  self.state:TriggerOnce(
    Mission02.State.HostagesEscaped,
    function() return not self.rescueGroup:IsAnyInZone(self.escapeZone) end,
    function() self:OnHostagesEscaped() end
  )
  
  self.state:TriggerOnce(
    MissionState.MissionFailed,
    function() return not self.rescueGroup:IsAlive() end
  )
  
  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission02.State.HostagesEscaped,
    function() return self:ArePlayersLanded() end
  )
  
end

---
-- @param #Mission02 self
function Mission02:OnStart()
  
  self:MessageAll(MessageLength.Long, "Mission 2: Assist with a hostage rescue in enemy territory.")
  self:MessageAll(MessageLength.Long, "Read the mission brief enroute to WP1")
  
  -- Respawn unattended to stop them from moving
  self.rescueGroup:RespawnAtCurrentAirbase(nil, nil, true)
  
end

---
-- @param #Mission02 self
function Mission02:GetEnemyApc()

  local index = self.enemyApcIndex
  if index == -1 then 
    return nil
  end
  
  local apc = self.enemyApcs[index]
  if not apc then
    return nil
  end
  
  return apc
  
end

---
-- @param #Mission02 self
function Mission02:IsAirfieldSecured()

  local apc = self:GetEnemyApc()
  if not apc then
    return false
  end
  
  return self:CountAliveUnitsFromGroup(apc) == 0

end

---
-- @param #Mission02 self
function Mission02:OnTerroristsLanding()

  self:MessageAll(MessageLength.Long,
    "The hijacked aircraft is on final approach. Enemy forces are now trying to take " .. 
    "the airbase. Any vehicles approaching the airbase are to be considered hostile " ..
    "and should be destroyed. Friendly forces on the ground will pop smoke in the " ..
    "direction of the enemy when spotted.",
    true)
    
  local random = math.random(1, self.enemyApcMaxCount)
  self.enemyApcIndex = random
  
  local apc = self.enemyApcs[random]
  self:Assert(apc, "APC expected at index: " .. random)
  apc:Activate()
    
  self:Schedule(function()
  
    local scout = self.scouts[random]
    self:Assert(apc, "Scout expected at index: " .. random)
  
    scout:SmokeRed()
    
    self:MessageAll(MessageLength.LessShort,
      "[Scout] I have spotted an enemy moving through the city toward my direction. I'm popping red smoke.", true)
  
  end, self.enemyApcSpawnDelay)

end

---
-- @param #Mission02 self
function Mission02:OnAirfieldSecured()

  self:MessageAll(MessageLength.LessShort,
    "The last of the approaching enemy ground units have been destroyed. " ..
    "Orbit the airbase until the rescue mission has been completed.",
    true)
    
end

---
-- @param #Mission02 self
function Mission02:OnTerroristsArrived()

  -- Respawn normally to start them moving
  self.rescueGroup:RespawnAtCurrentAirbase()

  self:MessageAll(MessageLength.LessShort,
    "Hostages rescued and our C17 is rolling. "..
    "We have detected enemy fighters inbound from the east. " ..
    "They don't want the rescue mission to succeed. Escort the C17 to safety.",
    true)
  
end

---
-- @param #Mission02 self
function Mission02:OnHostagesEscaped()

  self:MessageAll(MessageLength.LessLong,
    "Our C17 is now safe. You may RTB.",
    true)
  
end

---
-- @param #Mission02 self
function Mission02:OnGameLoop()
  
  local apc = self:GetEnemyApc()
  if apc then
    self:SelfDestructDamagedUnitsInList(apc, self.enemyApcsMinLife)
  end
  
end

---
-- @param #Mission02 self
-- @param Wrapper.Unit#UNIT unit
function Mission02:OnUnitDead(unit)

  if (string.match(unit:GetName(), "Enemy APC")) then
    self:MessageAll(MessageLength.VeryShort, "Enemy APC destroyed.", true)
  end

  if (string.match(unit:GetName(), "Rescue")) then
    self:MessageAll(MessageLength.VeryShort, "Rescue transport was destroyed.", true)
  end

end

Mission02 = createClass(Mission, Mission02)
Horus_Mission02 = Mission02
