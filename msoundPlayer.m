function stMsoundPlayer = msoundPlayer(varargin)
% Usage:
%   stMsoundPlayer = msoundPlayer({fs}, {blocklen})
%   stMsoundPlayer = msoundPlayer(WavFilename, {fs}, {blocklen})
%   stMsoundPlayer = msoundPlayer(inSamples, fs, {blocklen})
%
% Input:
%   WavFilename     Filename of Inputsignal
%   inSamples       Samples of Inputsignal
%   fs              Sampling Rate (default: 44100)
%   blocklen        Blocklen (default: 4096)
% Output:
%   stMsoundPlayer	MsoundPlayer-Object

% V 0.1    2011.05.03     S. Franz
if nargin == 0, help(mfilename); return; end;
if nargin > 3
    error('Only 3 Inputparameters (in, fs, blocklen) allowed!');
end
stSettings.in = [];
stSettings.fs = [];
stSettings.blocklen = [];

for iCount = 1 : length(varargin)
    var = cell2mat(varargin(iCount));
    if ischar(var)
        stSettings.in = var;
    elseif isnumeric(var)
        if length(var) == 1
            if isempty(stSettings.fs)
                stSettings.fs = var;
            elseif stSettings.fs < var
                stSettings.blocklen = stSettings.fs;
                stSettings.fs = var;
            else
                stSettings.blocklen = var;
            end
        else
            stSettings.in = var;
        end
    end
end
if isempty(stSettings.fs)
    stSettings.fs = 44100;
end
if isempty(stSettings.blocklen)
    stSettings.blocklen = stSettings.fs * (1024 * 4) / 44100;
end
stSettings.strPath = fileparts(mfilename('fullpath'));
stSettings.isPlaying = false;
stSettings.isPaused = false;
stSettings.firstStart = true;
stSettings.specLen = 2;
stSettings.specIdx = 0;
stSettings.maxSpecIdx = ceil(stSettings.fs / stSettings.blocklen) * stSettings.specLen;
stSettings.BlockProcess = 0;
stSettings.Samples = [];
stSettings.idx = [];
stSettings.currBlock = [];
stSettings.showSpecs = [1 1];
stSettings.showTimes = [1 1];
if exist([stSettings.strPath 'SpecSettings.mat'], 'file')
    showSpecs = [];
    showTimes = [];
    load([stSettings.strPath 'SpecSettings.mat']);
    stSettings.showSpecs = showSpecs;
    stSettings.showTimes = showTimes;
    clear showSpecs showTimes;
end

stMsoundPlayer.play = @play;
stMsoundPlayer.close = @close;
handles = struct();
handles.imagesc = struct();

init();

if ischar(stSettings.in)
    if exist(stSettings.in, 'file')
        [stSettings.Samples stSettings.fs] = wavread(stSettings.in);
        playButton();
    else
        error('File not found: %i', stSettings.in);
    end
elseif ~isempty(stSettings.in)
    stSettings.Samples = stSettings.in;
    playButton();
else
    set(handles.buttons.Play, 'enable', 'off');
    stSettings.BlockProcess = 1;
end

    function init()
        ImageSize = 16;
        handles.pictures.stop = zeros(ImageSize,ImageSize,3);
        handles.pictures.play = 0.9.*ones(ImageSize,ImageSize,3);
        handles.pictures.pause = zeros(ImageSize,ImageSize,3);
        handles.pictures.pause(:, 6 : 10, :) = .9;
        for count = 1:ImageSize/2
            handles.pictures.play(count,1:2*count,1) = zeros(1,2*count);
            handles.pictures.play(count,1:2*count,2) = zeros(1,2*count);
            handles.pictures.play(count,1:2*count,3) = zeros(1,2*count);
            handles.pictures.play(ImageSize+1-count,1:2*count,1) = zeros(1,2*count);
            handles.pictures.play(ImageSize+1-count,1:2*count,2) = zeros(1,2*count);
            handles.pictures.play(ImageSize+1-count,1:2*count,3) = zeros(1,2*count);
        end

        handles.figures.mainFigure.h = figure();
        set(handles.figures.mainFigure.h,  ...
            'Units', 'normalized', ...
            'resize','on',...
            'NumberTitle','off', ...
            'Position', [.1 .75 .8  .2] , ...
            'ToolBar', 'none', ...
            'KeyPressFcn', @onKeyPress, ...
            'MenuBar', 'none', ...
            'DeleteFcn', @closeWindow, ...
            'Name', 'msoundPlayer');

        handles.panel0 = uipanel('Title','Controls', 'Parent', handles.figures.mainFigure.h, 'position', [0 0 1/3 1], 'Units', 'normalized');

        handles.buttons.Play = uicontrol('Parent',handles.panel0,...
            'Units','Normalized',...
            'Position',[0/3+1/60 .7 1/3-2/60 .25],...
            'Style','PushButton',...
            'CData',handles.pictures.play, ...
            'enable', 'on', ...
            'Callback', @playButton);

        handles.buttons.Pause = uicontrol('Parent',handles.panel0,...
            'Units','Normalized',...
            'Position',[1/3+1/60 .7 1/3-2/60 .25],...
            'Style','PushButton',...
            'CData',handles.pictures.pause, ...
            'enable', 'off', ...
            'Callback', @pauseButton);

        handles.buttons.Stop = uicontrol('Parent',handles.panel0,...
            'Units','Normalized',...
            'Position',[2/3+1/60 .7 1/3-2/60 .25],...
            'Style','PushButton',...
            'CData',handles.pictures.stop, ...
            'enable', 'off', ...
            'Callback', @stopButton);

        handles.timeline = axes('Parent',handles.panel0,'Position',[1/60 .6 1-2/60 .05], 'ytick', [-.5 .5], 'yticklabel', {'' ''});
        plot(handles.timeline, [0 0] / stSettings.fs, [-.5 .5], 'r', 'LineWidth', 2);
        xlim(handles.timeline, [0 1]);
        set(handles.timeline, 'yticklabel', {});

        handles.panel1 = uipanel('Title','Channel 1', 'Parent', handles.figures.mainFigure.h, 'position', [1/3 0 1/3 1], 'Units', 'normalized');
        handles.spectogram1 = axes('parent', handles.panel1, 'OuterPosition', [0 0.1 1 .9]);
        hold(handles.spectogram1, 'on');
        handles.ChkSpectogram1 = uicontrol('Parent',handles.panel1,...
            'Units','Normalized',...
            'Position',[0 0 .5 .1],...
            'String', 'Spectogram', ...
            'Value', stSettings.showSpecs(1), ...
            'Style','Checkbox');

        handles.ChkTimesignal1 = uicontrol('Parent',handles.panel1,...
            'Units','Normalized',...
            'Position',[.5 0 .5 .1],...
            'String', 'Timesignal', ...
            'Value', stSettings.showTimes(1), ...
            'Style','Checkbox');

        handles.panel2 = uipanel('Title','Channel 2','Parent', handles.figures.mainFigure.h, 'position', [2/3 0 1/3 1], 'Units', 'normalized');
        handles.spectogram2 = axes('parent', handles.panel2, 'OuterPosition', [0 0.1 1 .9]);
        hold(handles.spectogram2, 'on');
        handles.ChkSpectogram2 = uicontrol('Parent',handles.panel2,...
            'Units','Normalized',...
            'Position',[0 0 .5 .1],...
            'String', 'Spectogram', ...
            'Value', stSettings.showSpecs(2), ...
            'Style','Checkbox');

        handles.ChkTimesignal2 = uicontrol('Parent',handles.panel2,...
            'Units','Normalized',...
            'Position',[.5 0 .5 .1],...
            'String', 'Timesignal', ...
            'Value', stSettings.showTimes(2), ...
            'Style','Checkbox');

        figure(handles.figures.mainFigure.h);
    end

    function isPlaying = play(in)
        if ishandle(handles.figures.mainFigure.h)
            set(handles.buttons.Stop, 'enable', 'on');
            stSettings.Samples = in;
            stSettings.SigLen = size(in, 1) / stSettings.fs;
            xlim(handles.timeline, [0 stSettings.SigLen]);
            stSettings.f = 0 : stSettings.fs/2;
            stSettings.t = 0 : 1 : stSettings.specLen;
            stSettings.idx = [0 size(in, 1)];
            if stSettings.firstStart == true
                msound('close');
                msound('openWrite', [], stSettings.fs, stSettings.blocklen, min(2, size(in, 2)), []);
                stSettings.firstStart = false;
                stSettings.isPlaying = true;
                stSettings.isPaused = false;
            end
            stSettings.currBlock = in(:, 1 : min(2, size(in, 2)));
            blockPlay();
            isPlaying = stSettings.isPlaying;
            drawnow;
        else
            isPlaying = false;
        end
    end

    function playButton(hObject, eventdata)
        if ~isempty(stSettings.Samples)
            set(handles.buttons.Play, 'enable', 'off');
            set(handles.buttons.Pause, 'enable', 'on');
            set(handles.buttons.Stop, 'enable', 'on');
            drawnow;
            if stSettings.isPlaying == false
                stSettings.SigLen = size(stSettings.Samples, 1) / stSettings.fs;
                xlim(handles.timeline, [0 stSettings.SigLen]);
                stSettings.isPlaying = true;
                stSettings.f = 0 : stSettings.fs/2;
                stSettings.t = 0 : 1 : stSettings.specLen;
                if isempty(stSettings.idx)
                    stSettings.idx = 1 : stSettings.blocklen;
                    if stSettings.firstStart == true
                        msound('close');
                        msound('openWrite', [], stSettings.fs, stSettings.blocklen, min(2, size(stSettings.Samples, 2)), []);
                        stSettings.firstStart = false;
                    end
                end
                while stSettings.isPlaying
                    if stSettings.isPaused == false
                        stSettings.currBlock = stSettings.Samples(stSettings.idx, 1 : min(2, size(stSettings.Samples, 2)));
                        blockPlay();
                        stSettings.idx = mod((stSettings.idx + stSettings.blocklen) - 1, size(stSettings.Samples, 1)) + 1;
                    end
                    drawnow;
                end
            else
                stSettings.isPaused = false;
            end
        end
    end

    function blockPlay()
        if stSettings.isPlaying && ishandle(handles.figures.mainFigure.h)
            set(get(handles.timeline, 'Children'), 'XData', [stSettings.idx(1) stSettings.idx(1)] / stSettings.fs);
            msound('putSamples', stSettings.currBlock);
            bFirst = false;
            if ishandle(handles.figures.mainFigure.h)
                if get(handles.ChkSpectogram1, 'Value') == 1 && size(stSettings.currBlock, 2) >= 1
                    mySpec = 20*log10(abs(spectrogram(stSettings.currBlock(:, 1), 'yaxis')) + eps);
                    if ~isfield(handles.imagesc, 'Spec1')
                        bFirst = true;
                        stSettings.spec1 = zeros(size(mySpec, 1), size(mySpec, 2) * stSettings.maxSpecIdx);
                        handles.imagesc.Spec1 = imagesc(stSettings.t, stSettings.f, stSettings.spec1, 'parent', handles.spectogram1, [-60 0]);
                        set(handles.spectogram1, 'YDir', 'normal');
                        if isfield(handles.imagesc, 'Time1')
                            delete(handles.imagesc.Time1);
                            handles.imagesc = rmfield(handles.imagesc, 'Time1');
                        end
                    end
                    stSettings.spec1(1:size(mySpec,1), (stSettings.specIdx * size(mySpec, 2) + (1 : size(mySpec, 2)))) = mySpec;
                    set(handles.imagesc.Spec1, 'CData', stSettings.spec1);
                elseif isfield(handles.imagesc, 'Spec1')
                    delete(handles.imagesc.Spec1);
                    handles.imagesc = rmfield(handles.imagesc, 'Spec1');
                end
                if get(handles.ChkSpectogram2, 'Value') == 1 && size(stSettings.currBlock, 2) >= 2
                    mySpec = 20*log10(abs(spectrogram(stSettings.currBlock(:, 2), 'yaxis')) + eps);
                    if ~isfield(handles.imagesc, 'Spec2')
                        bFirst = true;
                        stSettings.spec2 = zeros(size(mySpec, 1), size(mySpec, 2) * stSettings.maxSpecIdx);
                        handles.imagesc.Spec2 = imagesc(stSettings.t, stSettings.f, stSettings.spec2, 'parent', handles.spectogram2, [-60 0]);
                        set(handles.spectogram2, 'YDir', 'normal');
                        if isfield(handles.imagesc, 'Time2')
                            delete(handles.imagesc.Time2);
                            handles.imagesc = rmfield(handles.imagesc, 'Time2');
                        end
                    end
                    stSettings.spec2(1:size(mySpec,1), (stSettings.specIdx * size(mySpec, 2) + (1 : size(mySpec, 2)))) = mySpec;
                    set(handles.imagesc.Spec2, 'CData', stSettings.spec2);
                elseif isfield(handles.imagesc, 'Spec2')
                    delete(handles.imagesc.Spec2);
                    handles.imagesc = rmfield(handles.imagesc, 'Spec2');
                end
                if get(handles.ChkTimesignal1, 'Value') == 1 || get(handles.ChkTimesignal2, 'Value')
                    stepSize = 20;
                    currBlockTempBlock = stSettings.currBlock(1 : stepSize : end, :) * stSettings.fs / 4 + stSettings.fs / 4;
                    if ~isfield(stSettings, 'timeSignal') || isempty(stSettings.timeSignal)
                        stSettings.timeSignal = zeros(size(currBlockTempBlock, 1) * stSettings.maxSpecIdx, size(stSettings.currBlock, 2)) + stSettings.fs / 4;
                        if ~isfield(handles, 'timeSignal1') || ~ishandle(handles.timeSignal1)
                            handles.timeSignal1 = axes('parent', handles.panel1, 'Position',get(handles.spectogram1,'Position'), 'YAxisLocation','right', 'XTickLabel', [], 'Color','none', 'ylim', [-1 1]);
                        end
                    end
                    stSettings.timeSignal(stSettings.specIdx * size(currBlockTempBlock, 1) + (1 : size(currBlockTempBlock, 1)), :) = currBlockTempBlock;
                end
                if get(handles.ChkTimesignal1, 'Value') == 1 && size(stSettings.currBlock, 2) >= 1
                    if ~isfield(handles.imagesc, 'Time1')
                        bFirst = true;
                        handles.imagesc.Time1 = plot(handles.spectogram1, (0 : size(stSettings.timeSignal, 1) - 1) / stSettings.fs * stepSize, stSettings.timeSignal(:, 1), 'k');
                        if ~isfield(handles, 'timeSignal2') || ~ishandle(handles.timeSignal2)
                            handles.timeSignal2 = axes('parent', handles.panel2, 'Position',get(handles.spectogram2,'Position'), 'YAxisLocation','right', 'XTickLabel', [], 'Color','none', 'ylim', [-1 1]);
                        end
                    end
                    set(handles.imagesc.Time1, 'YData', stSettings.timeSignal(:, 1));
                elseif isfield(handles.imagesc, 'Time1')
                    delete(handles.imagesc.Time1);
                    handles.imagesc = rmfield(handles.imagesc, 'Time1');
                    stSettings.timeSignal(:, 1) = stSettings.timeSignal(:, 1) * 0 + stSettings.fs / 4;
                end
                if get(handles.ChkTimesignal2, 'Value') == 1 && size(stSettings.currBlock, 2) >= 2
                    bFirst = true;
                    if ~isfield(handles.imagesc, 'Time2')
                        handles.imagesc.Time2 = plot(handles.spectogram2, (0 : size(stSettings.timeSignal, 1) - 1) / stSettings.fs * stepSize, stSettings.timeSignal(:, 2), 'k');
                    end
                    set(handles.imagesc.Time2, 'YData', stSettings.timeSignal(:, 2));
                elseif isfield(handles.imagesc, 'Time2')
                    delete(handles.imagesc.Time2);
                    handles.imagesc = rmfield(handles.imagesc, 'Time2');
                    stSettings.timeSignal(:, 2) = stSettings.timeSignal(:, 2) * 0 + stSettings.fs / 4;
                end
                if bFirst
                    xlim(handles.spectogram1, [min(stSettings.t) max(stSettings.t)]);
                    ylim(handles.spectogram1, [min(stSettings.f) max(stSettings.f)]);
                    xlim(handles.spectogram2, [min(stSettings.t) max(stSettings.t)]);
                    ylim(handles.spectogram2, [min(stSettings.f) max(stSettings.f)]);
                end
                stSettings.specIdx = mod(stSettings.specIdx + 1, stSettings.maxSpecIdx);
            end
        else
            stopButton();
        end
    end

    function pauseButton(hObject, eventdata)
        set(handles.buttons.Play, 'enable', 'on');
        set(handles.buttons.Pause, 'enable', 'off');
        set(handles.buttons.Stop, 'enable', 'on');
        stSettings.isPaused = true;
    end

    function stopButton(hObject, eventdata)
        stSettings.isPlaying = false;
        stSettings.isPaused = false;
        stSettings.idx = [];
        if ishandle(handles.figures.mainFigure.h)
            if stSettings.BlockProcess == 0
                set(handles.buttons.Play, 'enable', 'on');
                set(handles.buttons.Pause, 'enable', 'off');
                set(handles.buttons.Stop, 'enable', 'off');
                if ~ischar(stSettings.in)
                    close();
                end
            else
                close();
            end
        end
    end

    function close()
        if ishandle(handles.figures.mainFigure.h)
            msound('close');
            delete(handles.figures.mainFigure.h);
        end
    end

    function onKeyPress(hObject, eventdata)
        if ishandle(handles.figures.mainFigure.h)
            if strcmp(eventdata.Key, 'x')
                close();
            elseif strcmp(eventdata.Key, 's')
                if strcmp(get(handles.buttons.Stop, 'enable'), 'on')
                    stopButton();
                end
            elseif strcmp(eventdata.Key, 'p')
                if strcmp(get(handles.buttons.Play, 'enable'), 'on')
                    playButton();
                elseif strcmp(get(handles.buttons.Pause, 'enable'), 'on')
                    pauseButton();
                end
            end
        end
    end

    function closeWindow(hObject, eventdata)
        if ishandle(handles.figures.mainFigure.h)
            showSpecs = [get(handles.ChkSpectogram1, 'Value') get(handles.ChkSpectogram2, 'Value')];
            showTimes = [get(handles.ChkTimesignal1, 'Value') get(handles.ChkTimesignal2, 'Value')];
            save([stSettings.strPath 'SpecSettings.mat'], 'showSpecs', 'showTimes');
            closereq();
        end
    end        
end