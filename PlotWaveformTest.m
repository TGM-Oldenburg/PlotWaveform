clear
close all
disp('----------------- Start Tester -----------------')

% szFileName = '/Users/janwillhaus/Documents/MATLAB/ichwillnur.wav';

% szFileName = 'SampleShort.wav';
% szFileName = 'SampleMid.wav';
szFileName = 'SampleLong.wav';
% szFileName = 'D:\Audio\Movie Audio\Katze_auf_dem_heissen_Dach_ita';
% szFileName = 'song4channels.wav';
% szFileName = 'songLeftLoud.wav';
% szFileName = 'SampleFlipChannel.wav';
% szFileName = 'SampleShort8channels.wav';
% szFileName = 'TomShort.wav';
% % % for input data vector testing
% xyz = wavread(szFileName);
% Out = PlotWaveform(xyz,44100);
    
% for multiple argument testing
% manualColorsetFace = [0.75 0.75 0.75; 0 0 0];
% manualColorsetEdge = [0.1 0.1 0.1];
% h = PlotWaveform(szFileName, 'ChannelView', 1, 'ColorsetFace', manualColorsetFace, 'ColorsetEdge', manualColorsetEdge);
% h = PlotWaveform(szFileName, 'ChannelView', 1, 'Interval', [1 3.5]);
% h = PlotWaveform(szFileName, 'ChannelView', 1, 'PrintResolution', 150);
% h = PlotWaveform(szFileName, 'ChannelView', 1, 'PaperPosition', [0 0 16 5], 'SilentPrint', 1,'PrintResolution', 150, 'Interval', [0 0.1]);

% testing internal print via function handle
tic;
[hFigure hAxes hPrint]= PlotWaveform(szFileName,...
    'ChannelView',1,  'SampleViewStyle',1, 'Verbose',1);
toc;
%[hFigure hAxes hPrint]= PlotWaveform(szFileName,'ChannelView',1, 'SampleViewStyle',1);
% hPrint(gcf,'-depsc',sprintf('%s-SampleViewStyleTest.eps',szFileName),'-painters','PaperPosition', [2 2 16 10],'SilentPrint',0) 

% h = PlotWaveform(szFileName, 'ChannelView', 1);

% for standard testing
% h = PlotWaveform(szFileName);

% szFileName = input('Enter path to local file\n')
% h = PlotWaveform(szFileName, 'ChannelView', 1);
disp('----------------- Stop Tester -----------------')
