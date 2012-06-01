clear; clc; close all;
blocklen = 1024 * 4;

%% Blockwise Output
[in fs] = wavread('TomShort.wav');
myMsoundPlayer = msoundPlayer(fs, blocklen);
idx = 1 : blocklen;
while idx(end) < length(in) && myMsoundPlayer.play(in(idx, :));
    idx = idx + blocklen;
end
myMsoundPlayer.close();

%% Complete Samples Output
myMsoundPlayer = msoundPlayer(in);

%% File Output
strFile = 'TomShort.wav';
msoundPlayer(strFile);
