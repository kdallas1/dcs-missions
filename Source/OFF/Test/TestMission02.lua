skipMoose = true
dofile(baseDir .. "OFF/Mission02.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  mock.player1 = mock.moose:MockUnit({ name = "Colt #001" })
  mock.player2 = mock.moose:MockUnit({ name = "Colt #002" })

  mock.playerGroup1 = mock.moose:MockGroup({
    name = "Colt #001",
    units = { mock.player1, },
    IsAnyInZone = function() return false end
  })

  mock.playerGroup2 = mock.moose:MockGroup({
    name = "Colt #002",
    units = { mock.player2, },
    IsAnyInZone = function() return false end
  })

  mock.moose:MockZone({ name = "Player Parking" })
  mock.moose:MockZone({ name = "Start Convoy" })

  mock.moose:MockGroup({ name = "Blue Convoy Stopped" })
  mock.moose:MockGroup({ name = "Blue Convoy Moving" })

  for i = 1, 3, 1 do
    mock.moose:MockGroup({ name = "Red Units #00" .. i })
  end

  for i = 1, 3, 1 do
    mock.moose:MockGroup({ name = "Red Road Block #00" .. i })
  end

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = OFF_Mission02:New(args)
  mock.mission.playerTestOn = false

  return mock

end

local function Test_Start_Default_StateIsMissionStarted()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  TestAssertMissionState(MissionState.MissionStarted, mock.mission)

end

function Test_OFF_Mission02()
  return RunTests {
    "OFF_Mission02",
    Test_Start_Default_StateIsMissionStarted,
  }
end


testOnly = Test_OFF_Mission02
