# PLOTWAVEFORM Changelog


## v1.1 (20-Mar-2014)

* A lot of minor fixes improving overall stability, including minor UI fixes

+ Changes are now documented in this very file (CHANGELOG.md), being outsourced from the functions head.

+ Support for the new `audioread()` function that was introduced to MATLAB. Thus Plotwaveform supports many more audio formats on newer MATLAB releases. Support for wavread is still present for older releases.

## v1.0 (06-Sep-2013)

* Major release!

+ Finally added support for block-processing of wav read-in. PWF is now extremely fast in working with huge files; 1GB of wave can easily be loaded in about 15 seconds, while staying low in memory consumption.

+ Additional info: future versioning info will be placed inside the CHANGELOG.md file included in the repo. That way it is  easier to handle the multiple functions of the bundle. Cheers!