# PLOTWAVEFORM waveform plotting tool

## Synposis
**PlotWaveform plots the waveform of a WAVE-file, or vector of WAVE-data using a block by block mean calculation algorithm. WAVE-data first gets split into a number of blocks defined by the size of the axis (and therefore the available pixelwidth) which enables the most precise rendering of the data while using less CPU cycles then in normal plot calculation.**

## Usage

```Matlab
[myFigure myAxes myPrint vZoomPosition OrigStartEndVal …
   OrigSampleValuesPos OrigSampleValuesNeg OrigTimeVec numChannels] = …
    PlotWaveform(szFileNameOrData, varargin)
```


## Licensing

**PLOTWAVEFORM** is available under X11 (so called *MIT*) license

Copyright (c) 2011-2012 Jan Willhaus, Joerg Bitzer (Institute for Hearing Technology and Audiology at Jade University of Applied Sciences)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.