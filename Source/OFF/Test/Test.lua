dofile(baseDir .. "OFF/Test/TestMission01.lua")
dofile(baseDir .. "OFF/Test/TestMission02.lua")

function Test_OFF()
  RunTests {
    "OFF",
    Test_OFF_Mission01,
    Test_OFF_Mission02,
  }
end
