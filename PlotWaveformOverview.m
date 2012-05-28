    function [hFigure myAxes hOverviewAxes myPostZoomAction] = PlotWaveformOverview(szFileName, varargin)
% function to do something usefull (fill out)
% Usage [out_param] = PlotWaveformOverview(in_param)
% Input Parameter:
%	 in_param: 		 Explain the parameter, default values, and units
% Output Parameter:
%	 out_param: 	 Explain the parameter, default values, and units
%------------------------------------------------------------------------ 
% Example: Provide example here if applicable (one or two lines) 

% Author: Jan Willhaus (c) IHA @ Jade Hochschule applied 
% licence see EOF
% Version History:
% Ver. 0.01 initial create of concept script        21-Feb-2012     JW
% Ver. 0.1  first working implementation            29-Feb-2012     JW
% Ver. 0.2  fixed overview click&zoom functionality 09-Mar-2012     JW

%------------Your function implementation here--------------------------- 


bShowSlidersFlag = 1;
bShowOverviewFlag = 0;
vUpperAxesPos = [0.05 0.25 0.9 0.7];
vOverviewAxesPos = [0.05 0.05 0.9 0.15];
vZoomPosition = [];
hRect = [];
hOverviewAxes = [];
cParameters = varargin;
myColorsetFace = [0.4 0.4 1; 1 0.4 0.4; 0.75 0.75 0.5; 0.5 0.75 0.5; ...
    0.75 0.3 0.75; 0.3 0.75 0.75; 0.5 0.5 0.5; 0.2 0.2 0.2];
myColorsetEdge = [0.2 0.2 0.2];
numColorsFace = size(myColorsetFace,1);
numColorsEdge = size(myColorsetEdge,1);


    function cParameters = processInputParameters(cParameters)
        valuesToDelete = [];
        for kk=1:length(cParameters)
            arg = cParameters{kk};
            if ischar(arg) && strcmpi(arg,'ShowWaveOverview')
                bShowOverviewFlag = cParameters{kk +1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'ShowPositionSliders')
                bShowSlidersFlag = cParameters{kk +1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
        end
        cParameters(valuesToDelete) = [];
    end


hAxes = gca;
set(gca, 'units', 'normalized')
set(gca, 'Position', vUpperAxesPos);
myPostZoomAction = @myPostActionCallback;


[hFigure myAxes  , ~, vZoomPosition OrigStartEndVal OrigSampleValuesPos OrigSampleValuesNeg OrigTime_vek numChannels ReadAndComputeMaxData] = PlotWaveform(szFileName, 'ShowXAxisAbove', 1, 'PostZoomAction', myPostZoomAction, cParameters);

% vZoomPosition = [x_1 y_1 x_len y_len]

if bShowSlidersFlag
    % retrieve position of lowest axis to place the slider slightly below
    set(gca, 'units', 'normalized')
    vLastAxesPosition = get(hAxes, 'Position');
    
    % define the initial width of the zoom section
    iZoomWidth = vZoomPosition(3);
    
    hSliderHori = uicontrol('Style', 'slider',...
        'Min',OrigStartEndVal(1), ...
        'Max',OrigStartEndVal(2), ...
        'Value',(vZoomPosition(1)+iZoomWidth/2), ...
        'units', 'normalized', ...
        'Position', [vLastAxesPosition(1) vLastAxesPosition(2)-0.025 vLastAxesPosition(3) 0.02], ...
        'Callback', @CalcNewStartEndValHori);
    set(gcf,'toolbar','figure')
end

    function CalcNewStartEndValHori(h, ~)
        SliderValue = get(h, 'Value');
        StartEndVal(1) = SliderValue-iZoomWidth/2;
        StartEndVal(2) = SliderValue+iZoomWidth/2;
        YLims = get(hAxes, 'YLim');
        StartEndVal(3:4) = YLims(1:2);
        ReadAndComputeMaxData(1, StartEndVal);
        YLims = get(hAxes, 'YLim');
        StartEndVal(3:4) = YLims(1:2);
        vZoomPosition =  [StartEndVal(1) StartEndVal(3) (StartEndVal(2)-StartEndVal(1)) (StartEndVal(4)-StartEndVal(3))];
        set(hRect, 'Position', vZoomPosition);
    end

    hOverviewAxes = axes;
    set(gca, 'units', 'normalized')
    set(gca, 'Position', vOverviewAxesPos);
    for channel=1:numChannels
    hWaveView = fill([OrigTime_vek OrigTime_vek(end:-1:1)],[OrigSampleValuesPos(:,channel); flipud(OrigSampleValuesNeg(:,channel))],'b');
                    set(hWaveView,'FaceAlpha',0.5);
                    set(hWaveView,'EdgeAlpha',0.6);
                    set(hWaveView,'FaceColor',myColorsetFace(mod(channel-1, numColorsFace)+1,:));
                    set(hWaveView,'EdgeColor',myColorsetEdge(mod(channel-1, numColorsEdge)+1,:));
                    hold on;
    end
    axis(OrigStartEndVal);
    hold off;

    axes(hOverviewAxes);
    if isempty(hRect)
        hRect = rectangle;
    end
    set(hRect, 'Position', vZoomPosition);
    set(hRect, 'FaceColor', [0.9 0.9 1])
    set(hRect, 'EdgeColor', 'r')
    

    function myPostActionCallback(ActualRectPosition)  

        vZoomPosition =  [ActualRectPosition(1) ActualRectPosition(3) (ActualRectPosition(2)-ActualRectPosition(1)) (ActualRectPosition(4)-ActualRectPosition(3))];
        set(hRect, 'Position', vZoomPosition);
        axis(hOverviewAxes,OrigStartEndVal);
        
        iZoomWidth = vZoomPosition(3);
        set(hSliderHori,'Min',OrigStartEndVal(1)+iZoomWidth/2);
        set(hSliderHori,'Max',OrigStartEndVal(2)-iZoomWidth/2);
        set(hSliderHori,'Value',(vZoomPosition(1)+iZoomWidth/2));
    end

end


%--------------------Licence ---------------------------------------------
% Copyright (c) <2012> Jan Willhaus
% Institute for Hearing Technology and Audiology
% Jade University of Applied Sciences
% Permission is hereby granted, free of charge, to any person obtaining 
% a copy of this software and associated documentation files 
% (the "Software"), to deal in the Software without restriction, including 
% without limitation the rights to use, copy, modify, merge, publish, 
% distribute, sublicense, and/or sell copies of the Software, and to
% permit persons to whom the Software is furnished to do so, subject
% to the following conditions:
% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.