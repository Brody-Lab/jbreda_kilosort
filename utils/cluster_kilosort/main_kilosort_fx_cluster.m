% adapted from KS2 main_kilosort.m on 20200803 by Jess Breda
% purpose is to run kilosort on TigerGPU

function main_kilosort_fx_cluster(pathtobin, pathtoconfig, start_time)

%% Things in this block that have been harded for my (JRB) use:
% path to kilosort folder
% path to npy library
% name of channel map
% time (start 250 in)
% config file name

% TODO
% align start of sorting to bdata

addpath(genpath('/scratch/gpfs/jbreda/ephys/kilosort/Brody_Lab_Ephys/utils/Kilosort2')) % path to kilosort folder
addpath('/scratch/gpfs/jbreda/ephys/kilosort/Brody_Lab_Ephys/utils/npy-matlab-master') % for converting to Phy
rootZ = pathtobin; % the raw data binary file is in this folder
rootH = rootZ; % path to temporary binary file (same size as data, should be on fast SSD)
pathToYourConfigFile = pathtoconfig; % take from Github folder and put it somewhere else (together with the main_file)
chanMapFile = 'KSchanMap_thousands.mat';


ops.trange = [start_time Inf]; % time range to sort (in seconds)
ops.NchanTOT    = 32; % total number of channels in your recording

run(fullfile(pathToYourConfigFile, 'StandardConfig_JB_20200803.m'))
ops.fproc       = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(pathToYourConfigFile, chanMapFile);

%% this block runs all the steps of the algorithm
fprintf('Looking for data inside %s \n', rootZ)

% is there a channel map file in this folder?
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
    ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
ops.fbinary = fullfile(rootZ, fs(1).name);

% preprocess data to create temp_wh.dat
rez = preprocessDataSub(ops);

% time-reordering as a function of drift
rez = clusterSingleBatches(rez);

% saving here is a good idea, because the rest can be resumed after loading rez
save(fullfile(rootZ, 'rez.mat'), 'rez', '-v7.3');

% main tracking and template matching algorithm
rez = learnAndSolve8b(rez);

% final merges
rez = find_merges(rez, 1);


% final splits by SVD
rez = splitAllClusters(rez, 1);

% final splits by amplitudes
rez = splitAllClusters(rez, 0);

% decide on cutoff
rez = set_cutoff(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, rootZ);

%% if you want to save the results to a Matlab file...

% discard features in final rez file (too slow to save)
rez.cProj = [];
rez.cProjPC = [];

% final time sorting of spikes, for apps that use st3 directly
[~, isort]   = sortrows(rez.st3);
rez.st3      = rez.st3(isort, :);

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(rootZ, 'rez2.mat');
save(fname, 'rez', '-v7.3');

% remove temp_wh file because it's huge and we don't need it
delete *.dat

end
