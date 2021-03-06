---------------------------------------------------------------------
-- Author: Lorenzos
-- Date: 27/03/19
-- Farming Simulator version: 19 -  patch 1.5.1.0
-- Script version: 0.5.4.0
---------------------------------------------------------------------
-- This is my first script in LUA
-- It's surely written quite bad, but at least it seems to work
---------------------------------------------------------------------

realAttacherJoints = {}
realAttacherJoints.modDir = g_currentModDirectory

function realAttacherJoints.prerequisitesPresent(specializations)
  if specializations ~= nil then -- << Fix for dataS/scripts/vehicles/SpecializationUtil.lua(103) bad argument 'pairs'
    return SpecializationUtil.hasSpecialization(AttacherJointControl, specializations)
  end
end

function realAttacherJoints.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "SetHeight", realAttacherJoints.SetHeight)
  SpecializationUtil.registerFunction(vehicleType, "GoToSavedHeight", realAttacherJoints.GoToSavedHeight)
  SpecializationUtil.registerFunction(vehicleType, "ToggleManualControl", realAttacherJoints.ToggleManualControl)
end

function realAttacherJoints.registerOverwrittenFunctions(vehicleType)
  SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", realAttacherJoints.loadInputAttacherJoint)
  SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", realAttacherJoints.getIsLowered)
end

function realAttacherJoints.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onDraw", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", realAttacherJoints)
  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", realAttacherJoints)
end

function realAttacherJoints:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
  if self.isClient then
    local spec = self.spec_attacherJointControl
    local isControllable = false
    for i=1,#self:getInputAttacherJoints() do
      local jointType = self:getInputAttacherJoints()[i].jointType
      if jointType == 2 or jointType == 3 or jointType == 7 then
        -- 2 == trailer, 3 == trailerLow, 7 == semitrailer --
        isControllable = false
        break
      elseif self:getInputAttacherJoints()[i].upperDistanceToGround == self:getInputAttacherJoints()[i].lowerDistanceToGround then
        isControllable = false
        break
      else
        isControllable = true
        break
      end
    end
    if isControllable == true then
      if isActiveForInputIgnoreSelection then
        realAttacherJoints.updateImplementControllabe(self)
      end
    end
  end
end

function realAttacherJoints.updateImplementControllabe(self)
  if self:getFullName() ~= nil then
    local spec = self.spec_attacherJointControl
    if realAttacherJoints.implements[self:getFullName()] then
      if realAttacherJoints.implements[self:getFullName()].isControllable == true then
        local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SET_HEIGHT, self, realAttacherJoints.SetHeight, false, true, false, true, nil)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
        g_inputBinding:setActionEventTextVisibility(actionEventId, true)
        local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.GO_TO_SAVED_HEIGHT, self, realAttacherJoints.GoToSavedHeight, false, true, false, true, nil)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
        g_inputBinding:setActionEventTextVisibility(actionEventId, true)
      end
    end
  end
end

function realAttacherJoints:loadMap()
  print("-------------------------- Loading realAttacherJoints.lua -------------------------")
  print("---- If you get bugs or errors please send me the log. Thank you ----")
  print("------------------ github.com/Lorenzoss/realAttacherJoints -----------------")
end

function realAttacherJoints:onLoad(savegame)
  self.realAttacherJoints = {}
  self.realAttacherJoints.square_img = createImageOverlay(realAttacherJoints.modDir .. "gui/sqr.dds")
  self.realAttacherJoints.greenPoint_img = createImageOverlay(realAttacherJoints.modDir .. "gui/greenPoint.dds")
  self.realAttacherJoints.redPoint_img = createImageOverlay(realAttacherJoints.modDir .. "gui/redPoint.dds")

  realAttacherJoints.implements = {}

  local spec = self.spec_attacherJointControl
  local isControllable = false
  for i=1,#self:getInputAttacherJoints() do
    local jointType = self:getInputAttacherJoints()[i].jointType
    if jointType == 2 or jointType == 3 or jointType == 7 then
      isControllable = false
      break
    elseif self:getInputAttacherJoints()[i].upperDistanceToGround == self:getInputAttacherJoints()[i].lowerDistanceToGround then
      isControllable = false -- For static three point implements
      break
    else
      isControllable = true
      break
    end
  end
  if isControllable then
    if #spec.controls == 0 then
      local controlFuncs = {"controlAttacherJointHeight", "controlAttacherJointTilt"}
      for _, controlFunc in pairs(controlFuncs) do
        local control = {}
        if controlFunc ~= nil and self[controlFunc] ~= nil then
          control.func = self[controlFunc]
          if control.func == self.controlAttacherJointHeight then
              spec.heightController = control
          end
        end
        local actionBindingName = nil
        if controlFunc == "controlAttacherJointHeight" then
          actionBindingName = "AXIS_HEIGHT_IMPLEMENT"
          if actionBindingName ~= nil and InputAction[actionBindingName] ~= nil then
            control.controlAction = InputAction[actionBindingName]
          end
          local iconName = "IMPLEMENT_ATTACHER_TRANS"
          if InputHelpElement.AXIS_ICON[iconName] == nil then
            iconName = (self.customEnvironment or "") .. iconName
          end
        elseif controlFunc == "controlAttacherJointTilt" then
          actionBindingName = "AXIS_TILT_IMPLEMENT"
          if actionBindingName ~= nil and InputAction[actionBindingName] ~= nil then
            control.controlAction = InputAction[actionBindingName]
          end
          local iconName = "IMPLEMENT_ATTACHER_ROTX"
          if InputHelpElement.AXIS_ICON[iconName] == nil then
            iconName = (self.customEnvironment or "") .. iconName
          end
        end
        control.axisActionIcon = iconName
        control.invertAxis = true
        control.mouseSpeedFactor = 0.175
        control.moveAlpha = 0
        spec.nameToControl[actionBindingName] = control
        table.insert(spec.controls, control)
      end
      if self.isClient then
        spec.lastMoveTime = 0
        spec.samples = {}
        if realAttacherJoints.hydraulicSound == nil then
          realAttacherJoints.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cylindered.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        end
        spec.samples.hydraulic = realAttacherJoints.hydraulicSound
      end
      if spec.jointDesc ~= nil then
        spec.jointDesc.lockDownRotLimit = true
        spec.jointDesc.lockUpRotLimit = true
      end
      spec.jointDesc = nil
      spec.dirtyFlag = self:getNextDirtyFlag()
    end
  end
end

function realAttacherJoints:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
  if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
    return false
  end
  inputAttacherJoint.isControllable = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isControllable"), true)
  return true
end

function realAttacherJoints:onPreAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex)
  -- Fix for "strange" rotation on first attach
  for _,v in pairs(attachableObject:getAttacherJoints()) do
    v.lockUpRotLimit = true
    v.lockDownRotLimit = true
  end
end

function realAttacherJoints:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
  if self.spec_attachable then
    local value = self.spec_attachable.attacherJoint.jointType
    if value == 2 or value == 3 or value == 7 then
      -- Not good for trailers and trailed implements
    else -- Fix for "strange" rotation on first attach
      for _,v in pairs(attacherVehicle:getAttacherJoints()) do
        v.lockUpRotLimit = true
        v.lockDownRotLimit = true
      end
    end
  end
end

function realAttacherJoints:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
  local implement = tostring(self:getFullName())
  local spec = self.spec_attacherJointControl
  spec.jointDescIndex = inputJointDescIndex
  if implement ~= nil then
    if realAttacherJoints.implements[implement] == nil then -- Create table for equipment for store data
      realAttacherJoints.implements[implement] = {}
    end
    if realAttacherJoints.implements[implement].isControllable == nil then
      if realAttacherJoints.implements[implement].jointDesc == nil then
        realAttacherJoints.implements[implement].jointDesc = spec.jointDesc -- Store jointDesc data for toggle manual control (AI)
      end
      realAttacherJoints.implements[implement].isControllable = true
      spec.jointDesc.lowerRotationOffset = spec.jointDesc.upperRotationOffset
      -- Save default groundReferenceNode force and powerConsumer maxForce for dynamic force
      local specPowerConsumer = self.spec_powerConsumer
      local specGRN = self.spec_groundReference
      if self.configFileName then
        local xmlFilename = self.configFileName
        local xmlFile = loadXMLFile("TempXML", xmlFilename)
        if specGRN ~= nil then
          if specGRN.hasForceFactors == true then
            realAttacherJoints.implements[implement].groundReferenceNodes = {}
            --for i,v in ipairs(specGRN.groundReferenceNodes) do
              local value = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNodes.groundReferenceNode#forceFactor"), 1)
              realAttacherJoints.implements[implement].groundReferenceNode = value
              --realAttacherJoints.implements[implement].groundReferenceNodes[i] = specGRN.groundReferenceNode.forceFactor
            --end
          end
        end
        if specPowerConsumer ~= nil then
          if specPowerConsumer.maxForce ~= nil then
            local value = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#maxForce"), 50)
            realAttacherJoints.implements[implement].maxForce = value
          end
        end
      end
    end
  end
end

function realAttacherJoints:onAIImplementStart()
  local spec = self.spec_attacherJointControl
  local inputAttacherJoints = self:getInputAttacherJoints()
  if spec.jointDescIndex then
    inputAttacherJoints[spec.jointDescIndex].isControllable = false
    if spec.jointDesc ~= nil then
      spec.jointDesc.allowsLowering = true
      spec.jointDesc.upperRotationOffset = spec.jointDesc.upperRotationOffsetBackup
      spec.jointDesc.lowerRotationOffset = spec.jointDesc.lowerRotationOffsetBackup
      spec.jointDesc = nil
    end
  end
end

function realAttacherJoints:onAIImplementEnd()
  local spec = self.spec_attacherJointControl
  local inputAttacherJoints = self:getInputAttacherJoints()
  local index = spec.jointDescIndex
  inputAttacherJoints[index].isControllable = true
  if inputAttacherJoints[index] ~= nil and inputAttacherJoints[index].isControllable then
    local jointDesc = realAttacherJoints.implements[self:getFullName()].jointDesc
    jointDesc.allowsLowering = true
    jointDesc.upperRotationOffsetBackup = jointDesc.upperRotationOffset
    jointDesc.lowerRotationOffsetBackup = jointDesc.lowerRotationOffset
    spec.jointDesc = jointDesc
    for _, control in ipairs(spec.controls) do
      control.moveAlpha = control.func(self)
    end
    spec.heightTargetAlpha = spec.jointDesc.upperAlpha
    self:requestActionEventUpdate()
  end
end

function realAttacherJoints:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
  if not self:getIsAIActive() then
    if self.typeName == "cultivator" or self.typeName == "plow" or self.typeName == "seeder" then
      local spec = self.spec_attacherJointControl
      local inputAttacherJoints = self:getInputAttacherJoints()
      if spec.jointDesc then
        if spec.jointDesc.index then
          if inputAttacherJoints[spec.jointDesc.index] then
            if inputAttacherJoints[spec.jointDesc.index].isControllable == true then -- Fix for helper
              if spec ~= nil then
                if spec.heightController ~= nil then
                  local moveAlpha = spec.heightController.moveAlpha
                  --self.spec_groundReference.groundReferenceNodes[1].depth
                  local specGRN = self.spec_groundReference
                  local specPowerConsumer = self.spec_powerConsumer
                  local implement = self:getFullName()
                  if implement ~= nil then
                    if realAttacherJoints.implements[implement] then
                      if specGRN ~= nil then
                        if specGRN.hasForceFactors == true then
                          for i=1,#specGRN.groundReferenceNodes do
                            specGRN.groundReferenceNodes[i].forceFactor = realAttacherJoints.implements[implement].groundReferenceNode * moveAlpha * 2
                          end
                        elseif specPowerConsumer ~= nil then
                          if specPowerConsumer.maxForce ~= nil then
                            specPowerConsumer.maxForce = realAttacherJoints.implements[implement].maxForce + moveAlpha * 75
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

function realAttacherJoints:SetHeight()
  local implement = self:getFullName()
  if implement ~= nil then
    if realAttacherJoints.implements[implement].isControllable == true then
      local spec = self.spec_attacherJointControl
      -- Save height value by implement name - Not sure it's the best way
      if implement ~= nil and spec.heightController.moveAlpha ~= nil then
        realAttacherJoints.implements[implement].presetHeightValue = spec.heightController.moveAlpha
        if self.spec_groundReference then
          realAttacherJoints.implements[implement].groundDepth = self.spec_groundReference.groundReferenceNodes[1].depth
        end
      end
    end
  end
end

function realAttacherJoints:GoToSavedHeight()
  local implement = self:getFullName()
  if implement ~= nil then
    if realAttacherJoints.implements[implement].isControllable == true then
      local spec = self.spec_attacherJointControl
      local presetHeightValue = realAttacherJoints.implements[implement].presetHeightValue
      -- It's practically impossible that presetHeightValue == moveAlpha
      local maxToleratedValue = spec.heightController.moveAlpha + 0.035
      local minToleratedValue = spec.heightController.moveAlpha - 0.035
      if not presetHeightValue then-- Check if a custom height value is already setted
        presetHeightValue = spec.jointDesc.lowerAlpha -- Lowest height value
      end
      if presetHeightValue >= minToleratedValue and presetHeightValue <= maxToleratedValue then
        spec.heightTargetAlpha = 0
      else
        spec.heightTargetAlpha = presetHeightValue
      end
    end
  end
end

function realAttacherJoints:ToggleManualControl()
  local spec = self.spec_attacherJointControl
  if self:getFullName() ~= nil then
    if realAttacherJoints.implements[self:getFullName()].isControllable == true then
      realAttacherJoints:disableManualControl(self)
    else
      realAttacherJoints:enableManualControl(self)
    end
  end
end

function realAttacherJoints:update(dt)
end

function realAttacherJoints:getIsLowered(superFunc, default)
  local spec = self.spec_foldable
  if self.spec_attachable.attacherJoint then
    local value = self.spec_attachable.attacherJoint.jointType
    if value == 2 or value == 3 or value == 7 then
      -- Nothing
    else
      if self.getIsFoldMiddleAllowed then
        if self:getIsFoldMiddleAllowed() then
          if spec.foldMiddleAnimTime ~= nil and spec.foldMiddleInputButton ~= nil then
            if spec.foldMoveDirection ~= 0 then
              if spec.foldMiddleDirection > 0 then
                if spec.foldAnimTime < spec.foldMiddleAnimTime + 0.01 then
                  return spec.foldMoveDirection < 0 and spec.moveToMiddle ~= true
                end
              else
                if spec.foldAnimTime > spec.foldMiddleAnimTime - 0.01 then
                  return spec.foldMoveDirection > 0 and spec.moveToMiddle ~= true
                end
              end
            else
              if spec.foldMiddleDirection > 0 and spec.foldAnimTime < 0.01 then
                return true
              elseif spec.foldMiddleDirection < 0 and math.abs(1.0 - spec.foldAnimTime) < 0.01 then
                return true
              end
            end
          return false
          end
        end
      end
    end
  end

  local spec = self.spec_attacherJointControl
  if spec.heightController then
    local showText = spec.jointDesc ~= nil
    if showText then
      if self:getControlAttacherJointDirection() then
        return false
      else
        return true
      end
    end
  end

  return superFunc(self, default)
end

function realAttacherJoints:onDraw()
  if self.isClient and self:getIsActive() and not g_gui:getIsGuiVisible() and not self:getIsAIActive() then
    local spec = self.spec_attacherJointControl
    local isControllable = false
    for i=1,#self:getInputAttacherJoints() do
      local jointType = self:getInputAttacherJoints()[i].jointType
      if jointType == 2 or jointType == 3 or jointType == 7 then
        isControllable = false
        break
      elseif self:getInputAttacherJoints()[i].upperDistanceToGround == self:getInputAttacherJoints()[i].lowerDistanceToGround then
        isControllable = false
        break
      else
        isControllable = true
        break
      end
    end

    if isControllable then
      local uiScale = g_gameSettings:getValue("uiScale")
      local iconWidth = 0.01 * uiScale
      local iconHeight = iconWidth * g_screenAspectRatio * 7
      local iconWidthPoint = 0.005 * uiScale
      local iconHeightPoint = iconWidth * g_screenAspectRatio / 2
      local cruiseOverlay = g_currentMission.inGameMenu.hud.speedMeter.overlay

      local startX_1 = cruiseOverlay.x + cruiseOverlay.width * 0.65 - 0.037
      local startX_2 = startX_1 + 0.0075
      local startY = cruiseOverlay.y + cruiseOverlay.height * 0.9

      local fontSize = g_gameSettings:getValue("uiScale") * 0.0125
      local angle = 0

      if self.spec_attacherJointControl then
        local maxTiltAngle = self.spec_attacherJointControl.maxTiltAngle/2
        local angleRadiant = map(self.spec_attacherJointControl.controls[2].moveAlpha, 0, 1, maxTiltAngle * -1, maxTiltAngle)
        angle = round((angleRadiant * 1 * 180) / math.pi)
        local startX_mid = (startX_2+0.001)
        setTextBold(true)
        setTextColor(1, 1, 1, 1)
        setTextAlignment(1) -- 1 = Centre alignment
        renderText(startX_mid, startY + iconHeight, fontSize, angle.."°")
      end
      renderOverlay(self.realAttacherJoints.square_img, startX_1, startY, iconWidth, iconHeight)
      if spec.heightController.moveAlpha then
        renderOverlay(self.realAttacherJoints.greenPoint_img, startX_1+0.0025, map(spec.heightController.moveAlpha, 1, 0, startY + 0.0085, startY + iconHeight - 0.017), iconWidthPoint, iconHeightPoint)
      end
      renderOverlay(self.realAttacherJoints.square_img, startX_2, startY, iconWidth, iconHeight)
      if self:getFullName() then
        if realAttacherJoints.implements then
          if realAttacherJoints.implements[self:getFullName()] then
            presetHeightValue = Utils.getNoNil(realAttacherJoints.implements[self:getFullName()].presetHeightValue, 1)
          end
        end
      end
      if presetHeightValue ~= nil then
        renderOverlay(self.realAttacherJoints.redPoint_img, startX_2+0.0025, map(presetHeightValue, 1, 0, startY + 0.0085, startY + iconHeight - 0.017), iconWidthPoint, iconHeightPoint)
      end
    end
  end
end

function realAttacherJoints:deleteMap()
end
function realAttacherJoints:mouseEvent(posX, posY, isDown, isUp, button)
end
function realAttacherJoints:keyEvent(unicode, sym, modifier, isDown)
end

function realAttacherJoints:disableManualControl(self)
  local spec = self.spec_attacherJointControl
  local inputAttacherJoints = self:getInputAttacherJoints()
  inputAttacherJoints[spec.jointDesc.index].isControllable = false
  if spec.jointDesc ~= nil then
    spec.jointDesc.allowsLowering = true
    spec.jointDesc.upperRotationOffset = spec.jointDesc.upperRotationOffsetBackup
    spec.jointDesc.lowerRotationOffset = spec.jointDesc.lowerRotationOffsetBackup
    spec.jointDesc = nil
  end
  realAttacherJoints.implements[self:getFullName()].isControllable = false
  self:requestActionEventUpdate()
end

function realAttacherJoints:enableManualControl(self)
  local spec = self.spec_attacherJointControl
  local inputAttacherJoints = self:getInputAttacherJoints()
  local index = realAttacherJoints.implements[self:getFullName()].jointDesc.index
  inputAttacherJoints[index].isControllable = true
  if inputAttacherJoints[index] ~= nil and inputAttacherJoints[index].isControllable then
    local jointDesc = realAttacherJoints.implements[self:getFullName()].jointDesc
    jointDesc.allowsLowering = true
    jointDesc.upperRotationOffsetBackup = jointDesc.upperRotationOffset
    jointDesc.lowerRotationOffsetBackup = jointDesc.lowerRotationOffset
    spec.jointDesc = jointDesc
    for _, control in ipairs(spec.controls) do
      control.moveAlpha = control.func(self)
    end
    spec.heightTargetAlpha = spec.jointDesc.upperAlpha self:requestActionEventUpdate()
  end
  realAttacherJoints.implements[self:getFullName()].isControllable = true
end

function map(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function round(x)
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

addModEventListener(realAttacherJoints)
