dofile(baseDir .. "KD/Mission.lua")

---
-- @type OFF_Mission02
-- @extends KD.Mission#Mission
OFF_Mission02 = {
  className = "OFF_Mission02",

  enableDebugMenu = true,
  
  redMalitiaOptions = 3,
  redRoadblockOptions = 3,
  
  blueConvoyDead = 0,
  blueConvoyMinAlive = 4
}

---
-- @type OFF_Mission02.State
-- @extends KD.Mission#MissionState
OFF_Mission02.State = {
  ConvoyRendezvous = State:NextState(),
  EnemeyDestroyed = State:NextState(),
}

---
-- @param #OFF_Mission02 self
function OFF_Mission02:OFF_Mission02()

  self.enemyDestroyed = false

  --self:SetTraceLevel(3)
  self.playerTestOn = false
  self.testPlayerGroupName = "Test Squadron"
  self.testPlayerUnitName = "Test"

  self.state:AddStates(OFF_Mission02.State)
  self.state:CopyTrace(self)

  self.playerPrefix = "Colt"
  self.singlePlayerGroupMode = false

  self.playerParking = self:NewMooseZone("Player Parking")
  self.startConvoy = self:NewMooseZone("Start Convoy")
  
  self.blueConvoyStopped = self:GetMooseGroup("Blue Convoy Stopped")
  self.blueConvoyMoving = self:GetMooseGroup("Blue Convoy Moving")
  
  self.redMalitiaGroups = {}
  for i = 1, self.redMalitiaOptions do
    self.redMalitiaGroups[i] = self:GetMooseGroup("Red Units #00" .. i)
  end

  self.redRoadblockGroups = {}
  for i = 1, self.redRoadblockOptions do
    self.redRoadblockGroups[i] = self:GetMooseGroup("Red Road Block #00" .. i)
  end

  self.state:TriggerOnce(
    OFF_Mission02.State.ConvoyRendezvous,
    function() return self:AreAnyGroupsInZone(self.startConvoy, self.playerGroups) end,
    function() self:OnConvoyRendezvous() end
  )

  self.state:TriggerOnce(
    OFF_Mission02.State.EnemeyDestroyed,
    function() return self:AreAllEnemyDestroyed() end,
    function() self:OnEnemeyDestroyed() end
  )

  self.state:TriggerOnce(
    MissionState.MissionAccomplished,
    function() return self.enemyDestroyed and self:UnitsAreParked(self.playerParking, self.playerUnits) end
  )

  self.state:TriggerOnce(
    MissionState.MissionFailed,
    function() return self:IsHalfOfConvoyDead() end,
    function() self:OnMissionFailed() end
  )

end

---
-- @param #OFF_Mission02 self
function OFF_Mission02:OnStart()
  
  local redMalitiaRandom = math.random(1, self.redMalitiaOptions)
  local redRoadblockRandom = math.random(1, self.redRoadblockOptions)
  self:Trace(1, "Random malitia index: " .. redMalitiaRandom)
  self:Trace(1, "Random roadblock index: " .. redRoadblockRandom)
  
  local malitia = self.redMalitiaGroups[redMalitiaRandom]
  local roadblock = self.redRoadblockGroups[redRoadblockRandom]
  
  self:Assert(malitia, "Couldn't get random malitia")
  self:Assert(roadblock, "Couldn't get random roadblock")
  
  malitia:Activate()
  roadblock:Activate()
  
  if self.enableDebugMenu then
    self:CreateDebugMenu({
      self.playerGroups,
      self.redMalitiaGroups,
      self.redRoadblockGroups,
    })
  end

end

---
-- @param #OFF_Mission02 self
-- @param Wrapper.Unit#UNIT unit
function OFF_Mission02:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())
  
  if string.match(unit:GetName(), "Blue Convoy Moving") then
  
    self.blueConvoyDead = self.blueConvoyDead + 1 
  
  end

end

---
-- @param #OFF_Mission02 self
function OFF_Mission02:OnConvoyRendezvous()

  self:Trace(1, "Convoy rendezvous")

  self:MessageAll(MessageLength.LessShort, 
    "[Bucky] Hello Colt this is Bucky. It is good to see you overhead. " ..
    "We think there are enemy units hiding in the town just east of our position. " ..
    "We don't have the luxury of time, so clear them out before we reach the town! Bucky Out.", 
    true)
    
  self.blueConvoyStopped:Destroy()
  self.blueConvoyMoving:Activate()
    
end

---
-- @param #OFF_Mission02 self
function OFF_Mission02:OnEnemeyDestroyed()

  self:Trace(1, "Enemey destroyed")
  self.enemyDestroyed = true

  self:MessageAll(MessageLength.LessShort, 
    "Bucky, this is Colt. We have taken out two enemy groups. The town looks clear now.", 
    true)

  self.moose.scheduler:New(nil, function()
    self:MessageAll(MessageLength.LessShort, 
      "Roger that Colt. We are happy to proceed. You may RTB. Bucky Out.",
      true)
  end, {}, 6)
  
end

---
-- @param #OFF_Mission02 self
function OFF_Mission02:AreAllEnemyDestroyed()

  for i = 1, #self.redMalitiaGroups do
    if self.redMalitiaGroups[i]:IsAlive() then
      return false
    end
  end

  for i = 1, #self.redRoadblockGroups do
    if self.redRoadblockGroups[i]:IsAlive() then
      return false
    end
  end
  
  return true

end

---
-- @param #OFF_Mission02 self
function OFF_Mission02:IsHalfOfConvoyDead()

  return self.blueConvoyDead >= self.blueConvoyMinAlive

end

---
-- @param #OFF_Mission02 self
function OFF_Mission02:OnMissionFailed()
  
  self:MessageAll(MessageLength.LessShort, "Convoy has been hit.", true)
    
end

OFF_Mission02 = createClass(Mission, OFF_Mission02)
