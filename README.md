# PLOTWAVEFORM waveform plotting

## Synposis
**PlotWaveform (PWF) is a MATLAB tool to plot the waveform of a WAVE-file using a block-by-block mean calculation algorithm, using a number of blocks defined by the size of the axis (and therefore the available pixelwidth) which enables the most precise rendering of the data while using less CPU cycles then in normal ```plot();``` calculation. Additionally PWF supports a secondary display layer, in which WAVE-data is plotted sample-exact just as the default ```plot();``` function would do. This layer is used only when a certain number of samples is not exceeded anymore. A third display layer supports the displayal of  sample-exact data in the views of ```stems();``` or ```stairs();``` functions. This view is set for the tightly zoomed WAVE portions.**

## Usage

```Matlab
[myFigure myAxes myPrint vZoomPosition OrigStartEndVal ... 
    OrigSampleValuesPos OrigSampleValuesNeg OrigTimeVec numChannels] = ... 
    PlotWaveform(szFileNameOrData, varargin)
```

## Parameters

```Matlab
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
%   'Axes':             user defined axes handle in which the waveform is
%                       desired to be plotted in. This is especially important
%                       if the function is used in multi-axes figures.
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
%   OrigSampleValuesNeg:returns the original sample values of the negative
%                       halfshaft to a superior function or script
%
%   OrigTimeVec:        returns the corresponding time vector for the
%                       sample values to a superior function or script
%
%   numChannels:        returns the number of channels in the WAVE
```

## Version History
```Matlab
%   Version History:
%   Ver. 0.01   initial proof of concept script             10-Aug-2011     JB
%   Ver. 0.10   inital build of the function                27-Aug-2011     JW
%   Ver. 0.11   implementing mono & stereo view             31-Aug-2011     JW
%   Ver. 0.12   debugging second zoom layer                 01-Sep-2011     JW
%   Ver. 0.21   implementing two-axis view for stereo       07-Sep-2011     JW
%   Ver. 0.22   adding possibility to read multichannel     08-Sep-2011     JW
%   Ver. 0.23   improvements on multi-axis view             15-Sep-2011     JW
%   Ver. 0.24   debugging zoom layer switch                 22-Sep-2011     JW
%   Ver. 0.25   improvements on second zoom layer           28-Sep-2011     JW
%   Ver. 0.30   implementing customized zoom menu           12-Oct-2011     JW
%   Ver. 0.31   debugging customized zoom menu              23-Oct-2011     JW
%   Ver. 0.32   code cleaning, killing matlab warnings      01-Dec-2011     JW
%   Ver. 0.40   implementing print-functionhandle           30-Jan-2012     JW
%   Ver. 0.50   implementing wave-overview                  15-Feb-2012     JW
%   Ver. 0.51   fixed faulty zoom extract                   16-Feb-2012     JW
%   Ver. 0.60   supports PlotWaveformOverview function      27-Feb-2012     JW
%   Ver. 0.61   code cleaning, updating the help info       09-Mar-2012     JW
%   Ver. 0.70   code cleaning again. ready for public       01-Jun-2012     JW
%   Ver. 0.71   fixed some UI glitches due to use of gca    12-jan-2013     JW
%   Ver. 0.80   added 'axes' behavioral setting             12-Jan-2013     JW
%
%   Ver. 0.90   tons of improvements due to extended        25-Feb-2013     JW
%               usage in WaveformPlayer:
%               * fixed heavy glitches in terms of multi-
%                 axes and -figure use: The behavior of the
%                 'Axes' function property now works and
%                 allows the user to plot waveforms in any
%                 already given axes.
%               * reset to original values now works 
%                 correctly when ChannelView is off and 
%                 supports alpha blending in this state.
%               * other small bugfixes and improvements.
%
%   Ver. 0.91   Fixed the multi-axes behavior. PWF can     09-Mar-2013     JW
%               now be placed in axes even with channel
%               view activated. All channels will be 
%               plotted in place of the "parent" axes.
%
%   Ver. 1.0    Major release! PWF is now extremely fast   06-Sep-2013      JW
%               in working with huge files, due to a new
%               approach to block-processing the wavread
%               itself. 1GB of wave can easily be loaded
%               in about 15 seconds, while staying low in
%               memory consumption.
%               Additional info: future versioning info 
%               will be placed inside the CHANGELOG.md 
%               file included in the repo. That way it is 
%               easier to handle the multiple functions of 
%               the bundle. Cheers!
```

## Licensing

**PLOTWAVEFORM** is available under X11 (so called *MIT*) license

Copyright (c) 2011-2012 Jan Willhaus, Joerg Bitzer (Institute for Hearing Technology and Audiology at Jade University of Applied Sciences)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
