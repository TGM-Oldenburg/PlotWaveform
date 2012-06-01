function [myFigure myAxes myPrint vZoomPosition OrigStartEndVal OrigSampleValuesPos OrigSampleValuesNeg OrigTimeVec numChannels myReadAndComputeMaxData] = PlotWaveform(szFileNameOrData, varargin)
%PLOTWAVEFORM   waveform plot
%   PlotWaveform plots the waveform of a WAVE-file, or vector of WAVE-data
%   using a block by block mean calculation algorithm. WAVE-data first gets
%   split into a number of blocks defined by the size of the axis (and
%   therefore the available pixels) which enables the most precise
%   rendering of the data while using less CPU circles then in normal plot
%   calculation.
%
%   Usage [myFigure myAxes myPrint vZoomPosition OrigStartEndVal ... 
%   OrigSampleValuesPos OrigSampleValuesNeg OrigTimeVec numChannels] = ... 
%       PlotWaveform(szFileNameOrData, varargin)
%
%--------------------------------------------------------------------------
%
%   Input Parameter:
%   ----------------
%
%   szFileNameOrData:   string containing the filename of the WAVE-file or
%                       the variable containing the raw WAVE-data.
%                       (the latter requires the first following argument
%                       to be the desired sampling frequency)
%
%   varargin:           variable set of input arguments to modify the
%                       functions behavior. Consist of one declaration of
%                       setting and another declaration of value
%                       (eg. 'ChannelView',1). Possible behavior settings
%                       are shown and explained below.
%
%
%
%   Possible function behavior settings:
%   ------------------------------------
%
%   'ChannelView':      1: creating a new plot for each channel in file
%                       0: all channels overlayed in one plot (default)
%
%   'ColorsetFace':     user defined vector of Colors to be used for the
%                       faces of the plot. For details see documentation
%
%   'ColorsetEdge':     user defined vector of Colors to be used for the
%                       edges of the plot. For details see documentation
%
%   'Interval':         user defined vector of time (start and end) in
%                       seconds in which the function should calculate
%
%   'PaperPosition':    user defined size for printing/exporting the 
%                       figure. 1x4 vector: [x_min y_min x_len y_len]
%
%   'PrintResolution':  user defined resolution of graph for printing/
%                       exporting. Possibilities: 150, 300, 600 (dpi)
%
%   'SilentPrint':      0: figure will stay open after print/export
%                       1: figure will be closed after print/export
%
%   'SampleViewStyle':  0: show sample-exact view as stems (default)
%                       1: show sample-exact view as stairs
%                       2: show sample-exact view as classic plot
%
%   'ShowXAxisAbove':   0: shows the x-axis below the plot (default)
%                       1: shows the x-axis above the plot
%
%   'PostZoomAction':   input function handle from superior function or
%                       script to be executed right after a zoom action
%                       was performed. Can be used as a trigger for
%                       additional modifications on the plot, made by the
%                       superior function or script.
%
%   'Verbose':          integer to which to set the verbose logging. While
%                       future versions may offer more depth in verbose,
%                       right now only 0 (off) and 1 (on) are supported.
%
%
%
%   Output Parameter:
%   -----------------
%
%   myFigure:           handle to use in superior function or script to
%                       modify the parameters of the overall figure
%
%   myAxes:             handle to use in superior function or script to 
%                       modify the parameters of the plot
%
%   myPrint:            function handle to use in superior function to
%                       call the internal print-function
%
%   vZoomPosition:      returns the actual zoom position to a superior
%                       function or script
%
%   OrigStartEndVal:    returns the original start and end values of the
%                       plotted WAVE to a superior function or script
%
%   OrigSampleValuesPos:returns the original sample values of the positive
%                       halfshaft to a superior function or script
%                        
%
%   OrigSampleValuesNeg:returns the original sample values of the negative
%                       halfshaft to a superior function or script
%
%   OrigTimeVec:        returns the corresponding time vector for the
%                       sample values to a superior function or script
%
%   numChannels:        returns the number of channels in the WAVE
%

%--------------------------------------------------------------------------
% VERSION 0.70
%   Author: Jan Willhaus, Joerg Bitzer (c) IHA @ Jade Hochschule
%   applied licence see EOF
%
%   Version History:
%   Ver. 0.01   initial proof of concept script           10-Aug-2011   JB
%   Ver. 0.10   inital build of the function              27-Aug-2011   JW
%   Ver. 0.11   implementing mono & stereo view           31-Aug-2011   JW
%   Ver. 0.12   debugging second zoom layer               01-Sep-2011   JW
%   Ver. 0.21   implementing two-axis view for stereo     07-Sep-2011   JW
%   Ver. 0.22   adding possibility to read multichannel   08-Sep-2011   JW
%   Ver. 0.23   improvements on multi-axis view           15-Sep-2011   JW
%   Ver. 0.24   debugging zoom layer switch               22-Sep-2011   JW
%   Ver. 0.25   improvements on second zoom layer         28-Sep-2011   JW
%   Ver. 0.30   implementing customized zoom menu         12-Oct-2011   JW
%   Ver. 0.31   debugging customized zoom menu            23-Oct-2011   JW
%   Ver. 0.32   code cleaning, killing matlab warnings    01-Dec-2011   JW
%   Ver. 0.40   implementing print-functionhandle         30-Jan-2012   JW
%   Ver. 0.50   implementing wave-overview                15-Feb-2012   JW
%   Ver. 0.51   fixed faulty zoom extract                 16-Feb-2012   JW
%   Ver. 0.60   supports PlotWaveformOverview function    27-Feb-2012   JW
%   Ver. 0.61   code cleaning, updating the help info     09-Mar-2012   JW
%   Ver. 0.70   code cleaning again. ready for public     01-Jun-2012   JW


%% settings default values
% default Colorset
myColorsetFace = [0.4 0.4 1; 1 0.4 0.4; 0.75 0.75 0.5; 0.5 0.75 0.5; ...
    0.75 0.3 0.75; 0.3 0.75 0.75; 0.5 0.5 0.5; 0.2 0.2 0.2];
myColorsetEdge = [0.2 0.2 0.2];

% setting threshold below which the WAVE is plotted sample-exact
iPlotBlockwiseThreshold = 16384;

% setting threshold below which the samples are plotted with chosen markers
iPlotMarkersThreshold = 128;

bAlphaBlendFlag = 0;
% bAlphaBlendOn == 0 --> disable alphablending of stereo data
% bAlphaBlendOn == 1 --> enable alphablending of stereo data

bPlotBlockwiseFlag = 1;
% bPlotBlockwiseFlag == 1 --> waveform blockwise (default)
% bPlotBlockwiseFlag == 0 --> waveform

bChannelViewFlag = 1;
% bChannelViewFlag == 0 --> display stereo data in one plot
% bChannelViewFlag == 1 --> display stereo data in two seperate plots

%% creating global variables
bPrintFlag = 0;
bSampleViewStyleFlag = 0;
bPlotWithMarkersFlag = 0;
bShowXAxisAboveFlag = 0;
bAlphaBlendOn = [];
bSilentPrintFlag = 0;
bReplotOriginalValuesFlag = 0;
bAutoAdjustYAxisFlag = 0;
fs = [];
FileSize = [];
UnterBlocks = 0;
StartEndVal = [];
OrigStartEndVal= [];
plotWidth = [];
iPrintResolution = [];
vPaperPosition = [];
OrigSampleValuesNeg = [];
OrigSampleValuesPos = [];
OrigTimeVec = [];
bOrigPlotBlockwiseFlag = [];
bOrigAlphaBlendOn = [];
bOrigPlotWithMarkersFlag = [];
vZoomPosition = [];
FileSize = [];
myPostZoomAction = @NOP;
iVerbose = 0;

%% evaluation of input data
if nargin == 0, help(mfilename); return; end;

if ischar(szFileNameOrData)
    [FileSize,fs] = wavread(szFileNameOrData,'size');
    bIsWavFileFlag = 1;
elseif isnumeric(szFileNameOrData)
    FileSize = size(szFileNameOrData);
    wavData = szFileNameOrData;
    if isnumeric(varargin{1})
        fs = varargin{1};
    else
        error('Raw wav-data requires second argument to be sampling rate')
    end
    varargin(1) = [];
    bIsWavFileFlag = 0;
else
    error('Unexpected type of input')
end

numChannels = FileSize(2);

if bChannelViewFlag == 0
    vDefaultPaperPosition = [0 0 15.9 3.81*numChannels];
else
    vDefaultPaperPosition = [0 0 15.9 3.81];
end
vDefaultPrintResolution = 150;
set(0,'DefaultFigurePaperPositionMode','manual')

varargin = processInputParameters(varargin);

%% variable arguments read-in
    function cParameters = processInputParameters(cParameters)
        valuesToDelete = [];
        for kk=1:length(cParameters)
            arg = cParameters{kk};
            if ischar(arg) && strcmpi(arg,'ChannelView')
                bChannelViewFlag = cParameters{kk + 1};
                bAlphaBlendFlag = ~bChannelViewFlag;
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'ColorsetFace')
                myColorsetFace = cParameters{kk + 1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'ColorsetEdge')
                myColorsetEdge = cParameters{kk + 1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'Interval')
                StartEndVal = cParameters{kk + 1};
                OrigStartEndVal = StartEndVal;
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'PaperPosition')
                vPaperPosition = cParameters{kk + 1};
                if  length(vPaperPosition) ~= 4
                    error('PaperPosition needs to be [x y width height]')
                end
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'PrintResolution')
                iPrintResolution = cParameters{kk + 1};
                if  iPrintResolution ~=150||300||600
                    warning('PrintResolution should be 150, 300 or 600')
                end
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'SilentPrint')
                bSilentPrintFlag = cParameters{kk + 1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'SampleViewStyle')
                bSampleViewStyleFlag = cParameters{kk +1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'ShowXAxisAbove')
                bShowXAxisAboveFlag = cParameters{kk +1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
            if ischar(arg) && strcmpi(arg,'PostZoomAction')
                myPostZoomAction = cParameters{kk +1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
             if ischar(arg) && strcmpi(arg,'Verbose')
                iVerbose = cParameters{kk +1};
                valuesToDelete = [valuesToDelete kk:kk+1];
            end
        end
        
        cParameters(valuesToDelete) = [];
    end

if isempty(StartEndVal)
    StartEndVal = [1/fs FileSize(1)/fs];
    OrigStartEndVal = StartEndVal;
end

if isempty(iPrintResolution)
    iPrintResolution = vDefaultPrintResolution;
end

if isempty(vPaperPosition)
    vPaperPosition = vDefaultPaperPosition;
end



numColorsFace = size(myColorsetFace,1);
numColorsEdge = size(myColorsetEdge,1);

SampleValuesPos = [];
SampleValuesNeg = [];
numSamples = 0;
myZoomMenu = uicontextmenu;
ChannelViewSet();

%% building the figure and its axes
    function ChannelViewSet()
        myAxes(1) = gca;
        myFigure = gcf;
        
        set(gca, 'units', 'normalized')
        pos = get(gca, 'position');
        
        if bChannelViewFlag == 1
            for channel=1:numChannels
                set(gca, 'position', ...
                    [pos(1) ...
                    pos(2)+pos(4)*(channel-1)/(numChannels) ...
                    pos(3) ...
                    (1/(numChannels)*pos(4))])
                myAxes(channel) = gca;
                if channel ~= numChannels
                    myAxes(channel+1) = axes;
                end
            end
        end
        myAxes = fliplr(myAxes);
    end

%% doing the math on samples
ReadAndComputeMaxData;
hZoom = zoom;
set(hZoom,'ActionPostCallback',@PostCallbackWithLims);

if isempty(get(gcf, 'ResizeFcn'))
    set(gcf, 'ResizeFcn', @ResizeFcn);
end

    function ReadAndComputeMaxData(iManualPlotWidth, NewStartEndVal)
        if iVerbose
            tic
        end
        if ~bReplotOriginalValuesFlag
            set(gca, 'units', 'Pixel')
            pos = get(gca, 'position');
            if nargin == 1
                plotWidth = iManualPlotWidth;
            elseif nargin == 2
                if iManualPlotWidth == 0
                    plotWidth = floor(pos(3));
                end
                StartEndVal = NewStartEndVal;
            else
                plotWidth = floor(pos(3));
            end
            set(gca, 'units', 'normalized')
            
            if bAutoAdjustYAxisFlag && length(StartEndVal) > 2
                StartEndVal(3 : 4) = [];
            end

            
            %         fprintf('%d pixel width of plot\n', plotWidth)
            
            iFirstSample = ceil(StartEndVal(1)*fs);
            if (iFirstSample <= 0)
                iFirstSample = 1;
            end
            
            iLastSample = max(floor(StartEndVal(2)*fs), iFirstSample + 1);
            if (iLastSample >= FileSize(1))
                iLastSample = FileSize(1);
            end
            
            %Getting Num of Samples to be processed
            numSamples = iLastSample-iFirstSample;
            if iVerbose
                fprintf('%d samples on input\n', numSamples);
            end
            
            SampleValuesPos = 0;
            bPlotBlockwiseFlag = 1;
            bPlotWithMarkersFlag = 0;
           
            numSamplesToDisplay = numSamples;
            if iVerbose
                fprintf('%d samples on output\n', numSamplesToDisplay)
            end
            
            indBlocks = [iFirstSample iFirstSample+numSamplesToDisplay];
            
            SamplesPerPixel = ceil(numSamples/plotWidth);
            
            MaxCompLen = SamplesPerPixel;
            
            UnterBlocks = floor(numSamplesToDisplay/MaxCompLen);
            if iVerbose
                fprintf('%d subblocks\n', UnterBlocks)
            end
            
            SampleValuesPos = zeros(UnterBlocks,numChannels);
            SampleValuesNeg = zeros(UnterBlocks,numChannels);
            
            if bIsWavFileFlag == 1
                DataBlocks = wavread(szFileNameOrData,indBlocks);
            else
                DataBlocks = wavData(indBlocks(1):indBlocks(2),:);
            end
            
            if  numSamplesToDisplay > iPlotBlockwiseThreshold
                for mm = 1:UnterBlocks
                    SampleValuesPos(mm,:) = ...
                        (max( ...
                        (DataBlocks((mm-1)*MaxCompLen+1:mm*MaxCompLen,:))));
                    SampleValuesNeg(mm,:) = ...
                        (min( ...
                        (DataBlocks((mm-1)*MaxCompLen+1:mm*MaxCompLen,:))));
                end
            else
                SampleValuesPos = DataBlocks;
            end
            
            if bAlphaBlendFlag == 1;
                bAlphaBlendOn = 1;
            end
            if length(StartEndVal) == 2
                StartEndVal(3) = ... 
                    -max(max(abs([SampleValuesPos; ...
                    SampleValuesNeg]))) * 1.1 - eps;
                StartEndVal(4) = ...
                    +max(max(abs([SampleValuesPos; ...
                    SampleValuesNeg]))) * 1.1 + eps;
            end
            if isempty(OrigStartEndVal)
                OrigStartEndVal = StartEndVal;
            end
            if length(OrigStartEndVal) == 2
                OrigStartEndVal(3) = StartEndVal(3);
                OrigStartEndVal(4) = StartEndVal(4);
            end

            if  numSamplesToDisplay <= iPlotBlockwiseThreshold
                bPlotBlockwiseFlag = 0;
                if isempty(bOrigPlotBlockwiseFlag)
                    bOrigPlotBlockwiseFlag = bPlotBlockwiseFlag;
                end
                bAlphaBlendOn = 0;
                if isempty(bOrigAlphaBlendOn)
                    bOrigAlphaBlendOn = bAlphaBlendOn;
                end
                
                if numSamplesToDisplay <= iPlotMarkersThreshold
                    bPlotWithMarkersFlag = 1;
                    if isempty(bOrigPlotWithMarkersFlag)
                        bOrigPlotWithMarkersFlag = bPlotWithMarkersFlag;
                    end
                end
            else
                bPlotBlockwiseFlag = 1;
                if isempty(bOrigPlotBlockwiseFlag)
                    bOrigPlotBlockwiseFlag = bPlotBlockwiseFlag;
                end
            end
        end
        plotData;
        
        if iVerbose
            T = toc;
            fprintf('%f seconds in data\n%f seconds to process.\n', ...
                numSamples/fs, T)
        end
    end

myReadAndComputeMaxData = @ReadAndComputeMaxData;

%% plotting the data
    function plotData()
        if bReplotOriginalValuesFlag
            SampleValuesPos = OrigSampleValuesPos;
            SampleValuesNeg = OrigSampleValuesNeg;
            timeVec = OrigTimeVec;
            
            bPlotBlockwiseFlag = bOrigPlotBlockwiseFlag;
            bAlphaBlendOn = bOrigAlphaBlendOn;
            bPlotWithMarkersFlag = bOrigPlotWithMarkersFlag;
            fprintf('Resetting to original values\n')
        end
        if isempty(vZoomPosition)
            vZoomPosition =  [ ...
                StartEndVal(1) ...
                StartEndVal(3) ...
                StartEndVal(2)-StartEndVal(1) ...
                StartEndVal(4)-StartEndVal(3)];
        end
        if size(SampleValuesPos,1) == 1
            SampleValuesPos = [SampleValuesPos; SampleValuesPos];
            SampleValuesNeg = [SampleValuesNeg; SampleValuesNeg];
        end
        if isempty(OrigSampleValuesPos)
        OrigSampleValuesPos = SampleValuesPos;
        end
        if isempty(OrigSampleValuesNeg)
        OrigSampleValuesNeg = SampleValuesNeg;
        end 
        timeVec = linspace(StartEndVal(1), ...
            StartEndVal(2), ...
            size(SampleValuesPos,1));
        if isempty(OrigTimeVec)
            OrigTimeVec = timeVec;
        end

        for channel=1:numChannels
            if bChannelViewFlag == 1
                axes(myAxes(channel));
            end
            if bPlotBlockwiseFlag == 0
                if bPlotWithMarkersFlag == 1
                    switch bSampleViewStyleFlag
                        case 0
                            if UnterBlocks*4<plotWidth
                                stem(timeVec, ...
                                    SampleValuesPos(:,channel), ...
                                    'Color', myColorsetFace(mod ...
                                    (channel-1, numColorsFace)+1,:));
                            else
                                plot(timeVec, ...
                                    SampleValuesPos(:,channel), ...
                                    'Color',myColorsetFace(mod( ...
                                    channel-1, numColorsFace)+1,:));
                            end
                        case 1
                            stairs(timeVec,SampleValuesPos(:,channel), ...
                                'Color',myColorsetFace(mod ...
                                (channel-1, numColorsFace)+1,:));
                        case 2
                            plot(timeVec,SampleValuesPos(:,channel), ...
                                'Color',myColorsetFace(mod ...
                                (channel-1, numColorsFace)+1,:));
                    end
                else
                    plot(timeVec,SampleValuesPos(:,channel), ...
                        'Color',myColorsetFace(mod ...
                        (channel-1, numColorsFace)+1,:));
                end
            elseif bPlotBlockwiseFlag == 1
                hWaveView = fill([timeVec timeVec(end:-1:1)],...
                    [SampleValuesPos(:,channel); ...
                    flipud(SampleValuesNeg(:,channel))],'b');
                if bAlphaBlendOn == 1
                    set(hWaveView,'FaceAlpha',0.5, 'EdgeAlpha',0.6, ...
                        'FaceColor', ...
                        myColorsetFace(mod(channel-1, numColorsFace)+1,:), ...
                        'EdgeColor', ...
                        myColorsetEdge(mod(channel-1, numColorsEdge)+1,:));
                else
                    set(hWaveView,'EdgeAlpha',0.6, ... 
                        'FaceColor', ...
                        myColorsetFace(mod(channel-1, numColorsFace)+1,:), ...
                        'EdgeColor', ...
                        myColorsetEdge(mod(channel-1, numColorsEdge)+1,:));
                end
            end
            axis(StartEndVal);
            if bChannelViewFlag == 0
                hold on;
            end
            if bShowXAxisAboveFlag
                if channel == 1
                    set(gca, 'XAxisLocation', 'top')
                end
                 if channel > 1 && bChannelViewFlag == 1
                    set(gca, 'xticklabel', [])
                 end
            else
                if channel ~= numChannels && bChannelViewFlag == 1
                    set(gca, 'xticklabel', [])
                end
            end
        end
        hold off;   
    end        

%% custom zoom operations
    function SetOriginalZoom(~, ~)
        StartEndVal = OrigStartEndVal;
        bReplotOriginalValuesFlag = 1;
        ReadAndComputeMaxData();
        bReplotOriginalValuesFlag = 0;
        if ~isempty(myPostZoomAction)
            myPostZoomAction(StartEndVal);
        end
        
    end

    function UnconstrainedZoom(~,~)
        set(itemMyZoomUnconst, 'Checked', 'on')
        set(itemMyZoomHoriOnly, 'Checked', 'off')
        set(itemMyZoomVertOnly, 'Checked', 'off')
        set(itemMyZoomHoriOnlyAutoVert, 'Checked', 'off')
        set(zoom,'Motion','both','Enable','on')
        bAutoAdjustYAxisFlag = 0;
    end

    function HorizontalZoomOnly(~,~)
        set(itemMyZoomUnconst, 'Checked', 'off')
        set(itemMyZoomHoriOnly, 'Checked', 'on')
        set(itemMyZoomHoriOnlyAutoVert, 'Checked', 'off')
        set(itemMyZoomVertOnly, 'Checked', 'off')
        set(zoom,'Motion','horizontal','Enable','on')
        bAutoAdjustYAxisFlag = 0;
    end

    function HorizontalZoomOnlyAutoVert(~,~)
        set(itemMyZoomUnconst, 'Checked', 'off')
        set(itemMyZoomHoriOnly, 'Checked', 'on')
        set(itemMyZoomHoriOnlyAutoVert, 'Checked', 'on')
        set(itemMyZoomVertOnly, 'Checked', 'off')
        set(zoom,'Motion','horizontal','Enable','on')
        bAutoAdjustYAxisFlag = 1;
    end

    function VerticalZoomOnly(~,~)
        set(itemMyZoomUnconst, 'Checked', 'off')
        set(itemMyZoomHoriOnly, 'Checked', 'off')
        set(itemMyZoomHoriOnlyAutoVert, 'Checked', 'off')
        set(itemMyZoomVertOnly, 'Checked', 'on')
        set(zoom,'Motion','vertical','Enable','on')
        bAutoAdjustYAxisFlag = 0;
    end

%% printing operations
  function SetPrintResolution(~,~)
      [OrigSampleValuesPos OrigSampleValuesNeg] = PrepareFigForPrint;
      [szSaveFileName, ...
          szSaveFilePath, ...
          szSaveFilterIndex] = uiputfile({ '*.eps', 'EPS file (*.eps)'; ...
          '*.jpg', 'JPEG image (*.jpg)'; ...
          '*.pdf', 'Portable Document Format (*.pdf)'}, ...
          'Save As', szFileNameOrData);
      if isequal(szSaveFileName,0) == 0 || isequal(szSaveFilePath,0) == 0
          szSaveFileNamePath = sprintf('%s%s', szSaveFilePath, szSaveFileName);
          szSaveFormat = {'-depsc', '-djpeg', '-dpdf'};
          set(gcf, 'renderer', 'painters');
          set(gcf, 'PaperPositionMode', 'manual');
          print(gcf,szSaveFormat{szSaveFilterIndex}, ...
              sprintf('-r%i', iPrintResolution),szSaveFileNamePath)
      end
      bPrintFlag = 0;
      SampleValuesPos = OrigSampleValuesPos;
      SampleValuesNeg = OrigSampleValuesNeg;
      plotData;
  end

myPrint=@internalPrint;

    function internalPrint(varargin)
        vararginPrint = processInputParameters(varargin);
        
        [OrigSampleValuesPos OrigSampleValuesNeg] = PrepareFigForPrint;
        print(vararginPrint{:})
        bPrintFlag = 0;
        if bSilentPrintFlag == 1
            close gcf
        else
            SampleValuesPos = OrigSampleValuesPos;
            SampleValuesNeg = OrigSampleValuesNeg;
            plotData;
        end
    end

    function [OrigSampleValuesPos OrigSampleValuesNeg] = PrepareFigForPrint()
        bPrintFlag = 1;
        iManualPlotWidth = iPrintResolution*(vPaperPosition(3)/2.54);
        OrigSampleValuesPos = SampleValuesPos;
        OrigSampleValuesNeg = SampleValuesNeg;
        ReadAndComputeMaxData(floor(iManualPlotWidth));
        set(gcf, 'PaperPositionMode', 'auto')
        set(gcf, 'Units', 'centimeters')
        set(gcf, 'Position',vPaperPosition)
    end
        

%% additional operations
    function SetSampleViewStyle(~,~,bSampleViewStyle)
        set(itemMyZoomShowStems, 'Checked', 'off')
        set(itemMyZoomShowStairs, 'Checked', 'off')
        set(itemMyZoomShowPlot, 'Checked', 'off')
        bSampleViewStyleFlag = bSampleViewStyle;
        if bSampleViewStyle == 0
            set(itemMyZoomShowStems, 'Checked', 'on')
%             fprintf('Sample View style was set to Stems\n')
        elseif bSampleViewStyle == 1
            set(itemMyZoomShowStairs, 'Checked', 'on')
%             fprintf('Sample View style was set to Stairs\n')
        elseif bSampleViewStyle == 2
            set(itemMyZoomShowPlot, 'Checked', 'on')
%             fprintf('Sample View style was set to Plotted Line\n')
        end
        plotData();
    end

    function SetChannelView(~,~,desiredFlag)
        switch desiredFlag
            case 1
                set(itemMyZoomEnableChannelView, 'Checked', 'on')
                set(itemMyZoomDisableChannelView, 'Checked', 'off')
            case 0
                set(itemMyZoomEnableChannelView, 'Checked', 'off')
                set(itemMyZoomDisableChannelView, 'Checked', 'on')
        end
        bChannelViewFlag = desiredFlag;
        bAlphaBlendFlag = ~desiredFlag;
        close gcf
        ChannelViewSet();
        ReadAndComputeMaxData();
    end

%% custom zoom menu build-up
hMenuSave = findall(gcf,'tag','Standard.SaveFigure');
set(hMenuSave, 'ClickedCallback', @SetPrintResolution);
zoom('off')
set(zoom,'UIContextMenu',myZoomMenu);

% Option to fully reset the zoom on plot to its original view
itemMyZoomReset = uimenu(myZoomMenu, ...
    'Label', 'Reset to Original View', ...
    'Callback', @SetOriginalZoom);

% Submenu to enable or disable ChannelView (Not implemented yet)
% itemMyZoomChannelView = uimenu(myZoomMenu, ...
%     'Label', 'ChannelView');
% itemMyZoomEnableChannelView = uimenu(itemMyZoomChannelView, ...
%     'Label', 'Enable ', ... 
%     'Callback', {@SetChannelView, 1});
% itemMyZoomDisableChannelView = uimenu(itemMyZoomChannelView, ...
%     'Label', 'Disable', ...
%     'Callback', {@SetChannelView, 0});

% Submenu to choose direction of zoom-process (horizontal/vertical/both)
itemMyZoomDirections = uimenu(myZoomMenu, ...
    'Label', 'Zoom Options');
itemMyZoomUnconst = uimenu(itemMyZoomDirections, ...
    'Label', 'Unconstrained Zoom', ...
    'Callback', @UnconstrainedZoom, ...
    'Checked', 'on');
itemMyZoomHoriOnly = uimenu(itemMyZoomDirections, ...
    'Label', 'Horizontal Zoom Only', ...
    'Callback', @HorizontalZoomOnly);
itemMyZoomHoriOnlyAutoVert = uimenu(itemMyZoomDirections, ...
    'Label', '- Auto-Adjust Vertically', ...
    'Callback', @HorizontalZoomOnlyAutoVert);
itemMyZoomVertOnly = uimenu(itemMyZoomDirections, ...
    'Label', 'Vertical Zoom Only', ...
    'Callback', @VerticalZoomOnly);

% Submenu to choose desired sample-exact view
itemMyZoomSampleView = uimenu(myZoomMenu, ...
    'Label', 'Sample-exact View');
itemMyZoomShowStems = uimenu(itemMyZoomSampleView, ...
    'Label', 'Show as stems', ...
    'Callback', {@SetSampleViewStyle, 0}, ...
    'Checked', 'on');
itemMyZoomShowStairs = uimenu(itemMyZoomSampleView, ...
    'Label', 'Show as stairs', ...
    'Callback',  {@SetSampleViewStyle, 1});
itemMyZoomShowPlot = uimenu(itemMyZoomSampleView, ...
    'Label', 'Show as plot', ...
    'Callback',  {@SetSampleViewStyle, 2});
% SetSampleViewStyle([],[],bSampleViewStyleFlag);


zoom('on')


        function PostCallbackWithLims(~, evd)
            StartEndVal(1 : 2) = get(evd.Axes,'XLim');
            StartEndVal(3 : 4) = get(evd.Axes,'YLim');
            
            ReadAndComputeMaxData(0, StartEndVal);
            if ~isempty(myPostZoomAction)
                myPostZoomAction(StartEndVal);
            end
            
    end

    function ResizeFcn(~,~)
        if bPrintFlag == 0
            ReadAndComputeMaxData();
        end

    end

    function NOP(varargin)
        % No OPeration; simply does nothing. 
    end

end

%%------------------------ Licence ---------------------------------------------
% Copyright (c) <2011> Jan Willhaus, Joerg Bitzer
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