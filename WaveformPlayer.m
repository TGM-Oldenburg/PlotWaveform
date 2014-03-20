function [hFigure, hWaveAxes, hOverviewAxes, stFuncHandles] = WaveformPlayer(szFileName, varargin)
%PLOTWAVEFORMPLAYER    waveform plot with player functionality
%   PlotWaveform plots the waveform of a WAVE-file, or vector of WAVE-data
%   using a block by block mean calculation algorithm. WAVE-data first gets
%   split into a number of blocks defined by the size of the axis (and
%   therefore the available pixels) which enables the most precise
%   rendering of the data while using less CPU circles then in normal plot
%   calculation.
%
%   This function is an extention to the existing PLOTWAVEFORM and offers
%   better handling, optimized for playback. It features playback controls
%   and additional options like an overlay-spectrogram (future release).
%
%
%--------------------------------------------------------------------------
%
%   Usage:
%   ------
%                       [hFigure, hWaveAxes, hOverviewAxes] = ...
%                           WaveformPlayer(szFileName)
%
%
%--------------------------------------------------------------------------
%
%   Input Parameter:
%   ----------------
%
%   szFileName:         string containing the filename of the WAVE-file
%
%
%--------------------------------------------------------------------------
%
%   Possible function behavior settings:
%   ------------------------------------
%
%   'Parent':           user defined UI handle of a figure() or uipanel() in
%                       which the WFP is supposed to be placed if the function
%                       is used in a multi-figure, or multi-panel environment
%
%   'ReturnStartEnd':   user defined function handle of a function present in
%                       the mother function that will receive the start and end
%                       values (in time [seconds]) after a zoom action was
%                       performed. The function handle has to be defined first
%                       For Example:
%                       
%                           funcPrintValues = @(StartEnd) ...
%                                               disp(...
%                                               sprintf(...
%                                               'Start: %4.3f, End: %4.3f', ...
%                                               StartEnd(1), StartEnd(2)));
%
%                           WaveformPlayer('ExampleWave', ...
%                                           'ReturnStartEnd', funcPrintValues);
%
%   'PostSlideAction':  user defined function handle of a function present in
%                       the mother function that will receive the start and end
%                       values (in time [seconds]) after a sliding action was
%                       performed. The function handle has to be defined first
%                       Example see 'ReturnStartEnd' above.
%
%   'PostViewChangeAction': user defined functino handle of a function present
%                           in the mother function that will receive the
%                           current view mode as integer:
%
%                               1: waveform display
%                               2: spectrogram display
%  
%                           The function handle has to be defined first.
%                           Example see 'ReturnStartEnd' above.
%
%
%       NOTE: WaveformPlayer supports all the behavioral settings that
%       PlotWaveform itself does, with except for the following. Those are used
%       internally by the waveform player and are therefore not available for 
%       the end-user:
%
%       ShowXAxisAbove, PostZoomAction, ChannelView, ZoomMode
%
%--------------------------------------------------------------------------
%
%   Output Parameter:
%   -----------------
%
%   myFigure:           handle to use in superior function or script to
%                       modify the parameters of the overall figure
%
%   myAxes:             handle to use in superior function or script to
%                       modify the parameters of the main axes plot
%
%   hOverviewAxes:      handle to use in superior function or script to
%                       modify the parameters of the overview plot
%
%   stFuncHandles:      struct containing internal function handles of the
%                       WFP to use in superior function or script to modify
%                       parameters.
%
%      * stFuncHandles.NewZoomPosition(vZoomPosition):     
%                       function handle to deliver a new zoom position to WFP.
%                       vZoomPosition has to be a 2x1 vector for the X position
%                       {and a 4x1 for X and Y position} to be forwarded:
%
%                           vZoomPosition = [X1, X2, {Y1, Y2}];
%

%--------------------------------------------------------------------------
% VERSION 0.36.2
%   Author: Jan Willhaus (c) IHA @ Jade Hochschule
%   applied licence see EOF
%
%   Version History:
%   Ver. 0.01   initial creation of function                16-Jul-2012     JW
%   Ver. 0.10   first working build                         16-Jul-2012     JW
%   Ver. 0.20   basic functionality of playback             17-Jul-2012     JW
%   Ver. 0.21   position mark in all plots                  19-Jul-2012     JW
%   Ver. 0.22   improved behavior at wave's end             20-Jul-2012     JW
%   Ver. 0.23   added support for channel routing matrix    27-Jul-2012     JW
%   Ver. 0.24   bugfixes: detection of default audio        13-Sep-2012     JW
%               output now working properly, routing 
%               matrix now completely deactivateable
%               live.
%   Ver. 0.25   bugfixes: first axes now behaving as        15-Sep-2012     JW
%               as expected (on change of fig size).
%   Ver. 0.26   added: menubar-item for window size         17-Sep-2012     JW
%               and NFFT. fixed: proper asynchronous
%               updating of the GUI.
%   Ver. 0.27   added: menubar item for colormap            18-Sep-2012     JW
%               (choice and change of depth)
%   Ver. 0.28   bugfixes: activation of spectrogram         20-Sep-2012     JW
%               now works without resetting 
%   Ver. 0.29   enhancement: player now supports the        09-Mar-2013     JW 
%               'Parent' property and can therefore be
%               placed inside of figures of uipanels
%   Ver. 0.30   enhancement: player now supports returning  02-Apr-2013     JW
%               the start/end interval of the current zoom
%               position via the 'ReturnStartEnd' property
%   Ver. 0.31   enhancement: player now supports receiving  19-Apr-2013     JW
%               the start/end interval for the zoom 
%               position via the 
%               stFuncHandles.PostZoomAction func. handle
%   Ver. 0.31.1 Multifig fix on input verification          19-Apr-2013     JW
%   Ver. 0.31.2 Removal of false error in input verifi.     30-Apr-2013     JW
%   Ver. 0.32   Newly created Ini-file will now be placed   30-Apr-2013     JW
%               in the directory of WaveformPlayer.m
%   Ver. 0.33   New function handle input for post slide    30-Apr-2013     JW
%   Ver. 0.34   Change: Checkboxes for spectrogram and      03-May-2013     JW
%               waveform have been exchanged for a toggle
%               switch. This works better than an overlayed
%               display of both.
%               Fix: Colormap depth works again and slider
%               input is now even better verified in the
%               zoom post action callback.
%   Ver. 0.34.1 Fix: Moved the function handle (post zoom)  09-May-2013     JW
%               a little further down, so the exection 
%               starts *after* re-writing the plots. 
%               (at suggestion of Julian Kahnert) 
%   Ver. 0.35   Realigned the spectrogram y axis to show    09-May-2013     JW
%               in kHz and fixed a small bug resulting in 
%               always showing a spectrogram when a slide
%               action is performed. Other small fixes.
%   Ver. 0.35.1 Fix: Audio playback won't lead to crash     09-May-2013     JW
%               when changing view type
%   Ver. 0.36   Change: "PostViewChangeAction" func handle  24-May-2013     JW
%               is executed after the view is changed from
%               waveform to spectrogram or vice versa
%   Ver. 0.36.1 Fix: Slider bug in relation to NewZomPos.   27-May-2013     JW
%               fun handle leading to inability to slide
%   Ver. 0.36.2 Fix: Again the slider bug. Hotfix 0.36.1    27-May-2013     JW
%               Had a tiny fault in it.

%DEBUG
% szFileName = 'SampleLong.wav';
% close gcf

%% evaluation of input data
if nargin == 0, help(mfilename); return; end;

%% Macintosh notification
if ismac
    disp('Macintosh is currently not supported.');
    disp('Use PlotWaveformOverview instead.');
    bPlaybackSupportFlag = 0;
%     return
else
    bPlaybackSupportFlag = 1;
end

[~,szReleaseDate]   = version;
nReleaseDate        = datenum(szReleaseDate);
nAudioreadAvailable = 735123;
bUseAudioread = nReleaseDate >= nAudioreadAvailable;

%% Set global visuals
vUpperAxesPos       = [ 0.05    0.45    0.90    0.50];
vOverviewAxesPos    = [ 0.05    0.23    0.90    0.15];

myColorsetFace      = [ 061/255 129/255 136/255; ...    % blue
                        223/255 104/255 098/255; ...    % red
                        051/255 230/255 051/255; ...    %
                        230/255 230/255 051/255; ...
                        230/255 051/255 230/255; ...
                        051/255 230/255 230/255];
myColorsetEdge      = [ 051/255 051/255 051/255];       % dark grey
myColormaps         = { 'autumn', ...
                        'bone', ...
                        'colorcube', ...
                        'cool', ...
                        'copper', ...
                        'flag', ...
                        'gray', ...
                        'hot', ...
                        'hsv', ...
                        'jet', ...
                        'lines', ...
                        'pink', ...
                        'prism', ...
                        'spring', ...
                        'summer', ...
                        'white', ...
                        'winter' };
guiColormapDef      =   'jet';
guiBackgroundColor  = [ 229/255 229/255 229/255];       % light grey
guiSize             = [ 800 600];
auxSize             = [ 400 300];

%% Set global settings
szSaveFileTitle = 'WaveformPlayer.ini';
iBlockLen       = 1024;
iWinMin         = 256;
iWinDef         = 2048;
iWinMax         = 8192;
iNFFTMin        = 256;
iNFFTDef        = 512;
iNFFTMax        = 8192;
iUpdateInterval = 1;
iIconSize       = 24;
globsetOutputID = 0;

vPlayStartEnd = [];

%% Set global variables
PlayIdx         = 1;
vZoomPosition   = [];
vButtonSize     = [];
vOutputDevices  = [];
vSelectedDevice = [];
vAxesSize       = [];
iZoomWidth      = [];
vStartEndVal    = [];
caOrigSpectrData= {};
maOrigSpectrData= [];
routingMatrix   = [];
stDevices       = [];
defaultIDs      = [];
numOutputs      = [];
iRedrawCounter  = 0;
vColormapVal    = [];
OrigColormapVal = [];
caParentDef     = [];
CurrentPos      = [];

%% Create prelim. flags
bPlaySelectionFlag  = 1;
bPlayAsLoopFlag     = 0;
bIsPlayingFlag      = 0;
bIsEndOfWaveFlag    = 0;
bIsPausedFlag       = 0;
bCalcSpectogram     = 1;
bRoutingEnabled     = 1;
bWaveDisplayType    = 1;

%% Create empty handles
handles         = [];
icons           = [];
hRect           = [];
hSliderHori     = [];
hOverviewAxes   = [];
hOverviewPos    = [];
hWavePos        = [];
hDataToggle     = [];
hSpectrograms   = [];
hParentFig      = [];
hLoudnessPanel  = [];
hToolsPanel     = [];

myPostZoomReturnStartEnd    = [];
myPostSlideAction           = [];
myPostViewChangeAction      = [];

caLeftoverParams = processInputParameters(varargin);

%% Evaluation of behavioral settings
    function cParameters = processInputParameters(cParameters)
        valuesToDelete = [];
        for kk=1:length(cParameters)
            arg = cParameters{kk};
            if ischar(arg) && strcmpi(arg,'Parent')
                hParentFig = cParameters{kk + 1};
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
            if ischar(arg) && strcmpi(arg,'ShowXAxisAbove')
                warnForOverride(arg)
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
            if ischar(arg) && strcmpi(arg,'PostZoomAction')
                warnForOverride(arg)
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
            if ischar(arg) && strcmpi(arg,'PostSlideAction')
                myPostSlideAction = cParameters{kk + 1};
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
            if ischar(arg) && strcmpi(arg,'ReturnStartEnd')
                myPostZoomReturnStartEnd = cParameters{kk + 1};
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
%             if ischar(arg) && strcmpi(arg,'ColorsetFace')
%                 warnForOverride(arg)
%                 valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
%             end
%             if ischar(arg) && strcmpi(arg,'ColorsetEdge')
%                 warnForOverride(arg)
%                 valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
%             end
            if ischar(arg) && strcmpi(arg,'ChannelView')
                warnForOverride(arg)
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
            if ischar(arg) && strcmpi(arg,'ZoomMode')
                warnForOverride(arg)
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
            if ischar(arg) && strcmpi(arg,'PostViewChangeAction')
                myPostViewChangeAction = cParameters{kk + 1};
                valuesToDelete = [valuesToDelete kk:kk+1]; %#ok
            end
        end
        
        cParameters(valuesToDelete) = [];
        
        function warnForOverride(szParamName)
            warning('PWF:FeatureOverride', ...
                ['''' szParamName ''' is not user-changeable due internal '...
                'configuration of WaveformPlayer.'])
        end
    end


caParentDef{1} = 'Axes';

if ~isempty(hParentFig)
    hAxes = axes('Parent', hParentFig);
    
else
    hParentFig      = figure;
    hAxes           = axes('Parent', hParentFig);

    %% Retrieve screensize and center position
    set(0,'Units','pixels');
    vScrSze = get(0,'screensize');
    guiSize = [vScrSze(3:4)/2-guiSize(1:2)/2 guiSize(1:2)];
end

caParentDef{2} = hAxes;

caFuncPath = which('WaveformPlayer.m', '-all');
szFuncPath = fileparts(caFuncPath{1});
szSaveFile   = [szFuncPath   filesep     szSaveFileTitle];

if exist(szSaveFile,'file')
    load(szSaveFile, '-mat')
end
save(szSaveFile, 'globset*', 'gui*', '-mat')

set(hAxes, ...
    'units', 'normalized', ...
    'Position', vUpperAxesPos)


myPostZoomAction = @myPostActionCallback;
stFuncHandles.NewZoomPosition = myPostZoomAction;

if ispc
    guiFontSize        = 8;           % in pixels (default, Win)
else
    guiFontSize        = 10;           % in pixels (default, Unix)
end

%% Call the goddess of all-mighty PlotWaveform
[hFigure, ...
    hWaveAxes, ...
    ~, ...
    vZoomPosition, ...
    OrigStartEndVal, ...
    OrigSampleValuesPos, ...
    OrigSampleValuesNeg, ...
    OrigTime_vek, ...
    numChannels, ...
    ReadAndComputeMaxData, ...
    vWaveSize, fs] = PlotWaveform(szFileName, ...
    'ShowXAxisAbove', 1, ...
    'PostZoomAction', myPostZoomAction, ...
    'ColorsetFace',   myColorsetFace, ...
    'ColorsetEdge',   myColorsetEdge, ...
    'ChannelView', 1, ...
    'ZoomMode', 2, ...
    caLeftoverParams{:}, ...
    caParentDef{:});

vStartEndVal = [...
    vZoomPosition(1) vZoomPosition(1)+vZoomPosition(3) ...
    vZoomPosition(2) vZoomPosition(2)+vZoomPosition(4)];



    function ResetZoomWrapper
        ReadAndComputeMaxData([],[],1);
    end


% vSampleValues = OrigSampleValuesPos;

bMuteChannels = zeros(1, numChannels);

init();

% PlotWaveform/SetOriginalZoom;

%--------------------------------------------------------------------------
% SUBFUNCTIONS
%--------------------------------------------------------------------------

%% Function to retrieve the axes size
    function GetAxesSize
        set(hWaveAxes(1), 'Units', 'Pixels')
        vAxesSize = get(hWaveAxes(1), 'Position');
        set(hWaveAxes(1), 'Units', 'normalized')
        vAxesSize = vAxesSize(3:4);
    end

%% Function to calculate the spectrogram overlay
    function CalculateSpectrogram
    
        specProg = make_prog_bar('Spectrogram overlay');
        GetAxesSize();
        
        if bCalcSpectogram
            
            nBlockSize = iWinDef*100;
            nBlocks = ceil(vWaveSize(1)/nBlockSize);
            
            caOrigSpectrData = cell(nBlocks, vWaveSize(2));
            maOrigSpectrData = [];

            specProg('Generating full spectrogram', 1, nBlocks*vWaveSize(2));
            count = 1;
            
            for nBlockIdx=1:nBlocks
                
                
                if nBlockIdx*nBlockSize > vWaveSize(1)
                    blockEnd = vWaveSize(1);
                else
                    blockEnd = nBlockIdx*nBlockSize;
                end
                
                if bUseAudioread
                    curBlock = audioread(szFileName, ...
                        [(nBlockIdx-1)*nBlockSize+1 ...
                        blockEnd]);
                else
                    
                    curBlock = wavread(szFileName, ...
                        [(nBlockIdx-1)*nBlockSize+1 ...
                        blockEnd]);
                end
                for chanIdx=1:vWaveSize(2)
                    
                    specProg(count);
                    count = count+1;
                    

                    
                    curSpec = spectrogram(...
                        curBlock(:,chanIdx), iWinDef, [], iNFFTDef, 'yaxis');
                    
                    caOrigSpectrData{nBlockIdx, chanIdx} = curSpec;
                    
                    if nBlockIdx == nBlocks
                        
                        maOrigSpectrData(:,:,chanIdx) = 20*log10(abs(...
                            cell2mat(caOrigSpectrData(:,chanIdx)')));
                    end
                    
                end
            end
            specProg(count);
        else
            specProg('Reloading original data', 'info');
        end
        
        for xx=1:length(hWaveAxes)
            
            SpectrInterval(1) = floor(...
                vStartEndVal(1)/OrigStartEndVal(2)*size(maOrigSpectrData,2))+1;
            SpectrInterval(2) = floor(...
                vStartEndVal(2)/OrigStartEndVal(2)*size(maOrigSpectrData,2));
            
            SpectrData = maOrigSpectrData(...
                :, SpectrInterval(1):SpectrInterval(2), xx);
            
            specProg(['Resampling channel ' num2str(xx)], 1, 3);
            
            if size(SpectrData, 2) > vAxesSize(1)
                
                SpectrData = resample(SpectrData', 1, ...
                    floor(size(SpectrData, 2)/vAxesSize(1)))';

            end
            specProg(2);
            
            if size(SpectrData, 1) > vAxesSize(2)
                SpectrData = resample(SpectrData,  1, ...
                    floor(size(SpectrData, 1)/vAxesSize(2)));
                
                
            end
            specProg(3);
            
            SpectrData = flipud(SpectrData); % Fix for upside down y axis (1/2)
            
            hSpectrograms(xx) = imagesc(...
                vStartEndVal(1:2), ...
                [0 fs/2000], ...
                SpectrData, ...
                'Parent', hWaveAxes(xx), ...
                'Tag', 'spectrs', ...
                'Visible', 'on');

            szEval = ['colormap(hWaveAxes(' num2str(xx) '),' guiColormapDef ');'];
            
            eval(szEval);            
            hold(hWaveAxes(xx), 'off')
            set(hWaveAxes(xx), ...
                'YDir', 'normal');           % Fix for upside down y axis (2/2)
            
            if xx == 1
                set(hWaveAxes(xx), 'XAxisLocation', 'top');
            else
                set(hWaveAxes(xx), 'XTickLabel', '');
            end
            
            bCalcSpectogram = 0;
            OrigColormapVal = [];
                        
        end
        
        SetSpectrColordepth;
        specProg('done')

    end

%% Set the spectrogram's color depth
    function SetSpectrColordepth
        
        
        %% Different approach by completely reworking the CData (too intense)
%         for xx=1:numel(hSpectrograms)
%             
%             if isempty(OrigSpectrCData) || ...
%                     numel(OrigSpectrCData) < numel(hSpectrograms)
%                 OrigSpectrCData{xx} = get(hSpectrograms(xx), 'CData');
%             end
%             
%         end
%         
%         for xx=1:numel(hSpectrograms)
%             
%             lowestCData     = min(min(OrigSpectrCData{xx}));
%             highestCData    = max(max(OrigSpectrCData{xx}));
%             
%             for uu=1:size(OrigSpectrCData{xx},1)
%                 
%                 for vv=1:size(OrigSpectrCData{xx},2)
%                     
%                     if OrigSpectrCData{xx}(uu,vv) < -100+100*vColormapVal(1)
%                         CurSpectrCData{xx}(uu,vv) = lowestCData;
%                     elseif OrigSpectrCData{xx}(uu,vv) > -100+100*vColormapVal(2)
%                         CurSpectrCData{xx}(uu,vv) = highestCData;
%                     else
%                         CurSpectrCData{xx}(uu,vv) = OrigSpectrCData{xx}(uu,vv);
%                     end
%                 end
%             end
%             
%             set(hSpectrograms(xx), 'Cdata', CurSpectrCData{xx});
%             
%         end


        if bWaveDisplayType == 2

            if isempty(OrigColormapVal)
                OrigColormapVal =  get(hWaveAxes(1), 'CLim');
                vColormapVal = OrigColormapVal;
            end

            vColormapVal = sort(vColormapVal);
            
            for xx=1:numel(hSpectrograms)
                set(hWaveAxes(xx), 'CLim', vColormapVal);
            end

        end

    end
            
%% Initiation of interface and functionality
    function init
        
        if isempty(hParentFig)
            
            set(hFigure, ...
                'Position', guiSize, ...
                'Color', guiBackgroundColor)
            
            set(hFigure,'toolbar','none')
            set(hFigure,'menubar', 'none')
            
        else
            try guiBackgroundColor = get(hFigure, ...
                'Color');
            catch
                try guiBackgroundColor = get(hFigure, ...
                'BackgroundColor');
                catch error
                    warning('WFP:GatherBGColor', ...
                        ['Could not parse background: ' error.message]);
                end
            end
        end
        
        %% Generate zoom slider
        % retrieve position of lowest axis
        set(hAxes, 'units', 'normalized')
        vLastAxesPosition = get(hAxes, 'Position');
        
        % define the initial width of the zoom section
        iZoomWidth = vZoomPosition(3);
        hSliderHori = uicontrol('Style', 'slider',...
            'Min',OrigStartEndVal(1), ...
            'Max',OrigStartEndVal(2), ...
            'Value',(vZoomPosition(1)+iZoomWidth/2), ...
            'units', 'normalized', ...
            'Position', [ ...
            vLastAxesPosition(1) ...
            vLastAxesPosition(2)-0.041 ...
            vLastAxesPosition(3) ...
            0.04], ...
            'Callback', @CalcNewStartEndValHori, ...
            'Enable', 'off', ...
            'Parent', hFigure);
        
        %% Generate overview axes
        hOverviewAxes = axes('Parent', hFigure);
        
        set(hOverviewAxes, 'units', 'normalized')
        set(hOverviewAxes, 'Position', vOverviewAxesPos);
        for channel=1:numChannels
            fill([OrigTime_vek OrigTime_vek(end:-1:1)], ...
                [OrigSampleValuesPos(:,channel); ...
                flipud(OrigSampleValuesNeg(:,channel))],'b', ...
                'Parent', hOverviewAxes, ...
                'FaceAlpha',0.5, ...
                'EdgeAlpha',0.6, ...
                'FaceColor',myColorsetFace(mod ...
                (channel-1, size(myColorsetFace,1))+1,:), ...
                'EdgeColor',myColorsetEdge(mod ...
                (channel-1, size(myColorsetEdge,1))+1,:));
            hold(hOverviewAxes,'on');
        end
        
        axis(hOverviewAxes, OrigStartEndVal);
        hold(hOverviewAxes,'off');
                
        %% Insert position rectangle
        if isempty(hRect)
            hRect = rectangle('Parent', hOverviewAxes);
        end
        set(hRect, 'Position', vZoomPosition);        
        set(hRect, 'FaceColor', 'w')
        set(hRect, 'EdgeColor', 'k')
        
        set(hOverviewAxes, ...
            'Color', 'w', ...
            'Box', 'off', ...
            'XTickLabel', {''}, ...
            'YTickLabel', {''}, ...
            'XTick', [], ...
            'YTick', [], ...
            'Layer', 'top');
        
        %% Generate player controls
        icons.stop = zeros(iIconSize,iIconSize,3);
        icons.play = 0.941.*ones(iIconSize,iIconSize,3);
        icons.pause = zeros(iIconSize,iIconSize,3);
        icons.pause(:, ceil(iIconSize/2.6) : ...
            iIconSize-floor(iIconSize/2.6), :) = .941;
        
        for count = 1:iIconSize/2
            icons.play(count,1:2*count,1) = zeros(1,2*count);
            icons.play(count,1:2*count,2) = zeros(1,2*count);
            icons.play(count,1:2*count,3) = zeros(1,2*count);
            icons.play(iIconSize+1-count,1:2*count,1) = zeros(1,2*count);
            icons.play(iIconSize+1-count,1:2*count,2) = zeros(1,2*count);
            icons.play(iIconSize+1-count,1:2*count,3) = zeros(1,2*count);
        end
        
        vButtonSize = [0.1 0.6];
        
        %% Build the UI
        
        handles.hPlayer = uipanel(...
            'Parent', hFigure, ...
            'Units', 'normalized', ...
            'Position', [0.05 0.05 0.9 0.15], ...
            'BackgroundColor', guiBackgroundColor);
        
        handles.hPBPlay = uicontrol(...
            'Style', 'pushbutton', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.02 (1-vButtonSize(2))/2 vButtonSize], ...
            'CData', icons.play, ...
            'Callback', @CallbackPlay);
        
        handles.hPBPause = uicontrol(...
            'Style', 'pushbutton', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.02+(0.02+vButtonSize(1))*1 ...
            (1-vButtonSize(2))/2 vButtonSize], ...
            'CData', icons.pause, ...
            'Callback', @CallbackPause, ...
            'Enable', 'off');
        
        handles.hPBStop = uicontrol(...
            'Style', 'pushbutton', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.02+(0.02+vButtonSize(1))*2 ...
            (1-vButtonSize(2))/2 vButtonSize], ...
            'CData', icons.stop, ...
            'Callback', @CallbackStop, ...
            'Enable', 'off');
        
        handles.hCheckLoop = uicontrol(...
            'Style', 'checkbox', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.04+(0.02+vButtonSize(1))*3 ...
            0.55 0.15 0.3], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', 'Loop', ...
            'FontSize', guiFontSize, ...
            'Value', bPlayAsLoopFlag);
        
        handles.hCheckSelection = uicontrol(...
            'Style', 'checkbox', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.04+(0.02+vButtonSize(1))*3 ...
            0.15 0.4 0.3], ...
            'BackgroundColor', guiBackgroundColor, ...
            'String', 'Selection', ...
            'FontSize', guiFontSize, ...
            'Value', bPlaySelectionFlag);
        
        
        
        uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.09+(0.02+vButtonSize(1))*4 ...
            0.54 0.07 0.27], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', 'Start:', ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
        uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.09+(0.02+vButtonSize(1))*4 ...
            0.1 0.07 0.27], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', 'End:', ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
        uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.09+(0.02+vButtonSize(1))*4 ...
            0.39 0.07 0.20], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', 'Current:', ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left')   
        
        %% update GUI with new start and end time
        szSelectionStart = sprintf('%8.3f s', ...
            vZoomPosition(1));
        szCurrentPos = szSelectionStart;
        
        szSelectionEnd   = sprintf('%8.3f s', ...
            vZoomPosition(1)+vZoomPosition(3));
        
        %% Display current values
        handles.hValueSelectionStart = uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.05+(0.02+vButtonSize(1))*5 ...
            0.54 0.12 0.27], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', szSelectionStart, ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
        handles.hValueSelectionEnd = uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.05+(0.02+vButtonSize(1))*5 ...
            0.095 0.12 0.27], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', szSelectionEnd, ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
         handles.hValueCurrentPos = uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.05+(0.02+vButtonSize(1))*5 ...
            0.39 0.12 0.20], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', szCurrentPos, ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
        %% Radio buttons for Waveform or Spectrogram        
        hDataToggle = uibuttongroup( ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.06+(0.02+vButtonSize(1))*6 0.1 0.2 0.8], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'FontSize', guiFontSize, ...
            'SelectionChangeFcn', @SwitchWaveDisplay);        
        
        uicontrol(...
            'Style', 'radio', ...
            'Parent', hDataToggle, ...
            'Units', 'normalized', ...
            'Position', [0.05 0.55 0.9 0.4], ...
            'HandleVisibility', 'off', ...
            'String', 'Waveform', ...
            'Tag', '1');
        
        uicontrol(...
            'Style', 'radio', ...
            'Parent', hDataToggle, ...
            'Units', 'normalized', ...
            'Position', [0.05 0.05 0.9 0.4], ...
            'HandleVisibility', 'off', ...
            'String', 'Spectrogram', ...
            'Tag', '2');
%         
%         set(hDataToggle, ...
%             'SelectedObject', hWaveform)
        
        %% Checkmarks for channel muting
        for channel=1:numel(hWaveAxes)      
            hWaveAxesPos = get(hWaveAxes(channel), 'Position');
            
            ChanMuteXPos = hWaveAxesPos(1)+hWaveAxesPos(3)+0.005;
            
            handles.hCheckChanMute(channel) = uicontrol(...
            'Style', 'checkbox', ...
            'Parent', hFigure, ...
            'Units', 'normalized', ...
            'Position', [ChanMuteXPos hWaveAxesPos(2) ...
             1-ChanMuteXPos-0.001 hWaveAxesPos(4)], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', '', ...
            'FontSize', guiFontSize, ...
            'Value', bMuteChannels(channel), ...
            'Callback', @MuteChannel);
        end
        
        %% Callback for user changing mute state
        function MuteChannel(~, ~, ~)
           
           checkValue = get(handles.hCheckChanMute(:), 'Value');
           bMuteChannels = cell2mat(checkValue)';
           
        end
        
        %% - Menubar: Input Device Entry
        
        % gathering all the devices that have input capabilities
        if bPlaybackSupportFlag
            [stDevices, defaultIDs] = msound('deviceinfo');
            vOutputDevices = find([stDevices.outputs]>0);
            vSelectedDevice = zeros(1, length(vOutputDevices)+1);
            
            % menubar entry for default device ID 0 in Msound
            handles.hMenubarInterface = uimenu('Label','Audio');
            vSelectedDevice(1) = uimenu(handles.hMenubarInterface, ...
                'Label','(ID: 0) Default Device', ...
                'Callback',{@setOutputDeviceID, defaultIDs(2)});
            
            if globsetOutputID == 0
                set(vSelectedDevice(1), 'Checked', 'on');
            end
            
            
            % run through input devices, put IDs and name into menubar
            for kk=1:length(vOutputDevices)
                
                % separator above first devices (looks better)
                if kk == 1
                    szSepString = 'on';
                else
                    szSepString = 'off';
                end
                
                vSelectedDevice(kk+1) = uimenu(...
                    handles.hMenubarInterface, ...
                    'Label', ['(ID: ' num2str(vOutputDevices(kk)) ') ' ...
                    stDevices(vOutputDevices(kk)).('name')], ...
                    'Callback', ...
                    {@setOutputDeviceID, vOutputDevices(kk)}, ...
                    'Separator', szSepString);
                
                if vOutputDevices(kk) == globsetOutputID
                    set(vSelectedDevice(kk+1), 'Checked', 'on');
                end
                
            end
            
            getNumberOfOutputs(globsetOutputID);
            
        end
        
        %% - Menubar: Channel Routing Entry
        
        handles.hMenubarRouting = uimenu('Label','Routing');
        
        handles.RoutingEnDis(1) = uimenu(handles.hMenubarRouting, ...
            'Label','Enabled', ...
            'Callback',{@setRoutingOnOff, 1}, ...
            'Checked', 'on');
        
        handles.RoutingEnDis(2) = uimenu(handles.hMenubarRouting, ...
            'Label','Disabled', ...
            'Callback',{@setRoutingOnOff, 0});
        
        handles.RoutingModify = uimenu(handles.hMenubarRouting, ...
            'Label','Modify ...', ...
            'Callback',@modifyRouting, ...
            'Separator', 'on');
        
        %% - - Editfunction to modify the routing matrix
        function modifyRouting(~,~,~)
            
            %% Beautifying: Centering the routing matrix
            set(hFigure,'Units','pixels');
            vFigSze = get(hFigure, 'Position');
            auxSize = [...
                vFigSze(3:4)/2-auxSize(1:2)/2+vFigSze(1:2) ...
                auxSize(1:2)];
            
            %% Opening new figure
            hRoutingPanel = figure(...
                'Name', 'Routing Matrix', ...
                'NumberTitle', 'off', ...
                'Resize', 'off', ...
                'Position', auxSize, ...
                'Color', guiBackgroundColor);
            
            set(hRoutingPanel,'toolbar','none')
            set(hRoutingPanel,'menubar', 'none')
            
            hPanel = uipanel(...
                'Parent', hRoutingPanel, ...
                'Title', 'Routing Matrix', ...
                'Units', 'normalized', ...
                'Position', [0.05 0.05 0.9 0.9]);
            
            
            editColumns = true(1,numChannels);
            
            uitable(...
                'Parent', hPanel, ...
                'Data', routingMatrix, ...
                'Units', 'normalized', ...
                'Position', [0.05 0.05 0.9 0.9], ...
                'CellEditCallback', @cellEditCB, ...
                'ColumnEditable', editColumns);
            
        end
        
        %% - - Callback on user editing the routing matrix
        function cellEditCB(Object, ~, ~)
            routingMatrix = get(Object, 'Data');
            
        end
        
        %% - - Switching function for the routing matrix
        function setRoutingOnOff(Object, ~, bOnOff)
            
            set(handles.RoutingEnDis, 'Checked', 'off')
            
            set(Object, 'Checked', 'on')
            
            bRoutingEnabled = bOnOff;
            
        end
        
        %% - Menubar: Fourier Transform Window Size
                
        iWinMinLog2 = nextpow2(iWinMin);
        iWinMaxLog2 = nextpow2(iWinMax);
        
        iMaxWinCount = iWinMaxLog2-iWinMinLog2+1;
        
        handles.hMenubarWindowSize = uimenu('Label','Window');
        
        for windows=1:iMaxWinCount
            
            iWinSet = 2^(iWinMinLog2+windows-1);
            
            handles.WindowSize(windows) = uimenu(...
                handles.hMenubarWindowSize, ...
                'Label',sprintf('%i (2^%i)', ...
                iWinSet, ...
                iWinMinLog2+windows-1),...
                'Checked', 'off', ...
                'Callback',{@setWindowSize, iWinSet});
            
            if iWinSet == iWinDef
                set(handles.WindowSize(windows), 'Checked', 'on')
            end
            
            
        end    
        
        %% - - Callback on user changing window size
        function setWindowSize(Object,~, NewWinSize)
            
            set(handles.WindowSize(:), 'Checked', 'off');
            set(Object, 'Checked', 'on');
            
            iWinDef = NewWinSize;
            
            bCalcSpectogram = 1;
            CalculateSpectrogram();
            
        end

        %% - Menubar: Fourier Transform FFT Length
        
        iNFFTMinLog2 = nextpow2(iNFFTMin);
        iNFFTMaxLog2 = nextpow2(iNFFTMax);
        
        iMaxNFFTCount = iNFFTMaxLog2-iNFFTMinLog2+1;
        
        handles.hMenubarNFFTSize = uimenu('Label','NFFT');
        
        for nfft=1:iMaxNFFTCount
            
            iNFFTSet = 2^(iNFFTMinLog2+nfft-1);
            
            handles.NFFTSize(nfft) = uimenu(...
                handles.hMenubarNFFTSize, ...
                'Label',sprintf('%i (2^%i)', ...
                iNFFTSet, ...
                iNFFTMinLog2+nfft-1),...
                'Checked', 'off', ...
                'Callback',{@setNFFTSize, iNFFTSet});
            
            if iNFFTSet == iNFFTDef
                set(handles.NFFTSize(nfft), 'Checked', 'on')
            end
            
            
        end    
        
        %% - - Callback on user changing NFFT size
        function setNFFTSize(Object,~, NewNFFTSize)
            
            set(handles.NFFTSize(:), 'Checked', 'off');
            set(Object, 'Checked', 'on');
            
            iNFFTDef = NewNFFTSize;
            
            bCalcSpectogram = 1;
            CalculateSpectrogram();
            
        end
        
        %% - Menubar: Color Map for Spectrogram
        
        handles.hMenbuarColormap = uimenu('Label','Colormap');
        
        for nn=1:numel(myColormaps)
                        
            szColormap = regexprep(myColormaps{nn},'(\<[a-z])','${upper($1)}');
            
            handles.Colormap(nn) = uimenu(...
                handles.hMenbuarColormap, ...
                'Label', szColormap, ...
                'Checked', 'off', ...
                'Callback', @setColormap);
            
            if strcmpi(myColormaps{nn},guiColormapDef)
                set(handles.Colormap(nn), 'Checked', 'on')
            end            
        end    
        
        handles.Colormap(numel(myColormaps)+1) = uimenu(...
                handles.hMenbuarColormap, ...
                'Label', 'Modify ...', ...
                'Checked', 'off', ...
                'Callback', @modifyColormap, ...
                'Separator', 'on');
        
        %% - - Callback on user choosing color map
        function setColormap(Object, ~, ~)
            
           set(handles.Colormap(:), 'Checked', 'off');
           set(Object, 'Checked', 'on');
           
           guiColormapDef = lower(get(Object, 'Label'));
           
           
           for ax=1:numel(hWaveAxes)
               szEval =  ['colormap(hWaveAxes(' num2str(ax) '),' guiColormapDef ')'];

               eval(szEval);
           end
        end
        
        %% - - Callback on user modifying color map
        function modifyColormap(~,~,~)
        
        if ~isempty(OrigColormapVal)
            
            FigureHeight = 100;
            
            SliderVal(1) = OrigColormapVal(1)*(-1)+OrigColormapVal(1);
            SliderVal(2) = OrigColormapVal(1)*(-1)+OrigColormapVal(2);
            
            %% Beautifying: Centering figure to come
            set(hFigure,'Units','pixels');
            vFigSze = get(hFigure, 'Position');
            auxSize = [...
                vFigSze(3:4)/2-auxSize(1:2)/2+vFigSze(1:2) ...
                auxSize(1) FigureHeight];
            
            %% Building a new figure
            hColordepthPanel = figure(...
                'Name', 'Colormap Depth', ...
                'NumberTitle', 'off', ...
                'Resize', 'off', ...
                'Position', auxSize, ...
                'Color', guiBackgroundColor);
            
            set(hColordepthPanel,'toolbar','none')
            set(hColordepthPanel,'menubar', 'none')
            
            hPanel = uipanel(...
                'Parent', hColordepthPanel, ...
                'Title', 'Colormap Depth', ...
                'Units', 'normalized', ...
                'Position', [0.02 0.05 0.96 0.9], ...
                'BackgroundColor', guiBackgroundColor);
            
            %% Place sliders to modify high and low
            handles.hSliderColormapDepth(1) = uicontrol('Style', 'slider',...
                'Parent', hPanel, ...
                'Min',SliderVal(1), ...
                'Max',SliderVal(2), ...
                'Value',SliderVal(1), ...
                'units', 'normalized', ...
                'Position', [0.18 0.5 0.70 0.3], ...
                'Callback', @setNewColormapDepth);
            
            handles.hSliderColormapDepth(2) = uicontrol('Style', 'slider',...
                'Parent', hPanel, ...
                'Min',SliderVal(1), ...
                'Max',SliderVal(2), ...
                'Value',SliderVal(2), ...
                'units', 'normalized', ...
                'Position', [0.18 0.05 0.70 0.3], ...
                'Callback', @setNewColormapDepth);
            
            %% Label the sliders
            uicontrol('Style', 'text', ...
                'Parent', hPanel, ...
                'String', 'Lowest', ...
                'units', 'normalized', ...
                'Position', [0.02 0.5 0.15 0.3], ...
                'BackgroundColor', guiBackgroundColor-0, ...
                'HorizontalAlign', 'left');
            
            uicontrol('Style', 'text', ...
                'Parent', hPanel, ...
                'String', 'Highest', ...
                'units', 'normalized', ...
                'Position', [0.02 0.05 0.15 0.3], ...
                'BackgroundColor', guiBackgroundColor-0, ...
                'HorizontalAlign', 'left');
            
            %% Show the current slider/depth values
            handles.hValueColormapDepth(1) = uicontrol('Style', 'text', ...
                'Parent', hPanel, ...
                'String', sprintf('%3.1f',SliderVal(1)), ...
                'units', 'normalized', ...
                'Position', [0.91 0.5 0.08 0.3], ...
                'BackgroundColor', guiBackgroundColor-0, ...
                'HorizontalAlign', 'left');
            
            handles.hValueColormapDepth(2) = uicontrol('Style', 'text', ...
                'Parent', hPanel, ...
                'String', sprintf('%3.1f',SliderVal(2)), ...
                'units', 'normalized', ...
                'Position', [0.91 0.05 0.08 0.3], ...
                'BackgroundColor', guiBackgroundColor-0, ...
                'HorizontalAlign', 'left');
        end
        end
        
        %% - - - Callback to callback: Process new depth values
        function setNewColormapDepth(~, ~, ~)
            
            for pp=1:2
            
                vColormapVal(pp) = get(handles.hSliderColormapDepth(pp), 'Value');
                
                set(handles.hValueColormapDepth(pp), 'String', ...
                    sprintf('%3.1f',vColormapVal(pp)));
                
                vColormapVal(pp) = vColormapVal(pp)- OrigColormapVal(1)*(-1);

            end     
            
            SetSpectrColordepth();
            
            
        end
        
        %% Get msound going
        
        if bPlaybackSupportFlag
            msound('close');
            msound('openWrite', globsetOutputID, fs, iBlockLen, numOutputs);
        end
        
    end





%% Callback for user changing mute state
    function MuteChannel(~, ~, ~)
        
        checkValue = get(handles.hCheckChanMute(:), 'Value');
        bMuteChannels = cell2mat(checkValue)';
        
    end

%% Switch the type of display (waveform / spectrogram)
    function SwitchWaveDisplay(~, event)
        
        iCurState = str2double(get(event.NewValue, 'Tag'));
        
        
        switch iCurState
            case 1
                bWaveDisplayType = 1;
                ReadAndComputeMaxData();
                
            case 2
                bWaveDisplayType = 2;
                CalculateSpectrogram();

                
            otherwise
                error('Internal error. Exiting.')
        end
        
        if ~isempty(myPostViewChangeAction)
            myPostViewChangeAction(iCurState); %#ok
        end
        
    end

%% Function called while playing is activated
    function whilePlaying()

        PlayIdx = PlayIdx-1;
        curStartIdx = PlayIdx+vPlayStartEnd(1);
        
        while bIsPlayingFlag
            
            
            %% Redrawing the Interface
            tic
            
            if iRedrawCounter == iUpdateInterval
                iRedrawCounter = 0;
                
                if bPlaySelectionFlag
                    CurrentPos   = (vZoomPosition(1)*fs+PlayIdx)/fs;
                else
                    CurrentPos   = PlayIdx/fs;
                end
                szCurrentPos = sprintf('%8.3f s',CurrentPos);
                
                set(handles.hValueCurrentPos, ...
                    'String', szCurrentPos);
                
                set(hOverviewPos, ...
                    'XData', [CurrentPos CurrentPos]);
                
                if ~ishandle(hWavePos)
                    createWavePosLine;
                else
                    set(hWavePos, ...
                        'XData', [CurrentPos CurrentPos]);
                end
                
                drawnow;
                % SUPER INEFFICIENT! ALTERNATIVE?
            else
                iRedrawCounter = iRedrawCounter+1;
            end

            %% Actual Playback actions
            
            % Handle end of playback section first if occurs: needs zeropadding
            if vPlayStartEnd(1)+PlayIdx+iBlockLen-1 > vPlayStartEnd(2)
                
                % End of playback section is reached. Set flag.
                bIsEndOfWaveFlag = 1;
                
                % For left over samples: generate ZeroPadded block
                OutZP = zeros(iBlockLen, numChannels);
                
                if bUseAudioread
                     curBlock = audioread(szFileName, ...
                        [curStartIdx vPlayStartEnd(2)]);
                else
                curBlock = wavread(szFileName, ...
                    [curStartIdx vPlayStartEnd(2)]); %#ok
                end
                OutZP(1:length(curBlock),:) = curBlock;
                
                % Output
                T = toc;
                if bPlaybackSupportFlag
                    OutZPComplete = RoutingAndMuting(OutZP);
                    
                    msound('putsamples', ...
                        OutZPComplete);
                else
                    pause(iBlockLen/fs-T)
                end
                % Resetting playback index
                PlayIdx = 0;
                
                % In case of non-looped playback, kill the while loop
                if ~bPlayAsLoopFlag
                    bIsPlayingFlag   = 0;
                end
                
            elseif bIsPlayingFlag
                
                if bPlaybackSupportFlag
                    
                    if bUseAudioread
                        curBlock = audioread(szFileName, ...
                            [curStartIdx ...
                            curStartIdx+iBlockLen-1]);
                    else
                        curBlock = wavread(szFileName, ...
                            [curStartIdx ...
                            curStartIdx+iBlockLen-1]); %#ok
                    end
                    OutZPComplete = RoutingAndMuting(curBlock);
                    
                    msound('putsamples', ...
                        OutZPComplete);
                else
                    T = toc;
                    pause(iBlockLen/fs-T)
                end
                
                
                PlayIdx = PlayIdx+iBlockLen-1;
                curStartIdx = PlayIdx+vPlayStartEnd(1);
                
            end
        end
        
        % Activate the correct UI buttons
        set(handles.hPBPlay,     'Enable', 'on' )
        set(handles.hPBPause,    'Enable', 'off')
        
        if ~bIsPausedFlag
            delete(hOverviewPos);
            delete(hWavePos);
        end
        
        if bIsEndOfWaveFlag
            PlayIdx          = 1;
            bIsEndOfWaveFlag = 0;
            
            set(handles.hPBStop,     'Enable', 'off')

            
            szCurrentPos = sprintf('%8.3f s', ...
                vZoomPosition(1)+vZoomPosition(3));
            
            set(handles.hValueCurrentPos, ...
                'String', szCurrentPos)
        end
    end

%% Routing and Muting Process
    function ProcessingBlock = RoutingAndMuting(ProcessingBlock)
        
        %% Muting by the set checks
        PreMultiplier = mod(1,bMuteChannels);
        
        for mute=1:numChannels
            ProcessingBlock(:,mute) = PreMultiplier(mute).*ProcessingBlock(:,mute);
        end
        
        %% Routing by the routing matrix
        ProcessingBlockRouted = ...
            zeros(length(ProcessingBlock), numOutputs);
        
        if bRoutingEnabled
            
            for out=1:numOutputs
                for chan=1:numChannels
                    ProcessingBlockRouted(:, out) = ...
                        ProcessingBlockRouted(:, out) + ...
                        ProcessingBlock(:, chan)*routingMatrix(chan, out);
                end
            end
        else
            for out=1:numOutputs
                ProcessingBlockRouted(:, out) = ProcessingBlock(:, out);
            end
        end
        
        ProcessingBlock = ProcessingBlockRouted;
        
        
    end

%% Callback on user hit: play
    function CallbackPlay(~,~)
        
        bPlaySelectionFlag  = get(handles.hCheckSelection,  'Value');
        bPlayAsLoopFlag     = get(handles.hCheckLoop,       'Value');

        if bPlaySelectionFlag
            
            
            
            FrmBeg  = max([floor(vZoomPosition(1)*fs) 1]);
            FrmEnd  = floor((vZoomPosition(1)+vZoomPosition(3))*fs);
            
            vPlayStartEnd = [FrmBeg FrmEnd];
        else
            vPlayStartEnd = [1 vWaveSize(1)];
        end
        
        
       
        
        bIsPlayingFlag = 1;
        bIsPausedFlag  = 0;
        
       set(handles.hPBPlay, 'Enable', 'off')
       set(handles.hPBPause,'Enable', 'on')
       set(handles.hPBStop, 'Enable', 'on')
       
       if bPlaySelectionFlag
           CurrentPos   = (vZoomPosition(1)*fs+PlayIdx)/fs;
       else
           CurrentPos   = PlayIdx/fs;
       end
       szCurrentPos = sprintf('%8.3f',CurrentPos);
       
       set(handles.hValueCurrentPos, ...
           'String', szCurrentPos)
              
       if ishandle(hOverviewPos)
           delete(hOverviewPos)
       end
       
       if ishandle(hWavePos)
           delete(hWavePos)
       end
       
       
       hOverviewPos = line([CurrentPos CurrentPos],[-1.5 1.5], ...
           'Parent', hOverviewAxes, ...
           'Color', [000/255 000/255 000/255], ...
           'XData', [CurrentPos CurrentPos], ...
           'LineWidth', 1.5);
       
       hWavePos = zeros(1, length(hWaveAxes));

       createWavePosLine;
       
       whilePlaying();
       
    end

%% Callback on user hit: stop
    function CallbackStop(~,~)
                
        % Activate the correct UI buttons
        set(handles.hPBPlay,     'Enable', 'on' )
        set(handles.hPBPause,    'Enable', 'off')
        set(handles.hPBStop,     'Enable', 'off')
        
        % Reset index and flags
        PlayIdx          = 1;
        bIsPlayingFlag   = 0;
        bIsPausedFlag    = 0;
    end

%% Callback on user hit: pause
    function CallbackPause(~,~)
        
        set(handles.hPBPlay, 'Enable', 'on')
        set(handles.hPBPause, 'Enable', 'off')
        set(handles.hPBStop, 'Enable', 'on')

        bIsPlayingFlag = 0;
        bIsPausedFlag  = 1;
        
    end

%% Switch the input device (menubar)
    function setOutputDeviceID(object,~,devID)
        
        % Visually removing checkmarks from all the menu entries
        for nn=1:length(vOutputDevices)+1
            set(vSelectedDevice(nn), 'Checked', 'off');
        end
        
        
        % Receive number of output channels for routing
        getNumberOfOutputs(devID);
        
        % Visually setting a checkmark to the chosen menu entry
        set(object, 'Checked', 'on');
        
        % Setting the global variable to the chosen device ID
        globsetOutputID = devID;
        
        save(szSaveFile, 'globset*', '-mat', '-append')
        
        if bPlaybackSupportFlag
            msound('close')
            msound('openWrite', ...
                globsetOutputID, ...
                fs, ...
                iBlockLen, ...
                numOutputs);
        end
        

    end

%% Function to plot new positioning lines in all axes
    function createWavePosLine
        
        for nn=1:numel(hWaveAxes)
            
            hWavePos(nn) = line([CurrentPos CurrentPos],[-1.5 fs/2], ...
                'Parent', hWaveAxes(nn), ...
                'Color', [000/255 000/255 000/255], ...
                'XData', [CurrentPos CurrentPos], ...
                'LineWidth', 1.5); 
        end
    end

%% Function to gather the number of output devices
    function getNumberOfOutputs(devID)
        
        if devID == 0
            devID = defaultIDs(2);
        end
        
        stDevices = msound( 'deviceInfo');
        vActualDevice = [stDevices.id]==devID;
        numOutputs = stDevices(vActualDevice).('outputs');
        
        routingMatrix = eye(numChannels, numOutputs);
        
    end

%% Function to initiate the callback after an action
    function myPostActionCallback(ActualRectPosition, ~)
    
    if ActualRectPosition(1) >= OrigStartEndVal(2)
        ActualRectPosition(1) = OrigStartEndVal(2)-0.001;
    end
    if ActualRectPosition(2) > OrigStartEndVal(2)
        ActualRectPosition(2) = OrigStartEndVal(2);
    end
    if ActualRectPosition(1) < OrigStartEndVal(1)
        ActualRectPosition(1) = OrigStartEndVal(1);
    end
    if ActualRectPosition(2) < OrigStartEndVal(1)
        ActualRectPosition(2) = OrigStartEndVal(1)+0.001;
    end
    
    
    switch length(ActualRectPosition)
        case 2
    
            vZoomPosition(1) = ActualRectPosition(1);
            vZoomPosition(3) = ActualRectPosition(2)-ActualRectPosition(1);
            
            vStartEndVal(1:2) = ActualRectPosition(1:2);

            bActualIsOrig = sum(ActualRectPosition == OrigStartEndVal(1:2));
        case 4
            
            vZoomPosition =  [...
                ActualRectPosition(1) ...
                ActualRectPosition(3) ...
                ActualRectPosition(2)-ActualRectPosition(1) ...
                ActualRectPosition(4)-ActualRectPosition(3)];
            
            vStartEndVal = ActualRectPosition;
            
            
            bActualIsOrig = sum(ActualRectPosition == OrigStartEndVal);
        otherwise
            error('ActualRectPosition has to be 2 or 4 element vector')
    end
    
        set(hRect, 'Position', vZoomPosition);
        axis(hOverviewAxes,OrigStartEndVal);
                
        iZoomWidth = vZoomPosition(3);
        if bActualIsOrig == 0
            set(hSliderHori,'Enable', 'on', ...
                'Min',OrigStartEndVal(1)+iZoomWidth/2, ...
                'Max',OrigStartEndVal(2)-iZoomWidth/2, ...
                'Value',(vZoomPosition(1)+iZoomWidth/2));
            
            set(hRect, 'FaceColor', [0.9 0.9 1])
            set(hRect, 'EdgeColor', 'r')
        else
            set(hSliderHori,'Enable', 'off');
            set(hRect, 'FaceColor', 'w')
            set(hRect, 'EdgeColor', 'w')
        end
        
        if bWaveDisplayType == 2
            CalculateSpectrogram;
        elseif bWaveDisplayType == 1 && numel(ActualRectPosition) == 2
            ReadAndComputeMaxData(1, vStartEndVal);
        end
        
        if ~isempty(myPostZoomReturnStartEnd)
            myPostZoomReturnStartEnd(vStartEndVal(1:2)); %#ok
        end
        
        % update GUI with new start and end time
        szSelectionStart = sprintf('%8.3f s', ...
            vZoomPosition(1));
        szSelectionEnd   = sprintf('%8.3f s', ...
            vZoomPosition(1)+vZoomPosition(3));

        set(handles.hValueSelectionStart, ...
            'String', szSelectionStart)
        
        set(handles.hValueSelectionEnd, ...
            'String', szSelectionEnd)
        
        
    end

%% Function to calculate new start and end values horizontally
    function CalcNewStartEndValHori(h, ~)
        
        SliderValue = get(h, 'Value');
        StartEndVal(1) = SliderValue-iZoomWidth/2;
        StartEndVal(2) = SliderValue+iZoomWidth/2;
        
        YLims = get(hAxes, 'YLim');
        StartEndVal(3:4) = YLims(1:2);
        
        ReadAndComputeMaxData(1, StartEndVal);
        
        YLims = get(hAxes, 'YLim');
        StartEndVal(3:4) = YLims(1:2);
        
        vZoomPosition =  [...
            StartEndVal(1) ...
            StartEndVal(3) ...
            StartEndVal(2)-StartEndVal(1) ...
            StartEndVal(4)-StartEndVal(3)];
        set(hRect, 'Position', vZoomPosition);

        vStartEndVal = StartEndVal;
        
        iCurViewState = str2double(...
            get(get(hDataToggle, 'SelectedObject'), 'Tag'));
        
        switch iCurViewState
            case 1
                bWaveDisplayType = 1;
                ReadAndComputeMaxData();
                
            case 2
                bWaveDisplayType = 2;
                CalculateSpectrogram();
        end
                
        if ~isempty(myPostSlideAction)
           myPostSlideAction(vStartEndVal); %#ok
        end
        
    end

end

%%------------------------ Licence ----------------------------------------
% Copyright (c) <2011> Jan Willhaus
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