% Script to test the PlotWaveformOverview function
% Author: Jan Willhaus (c) IHA @ Jade Hochschule applied licence see EOF 
% Version History:
% Ver. 0.01 copy inherited from PlotWaveformTest    21-Feb-2012     JW

clear
close all
fprintf('\n\n\n.\n.\n.\n-------------- Start Tester --------------\n')
tic
% szFileName = 'SampleShort.wav';
%   szFileName = 'SampleMid.wav';
szFileName = 'SampleLong.wav';
%szFileName = 'song4channels.wav';
% szFileName = 'songLeftLoud.wav';
% szFileName = 'SampleFlipChannel.wav';
% szFileName = 'SampleShort8channels.wav';

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

% figure
% set(gcf, 'Position', [80 536 1760 420]);
% testing internal print via function handle
[hFigure hAxes hOverview] = PlotWaveformOverview(szFileName);
%[hFigure hAxes hPrint]= PlotWaveform(szFileName,'ChannelView',1, 'SampleViewStyle',1);
% hPrint(gcf,'-depsc',sprintf('%s-SampleViewStyleTest.eps',szFileName),'-painters','PaperPosition', [2 2 16 10],'SilentPrint',0) 



T = toc;
fprintf('\nscript took %g seconds to finish.\n', T)
fprintf('\n-------------- Stop Tester --------------\n')

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