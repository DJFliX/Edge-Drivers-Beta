-- Copyright 2021 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local constants = require "st.zigbee.constants"
local clusters = require "st.zigbee.zcl.clusters"
local IlluminanceMeasurement = clusters.IlluminanceMeasurement

--- Temperature Mesurement config Samjin
local zcl_clusters = require "st.zigbee.zcl.clusters"
local tempMeasurement = zcl_clusters.TemperatureMeasurement
local device_management = require "st.zigbee.device_management"

-- preferences update
local function do_preferences(self, device)
  
  local have_temperature = "no"
  if device:get_manufacturer() == "Samjin" then
    have_temperature = "yes"
  elseif device:get_manufacturer() == "HiveHome.com" then
    have_temperature = "yes"
  elseif device:get_manufacturer() == "SmartThings" then
    have_temperature = "yes"
  elseif device:get_manufacturer() == "CentraLite" then
    have_temperature = "yes"  
  elseif device:get_manufacturer() == "Bosch" then
    have_temperature = "yes"
  elseif device:get_model() == "MOSZB-140" then
    have_temperature = "yes"
  end
  
  if have_temperature == "yes" then
   local manufacturer = device:get_manufacturer()
   local model =device:get_model()
   print("Manufacturer, Model",manufacturer, model)
   for id, value in pairs(device.preferences) do
    print("device.preferences[infoChanged]=", device.preferences[id], "preferences: ", id)
    local oldPreferenceValue = device:get_field(id)
    local newParameterValue = device.preferences[id]
     if oldPreferenceValue ~= newParameterValue then
      device:set_field(id, newParameterValue, {persist = true})
      print("<< Preference changed: name, old, new >>", id, oldPreferenceValue, newParameterValue)
      if  id == "maxTime" or id == "changeRep" then
        local maxTime = device.preferences.maxTime * 60
        local changeRep = device.preferences.changeRep
         print ("maxTime y changeRep: ", maxTime, changeRep)
          device:send(device_management.build_bind_request(device, tempMeasurement.ID, self.environment_info.hub_zigbee_eui))
          device:send(tempMeasurement.attributes.MeasuredValue:configure_reporting(device, 30, maxTime, changeRep))
          --device:configure()
      end
     end
  end
 end
end


local zigbee_motion_driver = {
  supported_capabilities = {
    capabilities.motionSensor,
    --capabilities.temperatureMeasurement,
    capabilities.relativeHumidityMeasurement,
    capabilities.battery,
    capabilities.presenceSensor,
    capabilities.contactSensor,
    capabilities.illuminanceMeasurement,
    capabilities.refresh
  },
  lifecycle_handlers = {
    infoChanged = do_preferences
},  
  sub_drivers = { require("aurora"),
                  require("ikea"),
                  require("iris"),
                  require("gatorsystem"),
                  require("motion_timeout"),
                  require("nyce"),
                  require("zigbee-plugin-motion-sensor"),
                  require("smartthings"),
                  require("samjin"),
  },
  ias_zone_configuration_method = constants.IAS_ZONE_CONFIGURE_TYPE.AUTO_ENROLL_RESPONSE
}

defaults.register_for_default_handlers(zigbee_motion_driver, zigbee_motion_driver.supported_capabilities)
local motion = ZigbeeDriver("zigbee-motion", zigbee_motion_driver)
motion:run()
