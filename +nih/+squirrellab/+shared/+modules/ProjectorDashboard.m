classdef ProjectorDashboard < symphonyui.ui.Module

    
    % Modified version of LightCrafterControl module taken from Rieke lab
    % package.
    
    % Started 3-22-2019.
    % I'm taking a hard stand on "auto" LED setting. It seems like a good
    % way to make mistakes and it's quite easy to select multiple LED
    % checkboxes instead (intuitive too).
    
    
    properties (Access = private)
        log
        settings
        lightCrafter
        ledEnableCheckboxes
        ledCurrentEditboxes
        ledCurrentSliders
        patternRatePopupMenu
        centerOffsetFields
        prerenderCheckbox
        listenerHandles
        ledCurrents = struct('amber', 30, 'uv', 50, 'blue', 50);
        
        
        filterWheel
        ndfWheelButtons
        ndfPosition
        currentNdf
        ndfs = [0.0, 0.5, 1.0, 2.0, 3.0, 4.0]; 
    end
    
    methods
        
        function obj = ProjectorDashboard()
            obj.log = log4m.LogManager.getLogger(class(obj));
            obj.settings = nih.squirrellab.shared.modules.settings.LightCrafterControlSettings();
        end
        
        function createUi(obj, figureHandle)
            
            
            import appbox.*;



            set(figureHandle, ...
                'Name', 'Projector Dashboard', ...
                'Position', [100,100,350, 350], ...
                'Resize', 'off','toolbar','none','menubar','none');

            mainLayout = uix.VBox( ...
                'Parent', figureHandle, ...
                'Padding', 11, ...
                'Spacing', 7, 'backgroundcolor','w');
            
            

            lightCrafterLayout = uix.Grid( ...
                'Parent', mainLayout, ...
                'Spacing', 7,'backgroundcolor','w');

            %Grid element 1
            Label( ...
                'Parent', lightCrafterLayout, ...
                'String', 'LED enables:','backgroundcolor','w');
            %Grid element 1.5
            Label( ...
                'Parent', lightCrafterLayout, ...
                'String', 'LED currents:','backgroundcolor','w');

            %Grid element 2
            Label( ...
                'Parent', lightCrafterLayout, ...
                'String', 'Pattern rate:','backgroundcolor','w');
            %Grid element 3
            Label( ...
                'Parent', lightCrafterLayout, ...
                'String', 'Center offset (um):','backgroundcolor','w');
            %Grid element 4
            Label( ...
                'Parent', lightCrafterLayout, ...
                'String', 'Prerender:','backgroundcolor','w');



            %Grid element 5
            ledEnablesLayout = uix.HBox( ...
                'Parent', lightCrafterLayout, ...
                'Spacing', 3, 'backgroundcolor','w');

            obj.ledEnableCheckboxes.amber = uicontrol( ...
                'Parent', ledEnablesLayout, ...
                'Style', 'checkbox', ...
                'HorizontalAlignment', 'left', ...
                'String', '560 nm', ...
                'backgroundcolor','w', ...
                'Callback',  @obj.toggleLed);
            obj.ledEnableCheckboxes.uv = uicontrol( ...
                'Parent', ledEnablesLayout, ...
                'Style', 'checkbox', ...
                'HorizontalAlignment', 'left', ...
                'String', '400 nm', ...
                'backgroundcolor','w', ...
                'Callback',  @obj.toggleLed);
            obj.ledEnableCheckboxes.blue = uicontrol( ...
                'Parent', ledEnablesLayout, ...
                'Style', 'checkbox', ...
                'HorizontalAlignment', 'left', ...
                'String', '460 nm', ...
                'backgroundcolor','w', ...
                'Callback',  @obj.toggleLed);
            


            %Grid element 5.5
            ledCurrentsLayout = uix.HBox( ...
                'Parent', lightCrafterLayout, ...
                'Spacing', 3, 'backgroundcolor','w');

            %Dummy spacer label
            Label( ...
                'Parent', ledCurrentsLayout, ...
                'String', '', 'backgroundcolor','w');
            
            obj.ledCurrentSliders.amber = uicontrol( ...
                'Parent', ledCurrentsLayout, ...
                'Style', 'slider', ...
                'String', 'Auto','backgroundcolor',[0.8 0.4 0.0], 'callback',@obj.editAmberLedCurrent, ...
                'sliderstep',[1.0/(30) 0.35],'min',0','max',30,'value',obj.ledCurrents.amber, ...
                'pos',[38.333 48 30 25],'horizontalalignment','center');
            
            %Dummy spacer label
            Label( ...
                'Parent', ledCurrentsLayout, ...
                'String', '', 'backgroundcolor','w');
            
            
            
            
            
            amberEditBoxSpacerLayout = uix.VBox( ...
                'Parent', ledCurrentsLayout, ...
                'Spacing', 3, 'backgroundcolor','w');            

            %Dummy spacer label
            Label( ...
                'Parent', amberEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', amberEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            obj.ledCurrentEditboxes.amber = uicontrol( ...
                'Parent', amberEditBoxSpacerLayout, ...
                'Style', 'edit','horizontalalignment','center', ...
                'HorizontalAlignment', 'left','string',obj.ledCurrents.amber, ...
                'Callback',  @obj.editAmberLedCurrent);
            %Dummy spacer label
            Label( ...
                'Parent', amberEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', amberEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
 
            addlistener(obj.ledCurrentSliders.amber,'Value','PostSet',@(~,~)set(obj.ledCurrentEditboxes.amber,'string',round(get(obj.ledCurrentSliders.amber,'value'))));
            addlistener(obj.ledCurrentSliders.amber,'Value','PostSet',@(~,~)set(obj.ledCurrentEditboxes.amber,'foregroundcolor','r'));

            
            
            % UV LED control
            %Dummy spacer label
            Label( ...
                'Parent', ledCurrentsLayout, ...
                'String', '', 'backgroundcolor','w');
            
            obj.ledCurrentSliders.uv = uicontrol( ...
                'Parent', ledCurrentsLayout, ...
                'Style', 'slider', ...
                'HorizontalAlignment', 'left', ...
                'String', 'Red','backgroundcolor',[0.4 0.0 0.4], 'callback', @obj.editUvLedCurrent, ...
                'sliderstep',[1.0/(255) 0.35],'min',0','max',255,'value',obj.ledCurrents.uv);
            
            %Dummy spacer label
            Label( ...
                'Parent', ledCurrentsLayout, ...
                'String', '', 'backgroundcolor','w');
            
            
            
            
            uvEditBoxSpacerLayout = uix.VBox( ...
                'Parent', ledCurrentsLayout, ...
                'Spacing', 3, 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', uvEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', uvEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            obj.ledCurrentEditboxes.uv = uicontrol( ...
                'Parent', uvEditBoxSpacerLayout, ...
                'Style', 'edit','horizontalalignment','center', ...
                'HorizontalAlignment', 'left','string',obj.ledCurrents.uv, ...
                'Callback', @obj.editUvLedCurrent);
            %Dummy spacer label
            Label( ...
                'Parent', uvEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', uvEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');

            addlistener(obj.ledCurrentSliders.uv,'Value','PostSet',@(~,~)set(obj.ledCurrentEditboxes.uv,'string',round(get(obj.ledCurrentSliders.uv,'value'))));
            addlistener(obj.ledCurrentSliders.uv,'Value','PostSet',@(~,~)set(obj.ledCurrentEditboxes.uv,'foregroundcolor','r'));
            
            
            
            
            
            
            
            %Dummy spacer label
            Label( ...
                'Parent', ledCurrentsLayout, ...
                'String', '', 'backgroundcolor','w');
            
            obj.ledCurrentSliders.blue = uicontrol( ...
                'Parent', ledCurrentsLayout, ...
                'Style', 'slider', ...
                'HorizontalAlignment', 'left', ...
                'String', 'Green','backgroundcolor',[0.0 0.0 0.8], 'callback', @obj.editBlueLedCurrent, ...
                'sliderstep',[1.0/(255) 0.35],'min',0','max',255,'value',obj.ledCurrents.blue);
            
            %Dummy spacer label
            Label( ...
                'Parent', ledCurrentsLayout, ...
                'String', '', 'backgroundcolor','w');
            
            blueEditBoxSpacerLayout = uix.VBox( ...
                'Parent', ledCurrentsLayout, ...
                'Spacing', 3, 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', blueEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', blueEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            obj.ledCurrentEditboxes.blue = uicontrol( ...
                'Parent', blueEditBoxSpacerLayout, ...
                'Style', 'edit','horizontalalignment','center', ...
                'HorizontalAlignment', 'left','string',obj.ledCurrents.blue, ...
                'Callback',  @obj.editBlueLedCurrent);
            %Dummy spacer label
            Label( ...
                'Parent', blueEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');
            %Dummy spacer label
            Label( ...
                'Parent', blueEditBoxSpacerLayout, ...
                'String', '', 'backgroundcolor','w');

            addlistener(obj.ledCurrentSliders.blue,'Value','PostSet',@(~,~)set(obj.ledCurrentEditboxes.blue,'string',round(get(obj.ledCurrentSliders.blue,'value'))));
            addlistener(obj.ledCurrentSliders.blue,'Value','PostSet',@(~,~)set(obj.ledCurrentEditboxes.blue,'foregroundcolor','r'));

            
            set(ledCurrentsLayout, ...
                'Widths', [10, 20, 5, -1, 10, 20, 5, -1, 10, 20, 5, -1]);
            

            %Grid element 6
            obj.patternRatePopupMenu = MappedPopupMenu( ...
                'Parent', lightCrafterLayout, ...
                'String', {' '}, ...
                'HorizontalAlignment', 'left');


            %Grid element 7
            offsetLayout = uix.HBox( ...
                'Parent', lightCrafterLayout, ...
                'Spacing', 5, 'backgroundcolor','w');
            obj.centerOffsetFields.x = uicontrol( ...
                'Parent', offsetLayout, ...
                'Style', 'edit', ...
                'HorizontalAlignment', 'left', ...
                'Callback', @obj.onSetCenterOffset);
            Label( ...
                'Parent', offsetLayout, ...
                'String', 'X','backgroundcolor','w');
            obj.centerOffsetFields.y = uicontrol( ...
                'Parent', offsetLayout, ...
                'Style', 'edit', ...
                'HorizontalAlignment', 'left', ...
                'Callback', @obj.onSetCenterOffset);
            Label( ...
                'Parent', offsetLayout, ...
                'String', 'Y','backgroundcolor','w');
            set(offsetLayout, ...
                'Widths', [-1 8+5 -1 8]);

            %Grid element 8
            obj.prerenderCheckbox = uicontrol( ...
                'Parent', lightCrafterLayout, ...
                'Style', 'checkbox', ...
                'String', '','backgroundcolor','w', ...
                'Callback', @obj.onSelectedPrerender);

            set(lightCrafterLayout, ...
                'Widths', [100 -1], ...
                'Heights', [23 120 23 23 23]);



            Label( ...
                'Parent', mainLayout, ...
                'String', 'NDF Wheel Selection:','backgroundcolor','w');

            ndfWheelLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);

            bg = uibuttongroup(ndfWheelLayout,'Visible','on',...
                              'Position',[0 0 .2 1],'backgroundcolor','w','bordertype','none');


            obj.ndfWheelButtons(1) = uicontrol(bg,'Style',...
                              'togglebutton',...
                              'String','0.0',...
                              'Position',[0+12 0 49 49],...
                              'HandleVisibility','off', ...
                              'Callback', @obj.setNdf1);

            obj.ndfWheelButtons(2) = uicontrol(bg,'Style',...
                              'togglebutton',...
                              'String','0.5',...
                              'Position',[50+12 0 49 49],...
                              'HandleVisibility','off', ...
                              'Callback', @obj.setNdf2);

            obj.ndfWheelButtons(3) = uicontrol(bg,'Style',...
                              'togglebutton',...
                              'String','1.0',...
                              'Position',[100+12 0 49 49],...
                              'HandleVisibility','off', ...
                              'Callback', @obj.setNdf3);

            obj.ndfWheelButtons(4) = uicontrol(bg,'Style',...
                              'togglebutton',...
                              'String','2.0',...
                              'Position',[150+12 0 49 49],...
                              'HandleVisibility','off', ...
                              'Callback', @obj.setNdf4);

            obj.ndfWheelButtons(5) = uicontrol(bg,'Style',...
                              'togglebutton',...
                              'String','3.0',...
                              'Position',[200+12 0 49 49],...
                              'HandleVisibility','off', ...
                              'Callback', @obj.setNdf5);

            obj.ndfWheelButtons(6) = uicontrol(bg,'Style',...
                              'togglebutton',...
                              'String','4.0',...
                              'Position',[250+12 0 49 49],...
                              'HandleVisibility','off', ...
                              'Callback', @obj.setNdf6);



            
            set(mainLayout,'heights',[240, 23, -1]);

            set(obj.ledCurrentEditboxes.amber,'horizontalalignment','center')
            set(obj.ledCurrentEditboxes.uv,'horizontalalignment','center')
            set(obj.ledCurrentEditboxes.blue,'horizontalalignment','center')
 

        end
        
    end
    
    
    
    
    
    methods (Access = protected)
        
        function willGo(obj)
            devices = obj.configurationService.getDevices('LightCrafter');
            if isempty(devices)
                error('No LightCrafter device found');
            end
            obj.lightCrafter = devices{1};
            
            
            devices = obj.configurationService.getDevices('Filter Wheel');
            if isempty(devices)
                error('No filterWheel device found');
            end
            obj.filterWheel = devices{1};
            
            %Here do the start-up stuff
            
            
            obj.setLedCurrents();
            
            obj.populateLedEnables();
            obj.populatePatternRateList();
            obj.populateCenterOffset();
            obj.populatePrerender();
            
            
            ndf = obj.filterWheel.getNDF();
            obj.currentNdf = ndf;
            obj.ndfPosition = find(obj.currentNdf==obj.ndfs);
            set(obj.ndfWheelButtons(obj.ndfPosition), 'value', 1);
            
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load settings: ' x.message], x);
            end
        end
        
        function willStop(obj)
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save settings: ' x.message], x);
            end
        end
        
    end
    
    methods (Access = private)
        
        function populateLedEnables(obj,~)
            %Kill auto mode if it's on
            [~, amber, uv, blue] = obj.lightCrafter.getLedEnables();
            obj.lightCrafter.setLedEnables(0, amber, uv, blue);
            
            %Just temporarily setting this for testing purposes
%             amber = 1;
%             uv = 1;
%             blue = 0;

            set(obj.ledEnableCheckboxes.amber, 'Value', amber);
            set(obj.ledEnableCheckboxes.uv, 'Value', uv);
            set(obj.ledEnableCheckboxes.blue, 'Value', blue);
            
            obj.toggleLed([], []);
        end
        
        function onSelectedLedEnable(obj, ~, ~)
            auto = 0; %get(obj.ledEnablesCheckboxes.auto, 'Value');
            red = get(obj.ledEnablesCheckboxes.red, 'Value');
            green = get(obj.ledEnablesCheckboxes.green, 'Value');
            blue = get(obj.ledEnablesCheckboxes.blue, 'Value');
            obj.lightCrafter.setLedEnables(auto, red, green, blue);
        end
        
        
        
        
        function editAmberLedCurrent(obj, ~, ~)
            editLedCurrent(obj, 'amber', 30)
        end
        
        function editUvLedCurrent(obj, ~, ~)
            editLedCurrent(obj, 'uv', 255)
        end
        
        function editBlueLedCurrent(obj, ~, ~)
            editLedCurrent(obj, 'blue', 255)
        end
        
        function editLedCurrent(obj, color, maxValue)
            
            oldValue = obj.ledCurrents.(color);
            newValue = str2double(get(obj.ledCurrentEditboxes.(color),'String'));
            
            
            if isnan(newValue)
                set(obj.ledCurrentEditboxes.(color),'string', oldValue);
                return
                
            elseif newValue > maxValue 
                set(obj.ledCurrentEditboxes.(color),'string', maxValue);
                set(obj.ledCurrentSliders.(color),'value', maxValue);
                obj.ledCurrents.(color) = maxValue;
                setLedCurrents(obj);
                return
                
            elseif newValue < 0
                set(obj.ledCurrentEditboxes.(color),'string', 0);
                set(obj.ledCurrentSliders.(color),'value', 0);
                obj.ledCurrents.(color) = 0;
                setLedCurrents(obj);
                return
                
            else
                set(obj.ledCurrentSliders.(color),'value', newValue);
                obj.ledCurrents.(color) = newValue;
                setLedCurrents(obj);
                return
            end
        end
        
        
        function setLedCurrents(obj)    
            set(obj.ledCurrentEditboxes.amber,'foregroundcolor','k')
            set(obj.ledCurrentEditboxes.uv,'foregroundcolor','k')
            set(obj.ledCurrentEditboxes.blue,'foregroundcolor','k')
            
            obj.lightCrafter.setLedCurrents(obj.ledCurrents.amber, obj.ledCurrents.uv, obj.ledCurrents.blue);
%             disp(['currents set: ' num2str(obj.ledCurrents.amber) ' ' num2str(obj.ledCurrents.uv) ' ' num2str(obj.ledCurrents.blue)]);
        end
        
        function toggleLed(obj, ~, ~)
            amber = get(obj.ledEnableCheckboxes.amber,'value');
            uv = get(obj.ledEnableCheckboxes.uv,'value');
            blue = get(obj.ledEnableCheckboxes.blue,'value');

            % Setting first argument to 0 to disable "auto" mode entirely
            obj.lightCrafter.setLedEnables(0, amber, uv, blue);
            
            for color = {'amber', 'uv', 'blue'}
                
                switch color{:}
                    case 'amber'
                        bg_color = [0.8 0.4 0.0];
                        ledOn = amber;
                    case 'uv'
                        bg_color = [0.4 0.0 0.4];
                        ledOn = uv;
                    case 'blue'
                        bg_color = [0.0 0.0 0.8];
                        ledOn = blue;
                end

                
                if ledOn
                    set(obj.ledCurrentSliders.(color{:}),'enable','on','backgroundcolor',bg_color);
                    set(obj.ledCurrentEditboxes.(color{:}),'enable','on');
                else
                    set(obj.ledCurrentSliders.(color{:}),'enable','inactive','backgroundcolor',0.94*[1 1 1]);
                    set(obj.ledCurrentEditboxes.(color{:}),'enable','off');
                end
                
            end
        end
        
        function populatePatternRateList(obj)
            rates = obj.lightCrafter.availablePatternRates();
            names = cellfun(@(r)[num2str(r) ' Hz'], rates, 'UniformOutput', false); 
            
            set(obj.patternRatePopupMenu, 'String', names);
            set(obj.patternRatePopupMenu, 'Values', rates);
            
            set(obj.patternRatePopupMenu, 'Value', obj.lightCrafter.getPatternRate());
        end
        
        
        
        function setNdf1(obj, ~, ~)
            obj.setNdfWheelPosition(0.0);
        end
        function setNdf2(obj, ~, ~)
            obj.setNdfWheelPosition(0.5);
        end
        function setNdf3(obj, ~, ~)
            obj.setNdfWheelPosition(1.0);
        end
        function setNdf4(obj, ~, ~)
            obj.setNdfWheelPosition(2.0);
        end
        function setNdf5(obj, ~, ~)
            obj.setNdfWheelPosition(3.0);
        end
        function setNdf6(obj, ~, ~)
            obj.setNdfWheelPosition(4.0);
        end
        
        function setNdfWheelPosition(obj, pos)
            
            set([obj.ndfWheelButtons],'enable','off'); drawnow
            obj.filterWheel.setNDF(pos);
            set(obj.ndfWheelButtons,'enable','on'); drawnow
            obj.ndfPosition = pos;
            
        end 
        
        
        
        
        function onSelectedPatternRate(obj, ~, ~)
            rate = get(obj.patternRatePopupMenu, 'Value');
            obj.lightCrafter.setPatternRate(rate);
        end
        
        function populateCenterOffset(obj)
            offset = obj.lightCrafter.pix2um(obj.lightCrafter.getCenterOffset());
            set(obj.centerOffsetFields.x, 'String', num2str(offset(1)));
            set(obj.centerOffsetFields.y, 'String', num2str(offset(2)));
        end
        
        function onSetCenterOffset(obj, ~, ~)
            x = str2double(get(obj.centerOffsetFields.x, 'String'));
            y = str2double(get(obj.centerOffsetFields.y, 'String'));
            if isnan(x) || isnan(y)
                obj.view.showError('Could not parse x or y to a valid scalar value.');
                return;
            end
            obj.lightCrafter.setCenterOffset(obj.lightCrafter.um2pix([x, y]));
        end
        
        function populatePrerender(obj)
            set(obj.prerenderCheckbox, 'Value', obj.lightCrafter.getPrerender());
        end
        
        function onSelectedPrerender(obj, ~, ~)
            prerender = get(obj.prerenderCheckbox, 'Value');
            obj.lightCrafter.setPrerender(prerender);
        end
        
        function loadSettings(obj)
            if ~isempty(obj.settings.viewPosition)
                p1 = obj.view.position;
                p2 = obj.settings.viewPosition;
                obj.view.position = [p1(1) p1(2) p1(3) p1(4)];
            end
        end

        function saveSettings(obj)
            obj.settings.viewPosition = obj.view.position;
            obj.settings.save();
        end
        
    end
    
end