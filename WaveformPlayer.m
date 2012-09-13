function [hFigure, hWaveAxes, hOverviewAxes] = WaveformPlayer(szFileName)
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

%--------------------------------------------------------------------------
% VERSION 0.22
%   Author: Jan Willhaus (c) IHA @ Jade Hochschule
%   applied licence see EOF
%
%   Version History:
%   Ver. 0.01   initial creation of function              16-Jul-2012   JW
%   Ver. 0.10   first working build                       16-Jul-2012   JW
%   Ver. 0.20   basic functionality of playback           17-Jul-2012   JW
%   Ver. 0.21   position mark in all plots                19-Jul-2012   JW
%   Ver. 0.22   improved behavior at wave's end           20-Jul-2012   JW
%   Ver. 0.23   


%DEBUG
szFileName = 'sample4chanFlip.wav';
close gcf

if ismac
    disp('Macintosh is currently not supported.');
    disp('Use PlotWaveformOverview instead.');
    bPlaybackSupportFlag = 0;
%     return
else
    bPlaybackSupportFlag = 1;
end

vUpperAxesPos       = [ 0.05    0.45    0.90    0.50];
vOverviewAxesPos    = [ 0.05    0.23    0.90    0.15];

myColorsetFace      = [ 051/255 051/255 230/255; ...    % blue
                        230/255 051/255 051/255; ...    % red
                        051/255 230/255 051/255; ...    %
                        230/255 230/255 051/255; ...
                        230/255 051/255 230/255; ...
                        051/255 230/255 230/255];
myColorsetEdge      = [ 051/255 051/255 051/255];       % dark grey
guiBackgroundColor  = [ 229/255 229/255 229/255];       % light grey
guiSize             = [ 800 600];

%% Set global settings
szSaveFile  = 'WaveformPlayer.ini';
iBlockLen   = 1024*2;
iIconSize   = 24;
globsetOutputID    = 0;

%% Set global variables
PlayIdx         = 1;
mPlaybackData   = []; 
vZoomPosition   = [];
vButtonSize     = [];
vOutputDevices  = [];
vSelectedDevice = [];
vAxesSize       = [];
iZoomWidth      = [];
vStartEndVal    = [];
OrigSpectrData  = [];
routingMatrix   = [];
stDevices       = [];
numOutputs      = [];

%% Create prelim. flags
bPlaySelectionFlag  = 1;
bPlayAsLoopFlag     = 0;
bIsPlayingFlag      = 0;
bIsEndOfWaveFlag    = 0;
bIsPausedFlag       = 0;
bShowAsWaveform     = 1;
bShowAsSpectrogram  = 1;
bCalcSpectogram     = 1;
bRoutingEnabled     = 1;

%% Create empty handles
handles         = [];
icons           = [];
hRect           = [];
hSliderHori     = [];
hOverviewAxes   = [];
hOverviewPos    = [];
hWavePos        = [];
hSpecPlots      = [];
hSpectograms    = [];
hAxes           = axes;



%% Retrieve screensize and center position
set(0,'Units','pixels');
vScrSze = get(0,'screensize');
guiSize = [vScrSze(3:4)/2-guiSize(1:2)/2 guiSize(1:2)];


if exist(szSaveFile,'file')
    load(szSaveFile, '-mat')
end
save(szSaveFile, 'globset*', 'gui*', '-mat')

set(hAxes, ...
    'units', 'normalized', ...
    'Position', vUpperAxesPos)

myPostZoomAction = @myPostActionCallback;

if ispc
    guiFontSize        = 8;           % in pixels (default, Win)
else
    guiFontSize        = 12;           % in pixels (default, Unix)
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
    wavData, ~, fs] = PlotWaveform(szFileName, ...
    'ShowXAxisAbove', 1, ...
    'PostZoomAction', myPostZoomAction, ...
    'ColorsetFace',   myColorsetFace, ...
    'ColorsetEdge',   myColorsetEdge, ...
    'ZoomMode', 2);

vStartEndVal = [...
    vZoomPosition(1) vZoomPosition(1)+vZoomPosition(3) ...
    vZoomPosition(2) vZoomPosition(2)+vZoomPosition(4)];

% vSampleValues = OrigSampleValuesPos;

init();


CalculateSpectrogram();

% PlotWaveform/SetOriginalZoom;

    function GetAxesSize
        set(hWaveAxes(1), 'Units', 'Pixels')
        vAxesSize = get(hWaveAxes(1), 'Position');
        vAxesSize = vAxesSize(3:4);
    end

    function CalculateSpectrogram
        
        GetAxesSize();
        
        for xx=1:length(hWaveAxes)
            
            hold(hWaveAxes(xx), 'on')
            
            if bCalcSpectogram
                OrigSpectrData = 20*log10(abs(...
                    spectrogram(wavData(:, xx), 2^10, 'yaxis')));                
            end

            SpectrInterval(1) = floor(...
                vStartEndVal(1)/OrigStartEndVal(2)*size(OrigSpectrData,2))+1;
            SpectrInterval(2) = floor(...
                vStartEndVal(2)/OrigStartEndVal(2)*size(OrigSpectrData,2));
            
            SpectrData = OrigSpectrData(:, SpectrInterval(1):SpectrInterval(2));
            
            if size(SpectrData, 2) > vAxesSize(1)
                SpectrData = resample(SpectrData', 1, ...
                    floor(size(SpectrData, 2)/vAxesSize(1)))';
            end
            
            if size(SpectrData, 1) > vAxesSize(2)
                SpectrData = resample(SpectrData,  1, ...
                    floor(size(SpectrData, 1)/vAxesSize(2)));
            end
            
            
            
            hSpectograms(xx) = imagesc(...
                vStartEndVal(1:2), ...
                vStartEndVal(3:4), ...
                SpectrData, ...
                'Parent', hWaveAxes(xx), ...
                'Tag', 'spectrs', ...
                'Visible', 'on');
%             
%             bShowAsSpectrogram = get (handles.hCheckSpectrogram, 'Value');
%             switch bShowAsSpectrogram
%                 case 1
%                     set(hSpectograms(xx), 'Visible', 'on');
%                     
%                 case 0
%                     set(hSpectograms(xx), 'Visible', 'off');
%             end
%             
            
            axis(hWaveAxes(xx) ,'xy', 'tight');
            
            colormap(jet); view(0,90);
            
            hold(hWaveAxes(xx), 'off')
            
            bCalcSpectogram = 0;
        end
    end

%--------------------------------------------------------------------------
% SUBFUNCTIONS
%--------------------------------------------------------------------------

%% Initiation of interface and functionality
    function init
        
        set(hFigure, ...
            'Position', guiSize, ...
            'Color', guiBackgroundColor)
        
        %% Generate zoom slider
        % retrieve position of lowest axis
        set(gca, 'units', 'normalized')
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
            'Enable', 'off');
        set(gcf,'toolbar','none')   
        set(gcf,'menubar', 'none')
        
        %% Generate overview axes
        hOverviewAxes = axes;
        
        set(gca, 'units', 'normalized')
        set(gca, 'Position', vOverviewAxesPos);
        for channel=1:numChannels
            hWaveView = fill([OrigTime_vek OrigTime_vek(end:-1:1)], ...
                [OrigSampleValuesPos(:,channel); ...
                flipud(OrigSampleValuesNeg(:,channel))],'b');
            set(hWaveView,'FaceAlpha',0.5, 'EdgeAlpha',0.6, ...
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
        % set(hRect, 'FaceColor', [0.9 0.9 1])
        % set(hRect, 'EdgeColor', 'r')
        
        set(hRect, 'FaceColor', 'w')
        set(hRect, 'EdgeColor', 'k')
        
        % set(hOverviewAxes, ...
        %     'Color', guiBackgroundColor, ...
        %     'Box', 'off', ...
        %     'XGrid', 'on', ...
        %     'XMinorGrid', 'on', ...
        %     'Layer', 'top');
        
        set(hOverviewAxes, ...
            'Color', 'w', ...
            'Box', 'off', ...
            'XTickLabel', {''}, ...
            'YTickLabel', {''}, ...
            'XTick', [], ...
            'YTick', []);
        
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
        set(hFigure, 'CloseRequestFcn', @Destructor)
        
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
            0.54 0.15 0.27], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', szSelectionStart, ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
        handles.hValueSelectionEnd = uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.05+(0.02+vButtonSize(1))*5 ...
            0.1 0.15 0.27], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', szSelectionEnd, ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
         handles.hValueCurrentPos = uicontrol(...
            'Style', 'text', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.05+(0.02+vButtonSize(1))*5 ...
            0.39 0.14 0.20], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', szCurrentPos, ...
            'FontSize', guiFontSize, ...
            'HorizontalAlign', 'left');
        
        %% Checkmarks for Waveform and Spectrogram
         handles.hCheckWaveform = uicontrol(...
            'Style', 'checkbox', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.06+(0.02+vButtonSize(1))*6 ...
            0.55 0.2 0.3], ...
            'BackgroundColor', guiBackgroundColor-0, ...
            'String', 'Waveform', ...
            'FontSize', guiFontSize, ...
            'Value', bShowAsWaveform, ...
            'Callback', @SwitchShowWaveform);
        
        handles.hCheckSpectrogram = uicontrol(...
            'Style', 'checkbox', ...
            'Parent', handles.hPlayer, ...
            'Units', 'normalized', ...
            'Position', [0.06+(0.02+vButtonSize(1))*6 ...
            0.15 0.2 0.3], ...
            'BackgroundColor', guiBackgroundColor, ...
            'String', 'Spectrogram', ...
            'FontSize', guiFontSize, ...
            'Value', bShowAsSpectrogram, ...
            'Callback', @SwitchShowSpectrogram, ...
            'Enable', 'on');
        
       
        
      
        
        
        
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
        
        
        %% Get msound going
        
        if bPlaybackSupportFlag
            msound('close');
            msound('openWrite', globsetOutputID, fs, iBlockLen, numOutputs);
        end
        
    end


    function setRoutingOnOff(Object, ~, bOnOff)
        
        set(handles.RoutingEnDis, 'Checked', 'off')
        
        set(Object, 'Checked', 'on')
        
        bRoutingEnabled = bOnOff;
        
    end


    function modifyRouting(~,~,~)
        
        
        hRoutingPanel = figure(...
            'Name', 'Routing Matrix', ...
            'NumberTitle', 'off', ...
            'Resize', 'off', ...
            'Position', guiSize, ...
            'Color', guiBackgroundColor);
        
        set(gcf,'toolbar','none')
        set(gcf,'menubar', 'none')
        
        hPanel = uipanel(...
            'Parent', hRoutingPanel, ...
            'Title', 'Routing Matrix', ...
            'Units', 'normalized', ...
            'Position', [0.05 0.05 0.9 0.9]);
        
            
        editColumns = true(1,numChannels);
        
        hTable = uitable(...
            'Parent', hPanel, ...
            'Data', routingMatrix, ...
            'Units', 'normalized', ...
            'Position', [0.05 0.05 0.9 0.9], ...
            'CellEditCallback', @cellEditCB, ...
            'ColumnEditable', editColumns);

    end


    function cellEditCB(Object, ~, ~)
        routingMatrix = get(Object, 'Data');
        
    end

%% Switching function for the waveform display
    function SwitchShowWaveform(object,~)
        
        bShowAsWaveform = get(object, 'Value');
        
        hWavePlots = findobj('Tag', 'pwf_plots');
        
        switch bShowAsWaveform
            case 0
                for hh=1:length(hWavePlots)
                    set(hWavePlots(hh), 'Visible', 'off')
                end
                
            case 1
                for hh=1:length(hWavePlots)
                    set(hWavePlots(hh), 'Visible', 'on')
                end
        end
        
    end

%% Switching function for the spectrum display
    function SwitchShowSpectrogram(object,~)
        
        bShowAsSpectrogram = get(object, 'Value');
        
        hSpecPlots = findobj('Tag', 'spectrs');
        
        switch bShowAsSpectrogram
            case 0
                    for hh=1:length(hSpecPlots)
                        set(hSpecPlots(hh), 'Visible', 'off')
                        set(hSpectograms(hh), 'Visible', 'off');
                    end

            case 1
                    
                    for hh=1:length(hSpecPlots)
                        set(hSpecPlots(hh), 'Visible', 'on')
                        set(hSpectograms(hh), 'Visible', 'on');
                    end                   

        end
        
    end

%% Callback on user hit: play
    function CallbackPlay(~,~)
        
        bPlaySelectionFlag  = get(handles.hCheckSelection,  'Value');
        bPlayAsLoopFlag     = get(handles.hCheckLoop,       'Value');

        if bPlaySelectionFlag
            
            
            FrmBeg  = floor(vZoomPosition(1)*fs);
            FrmEnd  = floor((vZoomPosition(1)+vZoomPosition(3))*fs);
            
            if FrmEnd-FrmBeg < iBlockLen
                mPlaybackData = zeros(iBlockLen, numChannels);
                mPlaybackData(1:FrmEnd-FrmBeg,:) = ...
                    wavData(FrmBeg:FrmEnd,:);
            end
            
            mPlaybackData = wavData(FrmBeg:FrmEnd,:);
            
        else
            mPlaybackData = wavData;
        end
        
        mPlaybackDataRouted = ...
            zeros(length(mPlaybackData), numOutputs);
        
        if bRoutingEnabled
            
            for out=1:numOutputs
                for chan=1:numChannels
                    mPlaybackDataRouted(:, out) = ...
                        mPlaybackDataRouted(:, out) + ...
                        mPlaybackData(:, chan)*routingMatrix(chan, out);
                end
            end
        else
            for out=1:numOutputs
                mPlaybackDataRouted(:, out) = mPlaybackData(:, out);
            end
        end
        mPlaybackData = mPlaybackDataRouted;
        
        bIsPlayingFlag = 1;
        bIsPausedFlag  = 0;
        
       set(handles.hPBPlay, 'Enable', 'off')
       set(handles.hPBPause,'Enable', 'on')
       set(handles.hPBStop, 'Enable', 'on')

       
       CurrentPos   = (vZoomPosition(1)*fs+PlayIdx)/fs;
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
       
       for nn=1:numel(hWaveAxes)
       
           hWavePos(nn) = line([CurrentPos CurrentPos],[-1.5 1.5], ...
           'Parent', hWaveAxes(nn), ...
           'Color', [000/255 000/255 000/255], ...
           'XData', [CurrentPos CurrentPos], ...
           'LineWidth', 1.5);
       
       
       end
       
       whilePlaying();
       
    end

%% Function called while playing is activated
    function whilePlaying()

        while bIsPlayingFlag
            tic
            CurrentPos   = (vZoomPosition(1)*fs+PlayIdx)/fs;
            szCurrentPos = sprintf('%8.3f s',CurrentPos);
            
            set(handles.hValueCurrentPos, ...
                'String', szCurrentPos);
            
            set(hOverviewPos, ...
                'XData', [CurrentPos CurrentPos]);
            
            set(hWavePos, ...
                'XData', [CurrentPos CurrentPos]);
            
            drawnow;
            % SUPER INEFFICIENT! ALTERNATIVE?
            
            
            if PlayIdx+iBlockLen-1 > length(mPlaybackData)
                
                % End of wave is reached. Set flag
                bIsEndOfWaveFlag = 1;
                                
                % For left over samples generate ZeroPadded block
                OutZP = zeros(iBlockLen, numOutputs);
                
                % Determine where the padding starts
                EndOfSamples = length(mPlaybackData(PlayIdx:end, :));
                
                % Fill the vector with the left blocks, leaving the zero
                % padding at the end to fill the block length
                OutZP(1:EndOfSamples, :) = mPlaybackData(PlayIdx:end, :);
                
                % Output
                T = toc;
                if bPlaybackSupportFlag
                    msound('putsamples', ...
                        OutZP)
                else
                    pause(length(OutZP)/fs-T)
                end
                % Resetting playback index
                PlayIdx = 1;
                
                % In case of non-looped playback, kill the while loop
                if ~bPlayAsLoopFlag
                    bIsPlayingFlag   = 0;
                end
                
                
            elseif bIsPlayingFlag
                
                T = toc;
                if bPlaybackSupportFlag
                msound('putsamples', ...
                    mPlaybackData(PlayIdx:PlayIdx+iBlockLen-1, :));
                else
                    pause(iBlockLen/fs-T)
                end
                PlayIdx = PlayIdx+iBlockLen;
                
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

    function getNumberOfOutputs(devID)
       
        stDevices = msound( 'deviceInfo');
        vActualDevice = [stDevices.id]==devID;
        numOutputs = stDevices(vActualDevice).('outputs');
        
        routingMatrix = eye(numChannels, numOutputs);
        
    end

%% Function to initiate the callback after an action
    function myPostActionCallback(ActualRectPosition, ~)
        
        vZoomPosition =  [...
            ActualRectPosition(1) ...
            ActualRectPosition(3) ...
            ActualRectPosition(2)-ActualRectPosition(1) ...
            ActualRectPosition(4)-ActualRectPosition(3)];
        set(hRect, 'Position', vZoomPosition);
        axis(hOverviewAxes,OrigStartEndVal);
        
        vStartEndVal = ActualRectPosition;



        
        iZoomWidth = vZoomPosition(3);
        if vZoomPosition ~= OrigStartEndVal
            set(hSliderHori,'Enable', 'on', ...
                'Min',OrigStartEndVal(1)+iZoomWidth/2, ...
                'Max',OrigStartEndVal(2)-iZoomWidth/2, ...
                'Value',(vZoomPosition(1)+iZoomWidth/2));
            
            set(hRect, 'FaceColor', [0.9 0.9 1])
            set(hRect, 'EdgeColor', 'r')
        else
            set(hSliderHori,'Enable', 'off');
            set(hRect, 'FaceColor', guiBackgroundColor)
            set(hRect, 'EdgeColor', guiBackgroundColor)
        end
        
        CalculateSpectrogram;
        
        
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
    end

%% Destructor function
    function Destructor(~,~)
       
        % Close down audio
        if bPlaybackSupportFlag
            msound('close')
        end
        
                guiSize = get(gcf, 'Position');

        
        % Close figure by deleting its handle
        delete(gcf)
        
        
        
        save(szSaveFile, 'globset*', 'gui*', '-mat')
        
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