classdef uLCDDevice < symphonyui.core.Device
    
    properties %(Access = private, Transient)
        serial
    end
    
    methods
        
        function obj = uLCDDevice(varargin)
            ip = inputParser();
            ip.addParameter('comPort', 'COM9', @ischar);
            ip.parse(varargin{:});
            cobj = Symphony.Core.UnitConvertingExternalDevice('uLCD', '4D Systems', Symphony.Core.Measurement(0, symphonyui.core.Measurement.UNITLESS));
            cobj.MeasurementConversionTarget = symphonyui.core.Measurement.UNITLESS;
            obj@symphonyui.core.Device(cobj);
            
            obj.serial = 'COM9';%squirrellab.devices.uLCDObj(ip.Results.comPort);
            fprintf('Connected to uLCD\n')
        end
        
        function close(obj)
%             if ~isempty(obj.serial)
%                 obj.serial.disconnect();
%             end
        end
  
    end
    
end

