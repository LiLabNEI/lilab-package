classdef uLCDObj < handle
    %uLCD is rotated -90 degrees in rigA so that x and y are swapped
    %Commands are therefore swapped (e.g. spot(x,y) actually sends command
    %for circle(y,x)
    properties %(Access = private, Transient)
        serialPort
        baudRate = 875000
    end

    methods
        
        function obj = uLCDObj(port)
            if nargin < 1
                if strcmpi(util.getComputerID,'.B9655E47BAE8.C73F818834B3') % rigA
                    port = 'COM3';
                    obj.baudRate = 875000;
                elseif strcmpi(util.getComputerID,'.873F71E3EA21.8C634CCD9F92') %nih laptop
                    port = '/dev/tty.SLAB_USBtoUART';
                    obj.baudRate = 9600;
                else %rigB (2-photon)
                    port = 'COM9';
                    obj.baudRate = 875000;
                end
            end

            obj.serialPort = serial(port,'BaudRate',obj.baudRate);%default=9600%max=875000 
        end
        
        function delete(obj)
            obj.disconnect();
            delete(obj.serialPort);
        end
        
        function connect(obj)
            fopen(obj.serialPort);
            pause(5);
            obj.testconnection;
        end
        
        function disconnect(obj)
            fclose(obj.serialPort);
        end
        
        function close(obj)
            fclose(obj.serialPort);
        end
        
        function testconnection(obj)
            % Test connection by clearing screen and receiving acknowledgement
            fwrite(obj.serialPort,[255,130]);
            ack=fread(obj.serialPort,1);
            if ack==6
                fprintf('Connection is active\n')
            else
                fprintf('Unable to receive ACK\n')
            end
        end
        
        function clear(obj)
            % clear screen
            fwrite(obj.serialPort,[255,130]);
            %msg=fread(obj.serialPort,1);
        end
        
        function spot(obj,centerX,centerY,radius,hexcolor1,hexcolor2)
            % spot(obj,centerX,centerY,radius,hexcolor1,hexcolor2)
            % radius in pixels, color in hexadecimal format
            % default color is white
            % remember that in rigA, uLCD is mounted at -90 degrees so code
            % swaps X and Y in sent commands
            if isempty(hexcolor1)
                hexcolor1=255;
            end
            if isempty(hexcolor2)
                hexcolor2=255;
            end        
            centerX(centerX>220)=220/2;
            centerY(centerY>220)=220/2;
            % Outer circle
            fwrite(obj.serialPort,[255,119]);
            fwrite(obj.serialPort,[00,centerY]);
            fwrite(obj.serialPort,[00,centerX]);
            fwrite(obj.serialPort,[00,radius]);
            fwrite(obj.serialPort,[hexcolor1,hexcolor2]);
            %msg=fread(obj.serialPort,1);
        end
        
        function spot_white(obj,centerX,centerY,radius)
            obj.spot(centerX,centerY,radius,255,255);
        end
        
        function spot_black(obj,centerX,centerY,radius)
            obj.spot(centerX,centerY,radius,0,0);
        end
        
        function spot_red(obj,centerX,centerY,radius)
            obj.spot(centerX,centerY,radius,255/2,0/2);
        end
        
        function ring_white(obj,centerX,centerY,rInner,rOuter)
            % Outer circle
            spot_white(obj,centerX,centerY,rOuter);
            %Inner circle
            spot_black(obj,centerX,centerY,rInner); 
        end
        
        function ring_black(obj,centerX,centerY,rInner,rOuter)
            % Outer circle
            spot_black(obj,centerX,centerY,rOuter);
            %Inner circle
            spot_white(obj,centerX,centerY,rInner); 
        end
        
        function white2black(obj)
            % makes all white pixels black
            fwrite(obj.serialPort,[255,105,255,255,000,000]);
        end
        
        function black2white(obj)
             % makes all black pixels white
            fwrite(obj.serialPort,[255,105,000,000,255,255]);
        end
        
        function moveRing(obj,stX,stY,fX,fY,rInner,rOuter,frames)
            
            
            deltaX=abs(stX-fX)/frames;
            deltaY=abs(stY-fY)/frames;
            
            for f=0:frames
                obj.spot_black(stX+(deltaX*f),stY+(deltaY*f),rOuter);
                obj.ring_white(stX+(deltaX*f),stY+(deltaY*f),rInner,rOuter);
                if f>0
                    obj.spot_black(stX+(deltaX*(f-1)),stY+(deltaY*(f-1)),rOuter);
                end
                obj.spot_white(stX+(deltaX*f),stY+(deltaY*f),rOuter);
                obj.spot_black(stX+(deltaX*f),stY+(deltaY*f),rInner);
            end
        end
        
        function loomSpot(obj,centerX,centerY,stR,fR,frames)
            obj.clear;
            
            deltaR=abs(stR-fR)/frames;
            for f=0:frames
                obj.spot_white(centerX,centerY,stR+deltaR);
            end
        end
        
    end
    
end
