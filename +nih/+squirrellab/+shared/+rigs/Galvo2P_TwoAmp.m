classdef Galvo2P_TwoAmp < nih.squirrellab.shared.rigs.Galvo2p
    
%     Galvo2P_TwoAmp - This rig description is identical to Galvo2p, but
%     includes an extra Axopatch 200B amplifier.
%	  This is a placeholder for the future as we have only installed one amplifier in this rig.
%     
%     Last modified 03-18-2019 (Angueyra)
    
         amp2 = AxopatchDevice('Amp2').bindStream(daq.getStream('ao1'));
         amp2.bindStream(daq.getStream('ai4'), AxopatchDevice.SCALED_OUTPUT_STREAM_NAME);
         amp2.bindStream(daq.getStream('ai5'), AxopatchDevice.GAIN_TELEGRAPH_STREAM_NAME);
         amp2.bindStream(daq.getStream('ai6'), AxopatchDevice.MODE_TELEGRAPH_STREAM_NAME);
         obj.addDevice(amp2);
                        
        end
        
    end
    
end
