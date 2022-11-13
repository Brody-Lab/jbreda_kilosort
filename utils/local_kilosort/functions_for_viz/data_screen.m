% ---------------------
% written by Jess Breda 20200627
% purpose is to screen through channels in a .bin file, plot them and
% then extract for further kilosort testing. Put break point on line 47 to
% step through plots.
%
% TODO:
% - 
%
% INPUT PARAMETERS:
% - fname = .bin file of interest (assuming 8 tetrode)
% 
% 
% RETURNS:
% - none, but plots along the way and sample of interest can be written out
% in debugger
% 
% = EXAMPLE CALLS:
% - data_screen('data_sdb_20190609_123456_fromSD_secondbundle.bin')
% ---------------------
function data_screen(fname)

% open & read in binary file
fid=fopen(fname,'r');

% hard-coding chan number and sample rate
chan = 32
sfreq = 30000

  for x = 1:100 %randomly picked big number
    
    % now, read in data
    % format it as a matrix with chan rows and X samples of time
    
    ten_min = (10 * 60) * sfreq

    dataRAW = fread(fid, [chan ten_min/2], 'int16');
    
    for z = 1:8
        figure(1); subplot(chan/4,1,z); plot(dataRAW(z,:));
%         ylim([-25000 25000])
        title(sprintf('Loop %d', x));
        
    end
    
  %chan 6,17,19,20 = super noise
pwd
 % use this to plot all the electrodes in the debugger
%     for z = 1:chan
%         if z < (chan/2) + 1
%             figure(1); subplot(chan/2,1,z); plot(dataRAW(z,:));
%             title(sprintf('Loop %d', x)); 
%         else
%             figure(2); subplot(chan/2,1,z-16); plot(dataRAW(z,:))
%     end
%   
%   
    end
%   
    fclose(fid)
  
  % binary file to write to in debugger terminal when the time comes
%   fidw = fopen(sprintf('%s_good.bin',fname(1:end-4)), 'w');
%   fidw = fopen(sprintf('%s_bad.bin',fname(1:end-4)), 'w');
%   fwrite(fidw, dataRAW, 'int16')

end