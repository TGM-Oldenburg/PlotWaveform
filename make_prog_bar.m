function h_prog_bar = make_prog_bar(headline)
% Usage: h_prog_bar = make_prog_bar(headline)%
% function that returns a function handle to a progress bar.
%
% headline - the... well... headline of the new generated progress bar
%
% The syntax of the function that the returned function handle points to
% is the following:
%
%      h_prog_bar(subsection_name, idx_min, idx_max)
%          to create a new subsection with an iteration counter that
%          goes from idx_min to idx_max.
%
%      h_prog_bar(k)
%          to update the progress bar (k is the current iteration value)
%
%      h_prog_bar(string, 'info')
%          prints an information to the command window
%
%      h_prog_bar('done')
%          displays a 'done' message in the command window
%
% Example:
%
%      h_prog_bar = make_prog_bar('ProgBar_Test1');
% 
%      h_prog_bar('first part', 1, 1000);
%      for k = 1 : 1000
%          h_prog_bar(k);
%          pause(0.01);
%      end
%
%      h_prog_bar('done');

% $Revision: 94 $
% $Author: brandt applied licence see EOF $
% $Date:   2011-09-08 14:49:56 +0200 (Do, 08 Sep 2011) $
% $Update: 2013-04-29 13:05, J.-A. Adrian (JA), included tick-ID to cope
%                                               with ticks outside the 
%                                               function.
%                                               Let Linux use the same
%                                               symbols as Windows. Only
%                                               Mac cannot display them

minValue = 0; %min
maxValue = 0; %max
lastProzValue = [];
section = [];
timerStarted = false;
numberOfDigits = -4;

% internal:
warnString = 'WARNING:';
infoString = '!';
if (~ismac) && ~isdeployed % (JA) use ascii symbols for win and linux
	lineChar = char(175);
	dotChar  = char(8226);
else
    lineChar = '~';
    dotChar  = '->';
%     lineChar = char(175);
% 	dotChar  = char(8226);
end

% write the headline:
line = repmat(lineChar, 1, length(headline));
headline = [headline] ;%'(<a href = "matlab:error(''STOPPED!'');">stop</a>)'];
fprintf('\n'); % one empty line...
disp(headline)
fprintf(line);

tID = [];   % (JA) use tick ID for robustness
h_prog_bar = @refreshProgBar;

% _________________________________________________________

    function refreshProgBar(varargin)
        if( nargin == 3 )
            newSection = varargin{1};
            if( ~strcmp(section, newSection) )
                fprintf(backspace(numberOfDigits));
                if( timerStarted )
                    t = toc(tID);
                    timeString = sprintf(' (%2.2fs)', t);
                    fprintf(timeString);
                end
                fprintf('\n%s %s... ', dotChar, newSection);
                section = newSection;
                numberOfDigits = 4;
                tID = tic;
                timerStarted = true;
            end
            minValue = varargin{2};
            maxValue = varargin{3};
        elseif nargin == 2
            string = varargin{1};
            if strcmp(varargin{2}, 'warn')
                fprintf('\n%s %s', warnString, string);
            elseif strcmp(varargin{2}, 'info')
                if( timerStarted )
                    fprintf(backspace(numberOfDigits));
                    numberOfDigits = 0;
                    t = toc(tID);
                    timeString = sprintf('(%2.2fs)', t);
                    fprintf(timeString);
                end
                timerStarted = false;
                fprintf('\n%s %s', infoString, string);
            else
                error('the second argument out of {''log'', ''info''} please!');
            end
        elseif( nargin == 1 )
            if ( strcmp(lower(varargin{1}), 'done') )
                if( timerStarted )
                    t = toc(tID);
                    fprintf(backspace(numberOfDigits));
                    fprintf(' (%2.2fs)', t);
                    numberOfDigits = 0;
                end
                fprintf('\n\nDONE!\n\n');
                %bing;   % make some noise
            else
                % progress update
                value = varargin{1};
                prozValue = round((value-minValue) / (maxValue-minValue) * 100);
                if isempty(lastProzValue) || prozValue ~= lastProzValue
                    vergangeneZeit = toc(tID);
                    remainingTime = vergangeneZeit * ( 1/(prozValue/100) - 1 );
                    remainingHours = floor(remainingTime/3600);
                    remainingMinutes = floor( (remainingTime - (3600*remainingHours)) / 60 );
                    remainingSeconds = floor(remainingTime - (3600*remainingHours) - (60*remainingMinutes));
                    fprintf([backspace(numberOfDigits) '... [%1.0f%%] - remaining: %02d:%02d:%02d'], prozValue, remainingHours, remainingMinutes, remainingSeconds);
                    numberOfDigits = length(num2str(round(prozValue))) + length(sprintf('%02d:%02d:%02d',remainingHours, remainingMinutes, remainingSeconds)) + 21;
                end
                lastProzValue = prozValue;
            end
        else
            error('Wrong number of arguments!');
        end
    end
end

function strOut = backspace(n)

strOut = repmat('\b', 1, n);

end




%--------------------Licence ---------------------------------------------
% Copyright (c) <2011> Matthias Brandt
% Institute for Hearing Technology and Audiology
% Jade University of Applied Sciences 
% 
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

