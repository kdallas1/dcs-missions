dofile(baseDir .. "KD/Mission.lua")

---
-- @type OFF_Mission01
-- @extends KD.Mission#Mission
OFF_Mission01 = {
  className = "OFF_Mission01",

  enableDebugMenu = true,

  playerAirborneSpeed = 100,
  redTanksActive = true,
  blueTanksActive = true,
  redTankSpawnRate = 300,
  blueTankSpawnRate = 360,
  
  redAirSpawnMax = 3,
  redTanksSpawnerMax = 7,
  redTanksMaxPerSpawn = 3,
  blueTanksSpawnerMax = 3,
}

---
-- @type OFF_Mission01.State
-- @extends KD.Mission#MissionState
OFF_Mission01.State = {
  PlayersAirborne = State:NextState(),
  RedInStopSpawn = State:NextState(),
  BlueInStopSpawn = State:NextState(),
  BlueInWinZone = State:NextState(),
}

---
-- @param #OFF_Mission01 self
function OFF_Mission01:OFF_Mission01()

  self.blueInWinZone = false
  self.playersTookOff = false

  --self:SetTraceLevel(3)
  self.playerTestOn = false

  self.state:AddStates(OFF_Mission01.State)
  self.state:CopyTrace(self)

  self._playerPrefix = "Chevy"
  self._playerGroupName = "Chevy #001"

  self.playerParking = self:NewMooseZone("Player Parking")
  self.stopBlueSpawn = self:NewMooseZone("Stop Blue Spawn")
  self.stopRedSpawn = self:NewMooseZone("Stop Red Spawn")
  self.winZone = self:NewMooseZone("Win")
  self.loseZone = self:NewMooseZone("Lose")

  self.redAir = {}
  for i = 1, self.redAirSpawnMax do
    self.redAir[i] = self:GetMooseGroup("Red Air #00" .. i)
  end

  self.redTanks = {}
  for i = 1, self.redTanksSpawnerMax do
    self.redTanks[i] = self:NewMooseSpawn("Red Tanks #00" .. i)
  end

  self.blueTanks = {}
  for i = 1, self.blueTanksSpawnerMax do
    self.blueTanks[i] = self:NewMooseSpawn("Blue Tanks #00" .. i)
  end

  self.blueTankGroups = {}
  self.redTankGroups = {}

  self.state:TriggerOnce(
    OFF_Mission01.State.PlayersAirborne,
    function() return self:AreUnitsAirborne(self.players, self.playerAirborneSpeed) end,
    function()
      self.playersTookOff = true
      --self:BeginBattle()
    end
  )

  self.state:TriggerOnce(
    OFF_Mission01.State.RedInStopSpawn,
    function() return self:AreAnyGroupsInZone(self.redTankGroups, self.stopBlueSpawn) end,
    function()
      self.blueTanksActive = false
      self:MessageAll(MessageLength.Short, "No more blue reinforcements", true)
    end
  )

  self.state:TriggerOnce(
    OFF_Mission01.State.BlueInStopSpawn,
    function() return self:AreAnyGroupsInZone(self.blueTankGroups, self.stopRedSpawn) end,
    function()
      self.redTanksActive = false
      self:MessageAll(MessageLength.Short, "No more red reinforcements", true)
    end
  )

  self.state:TriggerOnce(
    OFF_Mission01.State.BlueInWinZone,
    function() return self:AreAnyGroupsInZone(self.blueTankGroups, self.winZone) end,
    function()
      self.blueInWinZone = true
      self:MessageAll(MessageLength.Short, "Blue tanks made it to the city", true)
    end
  )

  self.state:TriggerOnce(
    MissionState.MissionAccomplished,
    function() return self.blueInWinZone and self:UnitsAreParked(self.playerParking, self.players) end,
    function()
      if self.playersTookOff then
        self:MessageAll(MessageLength.Short, "Nice landing!", true)
      end
    end
  )

  self.state:TriggerOnce(
    MissionState.MissionFailed,
    function() return self:AreAnyGroupsInZone(self.redTankGroups, self.loseZone) end,
    function() self:MessageAll(MessageLength.Short, "Red tanks made it to our FARP", true) end
  )

end

---
-- @param #OFF_Mission01 self
function OFF_Mission01:OnStart()

  self:BeginBattle()

end

---
-- @param #OFF_Mission01 self
-- @param Wrapper.Unit#UNIT unit
function OFF_Mission01:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())

end

---
-- @param #OFF_Mission01 self
function OFF_Mission01:BeginBattle()

  self:MessageAll(MessageLength.VeryShort, "The battle has begun!", true)

  self:MessageAll(MessageLength.VeryShort, "Enemy air inbound", true)
  for i = 1, self.redAirSpawnMax do
    self.redAir[i]:Activate()
  end

  self.moose.scheduler:New(nil, function()
    self:Trace(1, "Red tanks spawn check, active=" .. Boolean:ToString(self.redTanksActive))

    if self.redTanksActive then

      local randoms = {}
      for i = 1, self.redTanksSpawnerMax do
        randoms[i] = i
      end
      List:Shuffle(randoms)

      self:MessageAll(MessageLength.VeryShort, "Red tanks inbound", true)
        
      for i = 1, self.redTanksMaxPerSpawn do
        local randomIndex = randoms[i]
        local spawner = self.redTanks[randomIndex]
        self.redTankGroups[#self.redTankGroups] = spawner:Spawn()
      end
    end
  end, {}, 0, self.redTankSpawnRate)

  self.moose.scheduler:New(nil, function()
    self:Trace(1, "Blue tanks spawn check, active=" .. Boolean:ToString(self.blueTanksActive))

    if self.blueTanksActive then
      
      self:MessageAll(MessageLength.VeryShort, "Blue tanks inbound", true)
      
      for i = 1, self.blueTanksSpawnerMax do
        self.blueTankGroups[#self.blueTankGroups] = self.blueTanks[i]:Spawn()
      end
    end
  end, {}, 0, self.blueTankSpawnRate)

end

---
-- @param #OFF_Mission01 self
function OFF_Mission01:AreAnyGroupsInZone(groups, zone)

  self:Trace(3, "Checking if groups are in zone. Zone=" .. zone:GetName() .. " Groups=" .. #groups)

  for i = 1, #groups do
    local group = groups[i]
    self:Trace(3, "Checking group:" .. group:GetName())
    
    if self:UnitsAreInZone(zone, group:GetUnits()) then
      self:Trace(3, "Group was in zone")
      return true
    end
  end

  self:Trace(3, "No groups were in the zone")
  return false

end

---
-- @param #OFF_Mission01 self
function OFF_Mission01:AreUnitsAirborne(units, speed)

  self:Trace(3, "No units to check if airborne")

  if #units == 0 then
    return false
  end

  self:Trace(3, "Checking if units airborn")

  local airbornCount = 0
  for i = 1, #units do
    local unit = units[i]
    self:Trace(3, "Checking unit name: " .. unit:GetName())
    self:Trace(3, "Checking unit velocity: " .. unit:GetVelocityKNOTS())

    if (unit:GetVelocityKNOTS() > speed) then
      airbornCount = airbornCount + 1
    end
  end

  self:Trace(3, "Unit count: " .. #units)
  self:Trace(3, "Airborne count: " .. airbornCount)

  return (airbornCount == #units)
end

OFF_Mission01 = createClass(Mission, OFF_Mission01)
