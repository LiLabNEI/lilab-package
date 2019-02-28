% A stage stimulus that contains the uLCD device

classdef uLCDStimulus < stage.core.Stimulus

    properties
        uLCD
        cmdCount = 0;
        presetFlag = 0;
    end

    properties (Access = private)

    end

    methods
        function resetFlags(uLCD)
           uLCD.cmdCount = 0;
           uLCD.presetFlag = 0;
           uLCD.ranOnce = 0;
           uLCD.ranTwice = 0;
        end
    end

    methods (Access = protected)
        function performDraw(obj)
            modelView = obj.canvas.modelView;
            modelView.push();
            modelView.pop();
        end
    end

end

