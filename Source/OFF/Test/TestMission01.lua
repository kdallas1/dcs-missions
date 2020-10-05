skipMoose = true
dofile(baseDir .. "OFF/Mission01.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  mock.player1 = mock.moose:MockUnit({ name = "Chevy #001" })
  mock.player2 = mock.moose:MockUnit({ name = "Chevy #002" })

  mock.playerGroup1 = mock.moose:MockGroup({
    name = "Chevy #001",
    units = { mock.player1, },
    IsAnyInZone = function() return false end
  })

  mock.playerGroup2 = mock.moose:MockGroup({
    name = "Chevy #002",
    units = { mock.player2, },
    IsAnyInZone = function() return false end
  })

  mock.moose:MockZone({ name = "Player Parking" })
  mock.moose:MockZone({ name = "Win" })
  mock.moose:MockZone({ name = "Lose" })
  mock.moose:MockZone({ name = "Stop Blue Spawn" })
  mock.moose:MockZone({ name = "Stop Red Spawn" })

  for i = 1, 3, 1 do
    mock.moose:MockGroup({ name = "Red Air #00" .. i })
  end

  for i = 1, 7, 1 do
    mock.moose:MockGroup({ name = "Red Tanks #00" .. i })
  end

  for i = 1, 3, 1 do
    mock.moose:MockGroup({ name = "Blue Tanks #00" .. i })
  end

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = OFF.Mission01:New(args)

  return mock

end

local function Test_Start_Default_StateIsMissionStarted()

  local mock = NewMock({
    trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  TestAssert(
    mock.mission.state.current == MissionState.MissionStarted,
    "State should be: Mission accomplished")

end

testOnly = Test_Start_Default_StateIsMissionStarted

local function Test_PlayerSpeedOver100_StateIsPlayerAirborne()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
    })

  mock.mission:Start()

  mock.player1.velocity = 101
  mock.player2.velocity = 101

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == OFF.Mission01.State.PlayersAirborne,
    "State should be: Players airborn")

end

local function Test_RedTanksInStopBlueSpawnZone_StateIsRedInStopSpawn()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
    })

  mock.mission:Start()

  mock.player1.velocity = 101
  mock.player2.velocity = 101

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == OFF.Mission01.State.PlayersAirborne,
    "State should be: Players airborn")

end

local function Test_BlueTanksInStopRedSpawnZone_StateIsBlueInStopSpawn()
end

local function Test_RedTanksInLoseZone_StateIsMissionFailed()
end

local function Test_BlueTanksInWinZone_StateIsBlueInWinZone()
end

local function Test_BlueTanksInWinZoneAndPlayersParked_MissionAccomplished()
end

function Test_OFF_Mission01()
  return RunTests {
    "OFF.Mission01",
    Test_Start_Default_StateIsMissionStarted,
    Test_PlayerSpeedOver100_StateIsPlayerAirborne,
    Test_RedTanksInStopBlueSpawnZone_StateIsRedInStopSpawn,
    Test_BlueTanksInStopRedSpawnZone_StateIsBlueInStopSpawn,
    Test_RedTanksInLoseZone_StateIsMissionFailed,
    Test_BlueTanksInWinZone_StateIsBlueInWinZone,
    Test_BlueTanksInWinZoneAndPlayersParked_MissionAccomplished
  }
end



--testOnly = Test_OFF_Mission01
