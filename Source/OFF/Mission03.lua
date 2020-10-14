dofile(baseDir .. "KD/Mission.lua")

---
-- @type OFF_Mission03
-- @extends KD.Mission#Mission
OFF_Mission03 = {
  className = "OFF_Mission03",

  enableDebugMenu = true,
  
  redMalitiaOptions = 3,
  redRoadblockOptions = 3,
  redDeadCount = 0,
  redDeadMin = 6,
  
  blueConvoyDead = 0,
  blueConvoyMinAlive = 4
}

---
-- @type OFF_Mission03.State
-- @extends KD.Mission#MissionState
OFF_Mission03.State = {
  ConvoyRendezvous = State:NextState(),
  EnemeyDestroyed = State:NextState(),
}

---
-- @param #OFF_Mission03 self
function OFF_Mission03:OFF_Mission03()

  self.enemyDestroyed = false

  --self:SetTraceLevel(3)
  self.playerTestOn = false
  self.testPlayerGroupName = "Test"
  self.testPlayerUnitName = "Test"

  self.state:AddStates(OFF_Mission03.State)
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
    OFF_Mission03.State.ConvoyRendezvous,
    function() return self:AreAnyGroupsInZone(self.startConvoy, self.playerGroups) end,
    function() self:OnConvoyRendezvous() end
  )

  self.state:TriggerOnce(
    OFF_Mission03.State.EnemeyDestroyed,
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
-- @param #OFF_Mission03 self
function OFF_Mission03:OnStart()
    
  if self.enableDebugMenu then
    self:CreateDebugMenu({
      self.playerGroups,
      self.redMalitiaGroups,
      self.redRoadblockGroups,
    })
  end

end

---
-- @param #OFF_Mission03 self
-- @param Wrapper.Unit#UNIT unit
function OFF_Mission03:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())
  
  if string.match(unit:GetName(), "Blue Convoy Moving") then
    
    self.blueConvoyDead = self.blueConvoyDead + 1 
    self:MessageAll(MessageLength.LessShort, "Colt, Bucky, we are taking losses!", true)
  
  end

  if string.match(unit:GetName(), "Red") then
    
    self.redDeadCount = self.redDeadCount + 1 
    self:MessageAll(MessageLength.LessShort, "Enemy unit dead", true)
  
  end

end

---
-- @param #OFF_Mission03 self
function OFF_Mission03:OnConvoyRendezvous()

  self:Trace(1, "Convoy rendezvous")

  self:MessageAll(MessageLength.LessShort, 
    "Hello Colt this is Bucky. We are ready to start moving through the town toward the bridge." ..
    "Move to WP2 and take out any approching emeny vehicles to keep us safe. Bucky Out.",
    true)
    
  self.blueConvoyStopped:Destroy()
  self.blueConvoyMoving:Activate()

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

end

---
-- @param #OFF_Mission03 self
function OFF_Mission03:OnEnemeyDestroyed()

  self:Trace(1, "Enemey destroyed")
  self.enemyDestroyed = true

  self:MessageAll(MessageLength.LessShort, 
    "Bucky, this is Colt. We have taken out two seperate groups moving this way. You should be clear now. Over.", 
    true)

  self:Schedule(function()
    self:MessageAll(MessageLength.LessShort, 
      "Roger that Colt. We will be over the bridge shortly. You may RTB or continue to orbit until Bingo Fuel, just to make sure.  Bucky Out.",
      true)
  end, 6)

  self:LandTestPlayers(self.moose.airbase.Caucasus.Anapa_Vityazevo, 300)

end

---
-- @param #OFF_Mission03 self
function OFF_Mission03:AreAllEnemyDestroyed()

  return self.redDeadCount >= self.redDeadMin

end

---
-- @param #OFF_Mission03 self
function OFF_Mission03:IsHalfOfConvoyDead()

  return self.blueConvoyDead >= self.blueConvoyMinAlive

end

---
-- @param #OFF_Mission03 self
function OFF_Mission03:OnMissionFailed()
  
  self:MessageAll(MessageLength.LessShort, "Enemy units have hit us hard. We have taken too many losses", true)
    
end

OFF_Mission03 = createClass(Mission, OFF_Mission03)
