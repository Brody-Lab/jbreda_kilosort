
# Ephys
working on ephys data analysis rotation proj.

# Data acquisition

Recordings from rats performing PWM task with 32 tetrode, 128 channel recordings targeting mPFC.


----------------------------------
# TODO
- save out mask in kilosort_preprocess to document how much is getting set to 0
- write a mega-fx to run all together
- in main_kilosort_forcluster_parallel_wrapper, remove temp_wh.dat to save space after kilosort has run


------------------------------------

# Spike Sorting: Cluster

## Pre-processing

### Spock
---
#### .rec, .dat, .mda --> .bin

**1.** Sign into spock
```
ssh yourid@spock
password
```
**2.** In scratch make sure there is a folder with your name and subfolder(s) with ephys/rat info. This is where you will clone the repo to, add unprocessed data into & use as `input_path` for first slurm scripts

```
/jukebox/scratch/*your folder*/ephys/*folder for raw data*
```
- **note:** you will need to get permission access to scratch from pnihelp via Chuck

**3.** Move files you want to process into `/jukebox/scratch/*your folder*/ephys/*folder for raw data*` (**do this on globus!**)

**4.** Clone jbreda_kilosort git hub repo to your scratch folder

```
cd /jukebox/scratch/*your folder*/ephys/*folder with raw data*
git clone https://github.com/Brody-Lab/jbreda_kilosort
```

**5.** Open `datrec_to_bin.sh` & edit `input_path` to be folder with raw data. Additionally, adjust paths in the header for job output/errors & email for job updates. If you are working with .mda files see step **7**.

```
cd /jukebox/scratch/*your folder*/ephys/*folder with raw data*/jbreda_kilosort
nano datrec_to_bin.sh
 --- in nano ---
input_path="/jukebox/scratch/*your folder*/ephys/*folder with raw data*"

!!!also adjust header for your ID!!!
```

slurm notes:
- 1. this is set to run on a Brody lab partition, remove the --partition line if this does not apply to you
- 2. rather than running on slurm via sbatch (step 7 below), if the job is small enough, you can allocate a node instead:
```
tmux new -s DescriptiveSessionName
salloc -p Brody -t 11:00:00 -c 11 srun -J <DescriptiveJobName> -pty bash
```
  - Creates a new shell on the node  with 11 cores & reserves for 11 hours
  - To exit screen: `Ctrl` + `b` + `d` See [Tmux cheatsheet](https://tmuxcheatsheet.com/) for more info


**6.** Run `datrec_to_bin.sh` to convert any .dat, .rec files --> .mda files --> .bin bundles for kilosort

```
cd /jukebox/scratch/*your folder*/ephys/*folder with raw data*/jbreda_kilosort
sbatch datrec_to_bin.sh
```

**Function highlights:**
- cds into input_path and makes an array of file names with .rec or .dat extension
- Loops over file names and passes each into `pipeline_fork2` to create .mda files
  - this function converts .dat and .rec files into .mda files
- in input_path with new .mda folders, passes them into `kilosortpipelineforcluster.m` along with the repo name and jobid
  - This function adds all needed paths & cds into correct directory before passing .mda folders into `tetrode_32_mdatobin_forcluster.m`
  - `tetrode_32_mdatobin_forcluster.m` takes directory of .mda folders, makes a new directory with jobid appended and converts each recording session into .bin files split into 4 groups of 8 tetrodes for each session

- (optional) link your working repo to this directory. Git add, commit & push `kilosort_slurm.sh` with job ID for your records to document what input was for the job

**7.** OPTIONAL .dat and .rec --> .mda or .mda --> .bin bundles

To break up conversion process you can run:

`datrec_to_mda.sh` and `mda_to_bin.sh` instead once header & `input_path` are changed

---
#### preprocess .bin

**1.** Run `kilosort_preprocess_to_sort.sh` to preprocess .bin files before passing into kilosort

**Function highlights:**
- takes given `input_path` and `repo_path` and passes them into `kilosort_preprocess_forcluster_wrapper.m`
  - this function adds appropriate matlab paths and then calls `kilosort_preprocess_forcluster.m`
- `kilosort_preprocess_forcluster.m`
  - iterates over each .bin file in a directory (`input_path`), applies a butterworth  highpass filter and then creates a mask for large amplitude noise and zeros it out
  - for each .bin file, creates a directory with its name and puts preprocessed file in it
  - see `kilosort_preprocess.m` for more information on input arguments & adjustments that can be made

**Steps to run (condensed version of steps 5-7 above)**
- If you've cloned this repo locally already, find its path & skip this step. If you have not, clone the github repo to your local machine. It is easiest to clone it to your `input_path` where the .bin files to be processed are.

```
cd /jukebox/scratch/*your folder*/ephys/*folder with raw data*/*jobid_binfilesforkilosort2*
git clone https://github.com/Brody-Lab/jbreda_kilosort
```

- Open `kilosort_preprocess_to_sort.sh` & edit `input_path` such that it is the directory containing .bin files to process. Edit the `repo_path` so that it points to this repo. Additionally, adjust paths in the header for job output/errors & email for job updates.

- Run
```
cd repo_path
sbatch kilosort_preprocess_to_sort.sh
```

## Kilosort 2
----
### tigerGPU
---
#### Single File

**1.** Sign into tigerGPU. If you're not authorized the OIT cluster fill out this form [here](https://forms.rc.princeton.edu/newsponsor/)
```
ssh yourid@tigergpu
password
```

**2.** Create a directory to move your preprocessed data into. For example, the file structure I use is:

`/scratch/gpfs/jbreda/ephys/kilosort/*{session}_Xbundle_TY_WZ_forkilosort*`

**3.** Move preprocessed file(s) from Spock to tigerGPU. Make a tmux screen if you are doing many files & want to close your computer.
```
tmux new -s DescriptiveSessionName
scp -r yourid@spock.princeton.edu:/jukebox/scratch/foldertotransfer yourid@tigergpu.princeton.edu:/scratch/gpfs/foldermadeinstep2```
```

**4.** Clone repo to this directory
```
cd /scratch/gpfs/jbreda/ephys/kilosort
git clone https://github.com/Brody-Lab/jbreda_kilosort`
```

**5.** Initiate the kilosort submodule (pulls their most recent commit)
```
cd jbreda_kilosort
git submodule init
git submodule update
```

**6.** Set up mex-cuda-GPU per kilosort [readme](https://github.com/MouseLand/Kilosort2)
**note:** unsure if this needs to be done each time or is a one time thing. Will get an error "Undefined function or variable 'mexThSpkPC'." if not set up properly
```
cd /utils/Kilosort2/CUDA
module purge
module load matlab2018b
mexGPUall.m
```

**7.** Edit weird spkTh bug

For whatever reason, the spkTh parameter is overwritten in the code and set much higher than we need (-6 versus -1.5 std)

```
cd /utils/Kilosort2/mainLoop
nano learnTemplates.m
```

Comment out:
```
% spike threshold for finding missed spikes in residuals                                                              
% ops.spkTh = -6; % why am I overwriting this here?
```

**8.** Edit config files & channel map (if needed)

Currently (August 2020), I am using a channel map for 8 tetrodes that has each tetrode spaced 1000 um from each other to prevent noise templates from being made. It can be found in:
`jbreda_kilosort/utils/cluster_kilosort/KSchanMap_thousands.mat`

Currently, I am using a config file with `ops.Th = [6 2]`, `ops.lam = 20`, `ops.SpkTh = =1.5`, `ops.CAR = 1`, `ops.fshigh = 300`. Otherwise, all parameters are default. These settings seem to work well for wireless ephys, but can easily be adjusted. Found in:
`jbreda_kilosort/utils/cluster_kilosort/StandardConfig_JB_20200803`

**note:** if you edit these files & give them different names, you must go into `main_kilsosort_fx_cluster.m` and change these names

**9.** Edit paths in `main_kilsosort_fx_cluster.m`

I've hard coded these because they shouldn't change from run to run but will change form person to person. This depends on how you structure your files on tigerGPU. If you have a directory with the structure: `/scratch/gpfs/jbreda/ephys/kilosort/jbreda_kilosort` all you will need to do is change `jbreda` --> `yourid` in the paths provided

Paths to change:
- path to kilosort folder
- path to npy-master

**10.** Edit `input_path`, `repo_path` and `config_path` in `kilosort.sh` along with header information in preparation for run.

`input_path` = directory that preprocess .bin file is in
`repo_path` = path to jbreda_kilosort repository
`config_path` = where your channel map and config file are located
- **note:** the config path also needs to contain `main_kilosort_fx_cluster.m` and `main_kilosort_forcluster_wrapper.m`. They are currently all stored in `/utils/cluster_kilosort`, so this only applies if you change the structure of the repository.

**11.** Run `kilosort.sh`

```
cd repo_path
sbatch kilosort.sh
```
**Function highlights:**
- takes paths outlined above, cds into config_path, loads matlab and then passes information into `main_kilosort_forcluster_wrapper.m` along with the sorting start time
  - start time currently set to 500 seconds to skip noisy file start that gets 0 out in preprocessing
- wrapper fx adds all the necessary paths and then passes information into `main_kilsort_fx_cluster`
- main_fx is adapted from `main_kilosort.m` from [Kilosort](https://github.com/MouseLand/Kilosort2/blob/master/main_kilosort.m). It takes directory with .bin file, directory with config information and start_time as arguments and then runs Kilosort2
- **returns** in `input_path` outputs for [Phy Template GUI](https://github.com/cortex-lab/phy) are generated

optional: git add, commit, push here to document jobid & file(s) sorted

**12.** Move sorted files back to spock/jukebox for manual sorting in Phy
```
tmux new -s DescriptiveSessionName
scp -r yourid@tigergpu.princeton.edu:/input_path yourid@spock.princeton.edu:/jukebox/whereyoustore/storedfiles
```
---
#### Many files

**1.** Sign into tigerGPU. If you're not authorized the OIT cluster fill out this form [here](https://forms.rc.princeton.edu/newsponsor/)
```
ssh yourid@tigergpu
password
```

**2.** Create a directory to move your preprocessed data & logs into. For example, the file structure I use is:

`/scratch/gpfs/jbreda/ephys/kilosort/*Rat_Name*`

Because so many jobs are running, I like to easily transfer my logs with my files after kilosort & this is the structure I use:

```
cd /scratch/gpfs/jbreda/ephys/kilosort/*Rat_Name*
mkdir logs
```

**3.** In a second window, sign into Spock and navigate to where your preprocessed files are located. ***I am assuming the structure I outlined above is being used*** where a `binfilesforkilsort2_jobid` folder contains raw .bin bundle files and, for each file, a directory containing preprocessed file with `_forkilosort` label.

```
ssh yourid@spock
password

cd /jukebox/scratch/jbreda/ephys/Rat_Name/binfilesforkilsort2_jobid
```

**4.** Make a new directory, move **only** preprocessed files into this directory. Check the size & request more quota on tigerGPU if needed

We are doing this so we can copy only these files to tigerGPU (and then back to jukebox)

```
--- in Spock ---
mkdir preprocessed_Rat_Name_jobid
cd preprocsessed_Rat_Name_jobid

# only move contents that have _forkilosort in name
mv /scratch/jbreda/ephys/Rat_Name/binfilesforkilsort2_jobid/*_forkilosort .

# size check
du -sh
```

```
--- in tigerGPU ---
checkquota
```

if `du -sh > checkquota`, submit a request for more space [here](https://forms.rc.princeton.edu/quota/)

**5.** Transfer preprocessed files to TigerGPU

```
--- In tigerGPU or Spock ---
tmux new -s transfer
scp -r jbreda@spock.princeton.edu:/jukebox/scratch/jbreda/ephys/Rat_Name/binfilesforkilosort2_jobid/preprocessed_Rat_Name_jobid jbreda@tigergpu.princeton.edu:/scratch/gpfs/jbreda/ephys/kilosort/*Rat_Name*
 ```

*Assuming steps 4-9 in "Single File" directions have been completed. If not, complete them now*

These steps include:
- cloning repo
- initializing kilosort on a new machine
- adjusting kilosort parameters/channel map
- adjusting hard coded input paths in kilosort fxs

**6.** Find length of number of .bin files you want to process (optional)

You could run the array job from 0 to a large number, but it's nice to know how many should be run and run +1 of that so you don't have an unnecessary amount of logs

```
--- In TigerGPU ---
cd /scratch/gpfs/jbreda/ephys/kilosort/*Rat_Name*/preprocessed_Rat_Name_jobid
ls | wc -1
```

**7.** Edit `input_base_path`, `repo_path` and `config_path` in `kilosort_parallel.sh` along with header information in preparation for run.

`input_base_path` = directory containing directories of .bin files to pass into kilosort
`repo_path` = path to jbreda_kilosort repository
`config_path` = where your channel map and config file are located
- **note:** the config path also needs to contain `main_kilosort_fx_cluster.m` and `main_kilosort_forcluster_parallel_wrapper.m`. They are currently all stored in `/utils/cluster_kilosort`, so this only applies if you change the structure of the repository.


**8.** Run `kilosort_parrallel.sh`

Example with 120 preprocessed directories
```
cd repo_path
sbatch --array=0-120 kilosort_parallel.sh
```

**Function highlights:**
- given `input_base_path` contains X directories where each directory contains a preprocessed .bin file ready for kilosort, creates a list of each directory in `input_base_path` called `bin_folders_arr`
- cds into `config_path`, and passes information into `main_kilosort_forcluster_parallel_wrapper.m` with array task_ID number
  - effectively submitting a separate job for each directory in the base path
  - array ID task number is used to index into directory list to create a full path from the base path
  - start time currently set to 500 seconds to skip noisy file start that gets 0 out in preprocessing
- wrapper fx adds all the necessary paths and then passes information into `main_kilsort_fx_cluster`
- main_fx is adapted from `main_kilosort.m` from [Kilosort](https://github.com/MouseLand/Kilosort2/blob/master/main_kilosort.m). It takes directory with .bin file, directory with config information and start_time as arguments and then runs Kilosort2
- **returns** in `input_base_path + bin_folders_arr[array_ID]` where `array_ID = {0,1,..X}`, outputs for [Phy Template GUI](https://github.com/cortex-lab/phy) are generated

optional: git add, commit, push here to document jobid & file(s) sorted

**9.** Move sorted files & logs back to spock/jukebox for manual sorting in Phy (assumes you store your logs like I do, see **step 2**)
```
tmux new -s DescriptiveSessionName
scp -r yourid@tigergpu.princeton.edu:/scratch/gpfs/jbreda/ephys/kilosort/*Rat_Name* yourid@spock.princeton.edu:/jukebox/whereyoustore/storedfiles
```


-----------------------

# Spike Sorting: Local

## Pre-processing
---
#### .rec, .dat --> .mda
Steps modified from [here](https://brodylabwiki.princeton.edu/wiki/index.php?title=Internal:Wireless_Ephys_Instructions). 1-2 only needed for first time use

**1.** In scratch make sure there is a folder with your name and subfolder with ephys/rat info. This is where you will run and save your data from/to

`/jukebox/scratch/*your folder*/ephys/*folder for raw data*`
- note: you will need to get permission access to scratch from pnihelp via Chuck


**2.** Clone `jbreda_kilosort` github repo into your scratch data folder

```
cd /jukebox/scratch/*your folder*/ephys/*folder for raw data*
git clone https://github.com/Brody-Lab/jbreda_kilosort
```

Then, copy the trodes config file up out of the repo and into the folder so it is on the same level as the data (this is automatically done if running `kilosort_slurm.sh`). It's okay if it is already there, it will be copied over.
```
cd /jukebox/scratch/*your folder*/ephys/*folder for raw data*
cp jbreda_kilosort/128_Tetrodes_Sensors_CustomRF.trodesconf .  
```

Repo function highlights:
- `pipeline_fork2.sh` converts .dat or .rec files to .mda files
- `tetrode_32_mdatobin` converts .mda files into .bin files and splits 32 tetrodes into groups of 8 to reduce processing time
- `kilosort_preprocess` removes large noise artifacts & persistent noise from .bin files so they don't eat up templates in kilosort


**3.** In globus, take a .dat or .rec file(s) from archive and copy it into your scratch folder

Stored in: `/jukebox/archive/brody/RATTER/PhysData/Raw/*your folder*/*your rat*/*session file*`
Move to: `/jukebox/scratch/*your folder*/ephys/*folder for raw data*`

File format:
- previous pipeline.sh versions needed file in specific naming format (see wiki for more info)
- this is no longer the case, just needs to be `.dat` or `.rec`
- Brody lab naming conventions = `{session}.dat` or `{session}.rec` where `{session}` = any string with data/tetrode/rat information

**4.** Sign into spock and create a new tmux screen in the repo.

```
ssh yourid@spock
password

cd  /jukebox/scratch/*your folder*/ephys/*folder with raw data*

tmux new -s <DescriptiveSessionName>
```
To exit screen: `Ctrl + b + d` See [Tmux cheatsheet](https://tmuxcheatsheet.com/) for more info

**5.** Grab a Brody lab node

`salloc -p Brody -t 4:00:00 -c 11 srun --pty bash`
  - Creates a new shell on the node  with 11 cores & reserves for 4 hours

**6.** Run the pipeline_fork2.sh (pipeline for kilosort 2) `pipeline_fork2 "{session}.dat"` OR `pipeline_fork2 "{session}.rec"`

**overall:** converts .dat or .rec files to .mda files
  - This is a modified version of `pipeline.sh` written by Marino

*this function takes:*
- a .dat or .rec file in strings
- ex: `pipeline_fork2 "{session}.dat"` OR `pipeline_fork2 "{session}.rec"`

*this function performs:*
- Step 1 converts from .dat → .rec (skipped if .rec file is passed)
  - Using sdtorec from [trodes](https://bitbucket.org/mkarlsso/trodes/wiki/SDFunctions/)
  - takes number of channels and [trodes configuration settings](https://bitbucket.org/mkarlsso/trodes/wiki/Configuration/) as inputs
- Step 2 converts from .rec → .mda
  - Using exportdio and export from [trodes & ,mountainlab](https://bitbucket.org/mkarlsso/trodes/wiki/ExportFunctions/)

*this function returns:*
- In `/jukebox/scratch/*your folder*/ephys/*folder with raw data*` there will be a directory named `{session}.mda`
- `{session}.mda` will contain .mda files, .matlab files and results files
- we only care about the .mda files that have the naming convention:
  - `{session}.ntX.referenced` where `X = channel number`
  - they will all be the same size and there will be 32 of them

_#### .mda --> .bin bundles_

**7.** Run `tetrode_32_mdatobin.m`(once you've pulled files down from jukebox)

**overall:** takes 32 channel .mda files and converts them to 4 .bin files in groups of 8 tetrodes

*this function optionally takes:*
- a directory containing output(s) from pipeline function above, or current working directory with no argument
  - multiple mda output folders can be in directory (ie multiple sessions can be run at the same time)
      - mda folder format: `/jukebox/scratch/*your folder*/ephys/*folder with raw data*/{session}.mda/*32_mda_files_here*`
        - for this example, you'd want to run the function from the directory `/jukebox/scratch/*your folder*/ephys/*folder with raw data*`
  - note: the .mda files **must** all be the same size for this function to properly work/for you to be running it on the correct files
  - directory is flexible for mac or pc

*this function performs:*
- `readmda` from MountainSort repo see [here](https://github.com/flatironinstitute/mountainlab-js/blob/master/utilities/matlab/mdaio/readmda.m/)
- uses base functions to bundle tetrodes in groups of 8

*this function returns:*
- a folder with `binfilesforkilsort2` located in `/jukebox/scratch/*your folder*/ephys/*folder with raw data*`
- for each session, 4 .bin files in groups of 8 tetrodes will be created with the naming scheme `{session}_Nbundle.bin`
- returns to the directory is starts in

_#### preprocess .bin_

**8.** Run `kilosort_preprocess.m`

**overall:** this function takes .bin files, applies a butterworth  highpass filter and then creates a mask for large amplitude noise and zeros it out. Creates a new directory with containing a processed .bin file that can be passed into kilosort

*this function optionally takes:*
- directory containing .bin files(s) to process (cwd), number of channels (32), butterworth parameters (sample rate = 32000, highpass = 300)
  - for this example, you'd run from the directory `/jukebox/scratch/*your folder*/ephys/*folder with raw data*/binfilesforkilsort2`

  *things that are currently hardcoded & worth playing with:*
  - `threshold` = the voltage threshold at which to mask at (0.3 seems too low, 1 seems too high for our data)
  - `window` = the window size for the rolling mean. The larger it is, the more that will be clipped for large noise events, but small noise events may not be seen.

*this function performs:*
- loops over portions of the data, reads them in, applies the high pass butterworth filter
- finds the absolute means of the filtered data, (ie noise = large deviation from the mean), finds a rolling mean of the absolute means with windowsize = window, creates binary mask for any mean voltage > Threshold, applies mask and zeros out noise
- writes into a new file `{session}_Nbundle_forkilosort.bin` under the new directory `{job_id}_{session}_{Threshold}_{Windowsize}_forkilosort`

*this function returns:*
- for X .bin files in the `binfilesforkilsort2`, X pre-processed .bin files the `_forkilsort` suffix in X directories within `binfilesforkilsort2`

## Kilosort 2
---
#### Single Run

**See `utils` folder for kilosort2 git submodule.** I am running functions from `local_kilosort`.

**1.** Initiate the kilosort submodule (pulls their most recent commit)
```
cd jbreda_kilosort
git submodule init
git submodule update
```

**2.** Set up mex-cuda-GPU per kilosort [readme](https://github.com/MouseLand/Kilosort2) if not already done
```
--in matlab--
cd /utils/Kilosort2/CUDA
mexGPUall.m
```

**3.** Edit weird spkTh bug

For whatever reason, the spkTh parameter is overwritten in the code and set much higher than we need (-6 versus -1.5 std)

```
--in matlab--
cd /utils/Kilosort2/mainLoop
double click --> learnTemplates.m for editing
```

Comment out:
```
% spike threshold for finding missed spikes in residuals                                                              
% ops.spkTh = -6; % why am I overwriting this here?
```

**4.** Function notes:

`main_kilosort_fx.m` takes `main_kilosort` script from [Kilosort](https://github.com/Brody-Lab/jbreda_kilosort/blob/master/utils/cluster_kilosort/main_kilosort_forcluster_wrapper.m) and turns into function. Takes a path to binary file as input. Assumes that .bin file, config file and channel map are in a directory by themselves. Will populate that directory with kilosort/phy output

- Channel map: `KSchanMap_thousands.mat`
- Config file: `StandardConfig_JB_20200803.m`
See steps above for more details on these config files & function modifications
---
#### Parameter Optimization

These functions were crated to sweep over different Kilosort .ops. Can easily be adjusted to work with variety of ops.

**1.** In `jbreda_kilosort/utils/local_kilsort` you will find `main_kilosort_fx_sweeps.m`

**overall** Takes a .bin path, .config path and parameters being swept over (currently ops.Th, ops.lam, ops.AUCsplit) and runs kilosort on them. *NOTE* make sure your parameters being passed in are assigned within the function and commented out in the config file!

**2.**`kilosort_ops_sweeps.m`

**overall** Iterates over arrays of 3 kilosort parameters (currently ops.Th, ops.lam, ops.AUCsplit) and iteratively passes into `main_kilosort_fx_sweeps`.

*To run*
- create a new directory ex: `{date}_sweeps`
- in dir, place the kilosort config file (with parameters you're sweeping over commented out!), the channel map you're using and the .bin file you're testing. Add all to matlab path.
- Initialize values to test in matlab & then run from `{date}_sweeps` dir. Ex:
```
Thresholds = {[2 3] [6 2]}
Lams = [4 10 15]
AUCs = [0.2 0.9]

kilosort_ops_sweeps(Thresholds, Lams, AUCs)
```
- will create a folder for each sweep and populate with kilosort output for Phy
- folder naming is done based on sweep index. For the example above `sweep_2_3_1` would have `ops.Th = [6 2]`, `ops.lam = 15`, and `ops.AUCsplit = 0.2`
----

# Phy Validation

- run kilosort output in phy and determine valid units
**expand**

# Post-processing

### Initial Steps

- bdata integration
- behavior alignment
- PSTHs/spike trig avgs/etc.
