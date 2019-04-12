classdef UVAmberLightCrafterDevice < nih.squirrellab.shared.devices.RiekeLightCrafterDevice

    
    properties
    end
    
    methods
        
        function obj = UVAmberLightCrafterDevice(varargin)
            %Make this LCR variation do all the normal LCR things on
            %creation:
            
            obj@nih.squirrellab.shared.devices.RiekeLightCrafterDevice(varargin{1}, varargin{2});
           
            %To correct for image inversion by the microscope optics
            obj.setImageOrientation(true,true);
            
            
            obj.addResource('ledOrder', {'560nm', '400nm', '460nm'});
            obj.addConfigurationSetting('lightCrafterLedCurrents',  [0, 0, 0], 'isReadOnly', true);
            
            obj.setLedCurrents(0,0,0);
        end
        
        
        
        
        
        
        function setLedCurrents(obj, amber, UV, blue)
            
            if amber < 0 || amber > 30
                error('Amber LED current must be below 30 per EKB specs');
            end
            
            setLedCurrents@nih.squirrellab.shared.devices.RiekeLightCrafterDevice(obj, amber, UV, blue);
        end
        
        
        function setImageOrientation(obj, a, b)
            setImageOrientation@nih.squirrellab.shared.devices.RiekeLightCrafterDevice(obj, a, b);
        end
    end
    
    

    
    
end

