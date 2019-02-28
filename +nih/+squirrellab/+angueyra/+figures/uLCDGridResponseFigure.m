classdef uLCDGridResponseFigure < symphonyui.core.FigureHandler
    
    properties (SetAccess = private)
        ampDevice
        prepts
        stmpts
        datapts
        gridPatternX
        gridPatternY
        randOrder
        nX
        nY
        nTrials
    end
    
    properties (Access = private)
        axH
        rH
        currTrial
        minResponse
        maxResponse
    end
    
    methods
        
        function obj = uLCDGridResponseFigure(ampDevice, varargin)
            obj.ampDevice = ampDevice;            
            ip = inputParser();
            ip.addParameter('prepts', [], @(x)isvector(x));
            ip.addParameter('stmpts', [], @(x)isvector(x));
            ip.addParameter('datapts', [], @(x)isvector(x));
            ip.addParameter('gridPatternX', [], @(x)isvector(x));
            ip.addParameter('gridPatternY', [], @(x)isvector(x));
            ip.addParameter('currentX', [], @(x)isvector(x));
            ip.addParameter('currentY', [], @(x)isvector(x));
            ip.addParameter('randOrder', [], @(x)isvector(x));
            ip.addParameter('nX', [], @(x)isvector(x));
            ip.addParameter('nY', [], @(x)isvector(x));
            ip.addParameter('nTrials', [], @(x)isvector(x));
            ip.parse(varargin{:});

            obj.prepts = ip.Results.prepts;
            obj.stmpts = ip.Results.stmpts;
            obj.datapts = ip.Results.datapts;
            obj.gridPatternX = ip.Results.gridPatternX;
            obj.gridPatternY = ip.Results.gridPatternY;
            obj.randOrder = ip.Results.randOrder;
            obj.nX = ip.Results.nX;
            obj.nY = ip.Results.nY;
            obj.nTrials = ip.Results.nTrials;
            
            obj.createUi();
        end
        
        function createUi(obj)
            import appbox.*;
            
            obj.axH=gobjects(obj.nTrials);
            obj.rH=gobjects(obj.nTrials);
            
            obj.currTrial = 0;
            obj.minResponse = 0;
            obj.maxResponse = 0;
            
            spbuffer=.05/obj.nX;
            cnt=0;
            for y=1:obj.nX
                for x=1:obj.nY
                    cnt=cnt+1;
                    obj.axH(cnt) = axes( ...
                        'Parent', obj.figureHandle, ...
                        'Position',[(x-1+spbuffer)/obj.nX+spbuffer*2 (y-1+spbuffer)/obj.nY+spbuffer*2 1/obj.nX-(spbuffer*4) 1/obj.nY-(spbuffer*4)],...
                        'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                        'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                        'XTickMode', 'auto');

%                     obj.axH(cnt) = subplot(obj.nY,obj.nX,obj.nTrials-cnt,...
%                         'Parent', obj.figureHandle, ...
%                         'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
%                         'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
%                         'XTickMode', 'auto');
                    pretAx=(0:obj.datapts-1)/10000;
                    obj.rH(cnt)=line(pretAx,zeros(size(pretAx)),'Parent',obj.axH(cnt));
                end
            end
        end

        function setTitle(obj, t)
            set(obj.figureHandle, 'Name', t);
            title(obj.axesHandle, t);
        end

        function clear(obj)
            clf(obj.figureHandle)
            obj.createUi;
        end
        
        function handleEpoch(obj, epoch)
            %load amp data
            response = epoch.getResponse(obj.ampDevice);
            [epochResponse, units] = response.getData();
            sampleRate = response.sampleRate.quantityInBaseUnits;
            if numel(epochResponse) > 0
                tAx = (1:numel(epochResponse)) / sampleRate;
            else
                tAx = [];
            end
            
            obj.currTrial = mod(obj.currTrial+1,obj.nTrials);
            if obj.currTrial==0
                obj.currTrial=obj.nTrials;
            end
            % plot current response in appropriate subplot
            set(obj.rH(obj.randOrder(obj.currTrial)),'XData',tAx,'YData',epochResponse)
            
            maxR=max(epochResponse);
            if maxR > obj.maxResponse
                obj.maxResponse=maxR;
            end
            minR=min(epochResponse);
            if minR < obj.minResponse
                obj.minResponse=minR;
            end
            % update rescaling of all plots for comparison
            for i=1:obj.nTrials
                if obj.currTrial==1
                    set(obj.axH(i),'xlim',[min(tAx) max(tAx)])
                end
               set(obj.axH(i),'ylim',[obj.minResponse obj.maxResponse]) 
            end
        end
        
    end 
end
