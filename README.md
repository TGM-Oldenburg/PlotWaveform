# PlotWaveform toolbox for Matlab audio data displayal

## Synposis
**PlotWaveform (PWF) is a Matlab tool to plot the waveform of a WAVE-file (or in newer Matlab versions even other formats using the ```audioread()``` function)using a block-by-block mean calculation algorithm. The number of blocks is defined by the size of the axis and therefore the available pixelwidth which enables the most precise rendering of the data while using less CPU cycles than with standard ```plot()``` generation. Additionally PWF supports a secondary display layer, in which audio data is plotted sample-exact just as the default ```plot()``` function would do. This layer is used only when a certain number of samples is not exceeded anymore. A third display layer supports the displayal of  sample-exact data in the views of ```stem()``` or ```stairs()``` functions. This view is set for the tightly zoomed audio portions.**

## Usage

__PlotWaveform__ is simply called with the filename of an audio file or with a vector audio samples in the first input argument. If executed with using a variable, the second input argument has to be the sampling rate. Either way numerous other function behavior modifiers are available (see list [below](#parameters)).

__WaveformPlayer__ is called the same way as PlotWaveform, only that it provides you with a basic audio player built right in. The integrated [Playrec](https://github.com/Janwillhaus/Playrec) audio playback and recording function is used to playback the displayed audio.

### Examples:
```Matlab
PlotWaveform('audiofile.wav');
PlotWaveform(audio_vec, fs);
PlotWaveform(__, 'ChannelView', 1);

WaveformPlayer('audiofile.wav');
WaveformPlayer(audio_vec, fs);
```

## Parameters

```Matlab
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
%   'Axes':             user defined axes handle in which the waveform is
%                       desired to be plotted in. This is especially important
%                       if the function is used in multi-axes figures.
%
%   'Verbose':          integer to which to set the verbose logging. While
%                       future versions may offer more depth in verbose,
%                       right now only 0 (off) and 1 (on) are supported.
```

## Version History

Please consult the [CHANGELOG.md](CHANGELOG.md)

## License

**PlotWaveform** is available under X11 license

Copyright (c) 2011-2014 Jan Willhaus, Joerg Bitzer (Institute for Hearing Technology and Audiology at Jade University of Applied Sciences)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
