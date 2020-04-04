g_specializationManager:addSpecialization('realAttacherJoints', 'realAttacherJoints', Utils.getFilename('realAttacherJoints.lua', g_currentModDirectory), true, nil)
for vehicleName,vehicleType in pairs(g_vehicleTypeManager.vehicleTypes) do
  if vehicleName == "implement" then
    if false == SpecializationUtil.hasSpecialization(AttacherJointControl, vehicleType.specializations) then
      g_vehicleTypeManager:addSpecialization(vehicleName, "attacherJointControl")
      --print("attacherJointControl added to: " .. vehicleName)
    end
    if false == SpecializationUtil.hasSpecialization(realAttacherJoints, vehicleType.specializations) then
      g_vehicleTypeManager:addSpecialization(vehicleName, "realAttacherJoints")
      --print("realAttacherJoints added to: " .. vehicleName)
    end
  end
  if vehicleType.specializations ~= nil then
    if  true == SpecializationUtil.hasSpecialization(Attachable, vehicleType.specializations) then
      if true == SpecializationUtil.hasSpecialization(Cultivator, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(Seeder, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(Plow, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(Sprayer, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(Spreader, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(Windrower, vehicleType.specializations)
      --or true == SpecializationUtil.hasSpecialization(Mower, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(Tedder, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(TreePlanter, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(SowingMachine, vehicleType.specializations)
      or true == SpecializationUtil.hasSpecialization(Trailer, vehicleType.specializations)
      then
        if false == SpecializationUtil.hasSpecialization(AttacherJointControl, vehicleType.specializations) then
          g_vehicleTypeManager:addSpecialization(vehicleName, "attacherJointControl")
          --print("attacherJointControl added to: " .. vehicleName)
        end
        if false == SpecializationUtil.hasSpecialization(realAttacherJoints, vehicleType.specializations) then
          g_vehicleTypeManager:addSpecialization(vehicleName, "realAttacherJoints")
          --print("realAttacherJoints added to: " .. vehicleName)
        end
      end
    end
  end
end
