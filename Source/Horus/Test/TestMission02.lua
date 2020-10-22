skipMoose = true
dofile(baseDir .. "Horus/Mission02.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)
  mock.dcs = MockDCS:New()
  
  mock.player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.playerGroup = mock.moose:MockGroup({
    name = "Dodge #001",
    units = { mock.player },
    IsAnyInZone = function() return false end
  })
  
  mock.moose:MockZone({ name = "Terrorists" })
  mock.moose:MockZone({ name = "Escape" })
  
  mock.moose:MockGroup({ name = "Rescue" })
  mock.moose:MockGroup({ name = "Terrorists", GetVelocityKNOTS = function() return 0 end })
  
  mock.moose:MockGroup({ name = "Enemy Jets" })
  mock.moose:MockGroup({ name = "Enemy APCs #001" })
  mock.moose:MockGroup({ name = "Enemy APCs #002" })
  mock.moose:MockGroup({ name = "Enemy APCs #003" })
  mock.moose:MockGroup({ name = "Scouts #001" })
  mock.moose:MockGroup({ name = "Scouts #002" })
  mock.moose:MockGroup({ name = "Scouts #003" })

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission02:New(args)

  return mock
  
end

local function Test_Start()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  TestAssert(
    mock.mission.state.current == MissionState.MissionStarted,
    "State should be: Mission accomplished")

end

function Test_Mission02()
  return RunTests {
    "Mission02",
    Test_Start
  }
end

--testOnly = Test_Mission02
