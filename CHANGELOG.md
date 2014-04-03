# PLOTWAVEFORM Changelog

## v2.1 (03-Apr-2014)

* [PWF] Drastically improved the performance of PlotWaveform's data read-in. The processing is now "block-in-block", meaning only a slightly increased memory consumption as the drawback for amazing read-in times. As a benchmark, I tested a 6 hour wavefile, which was read in  under 40 seconds. 

* [WFP] Much better buffer handling of Playrec internally.

* [WFP] Added a settings panel in the Menubar (Audio -> Modify ...) to manipulate basic parameters of Playrec audio. For example, if the playback is dropping samples, increase the blocksize or GUI update interval.

* [WFP] Restored the broken functionality of the settings file for figure and audio settings in the player. If the function is called on its own (not integrated in another script's figure), the figure size and audio settings are kept til next opening.

[Commits](../../compare/2.0...2.1)


## v2.0 (26-Mar-2014)

* [WFP] Swapped Msound with [Playrec](https://github.com/Janwillhaus/playrec) and removed the binaries from this repository. With Playrec in Matlab path you'll now be able to use the playback functionality of the WaveformPlayer even on Macintosh! Make sure to get the most recent binaries of Playrec: https://github.com/Janwillhaus/playrec/releases/latest

* [WFP] [PWF] Moved the older changelogs from inside the function headers into CHANGELOG.md's bottom. WFP and PWF shall from now on use the same version number, making it more of a bundle's version number.

[Commits](../../compare/1.1...2.0)


## v1.1 (20-Mar-2014)

* A lot of minor fixes improving overall stability, including minor UI fixes

+ Changes are now documented in this very file (CHANGELOG.md), being outsourced from the functions head.

+ Support for the new `audioread()` function that was introduced to MATLAB. Thus Plotwaveform supports many more audio formats on newer MATLAB releases. Support for wavread is still present for older releases.

[Commits](../../compare/1.0...1.1)


## v1.0 (06-Sep-2013)

* Major release!

+ Finally added support for block-processing of wav read-in. PWF is now extremely fast in working with huge files; 1GB of wave can easily be loaded in about 15 seconds, while staying low in memory consumption.

+ Additional info: future versioning info will be placed inside the CHANGELOG.md file included in the repo. That way it is  easier to handle the multiple functions of the bundle. Cheers!

[Commits](../../compare/7b8ded3...1.0)


***
*Quoted below is the version history before moving it to CHANGELOG.md (in its original, but reversed order)*

**PlotWaveform**

```
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
%   Ver. 0.91   Fixed the multi-axes behavior. PWF can     09-Mar-2013      JW
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



**WaveformPlayer**

```
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
```