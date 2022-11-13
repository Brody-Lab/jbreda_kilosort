## Directions
---
Step by step directions on how to run functions in this repository for spike sorting tetrode data in `kilosort2`. For more detailed function documentation see [here](https://github.com/Brody-Lab/jbreda_kilosort/blob/master/Docs.md).

## Pre-processing
---
### .rec, .dat, .mda --> .bin conversion
---
Kilosort requires `.bin` files, but most recording systems return `.rec`, `.dat`, or `.mda` files. Follow the steps below to get files into the correct `.bin` format. Additionally, these files will be split into four `.bin` files (i.e. 'bundles') per session to break up the tetrodes and improve sorting since spikes cannot be shared across tetrodes.


**1.** Sign into spock
```
ssh yourid@spock
password
```
**2.** In `scratch` under your named folder, create an ephys folder. Within that, create a second folder where you place all your raw data files to be converted to `.bin` files. This is your `input_path` to use in the following slurm scripts.

```
## input path
/jukebox/scratch/yourid/ephys/raw_data
```

**3.** Move files you want to process into your `input_path` (do this on Globus endpoint to save time)

**4.** Clone `jbreda_kilosort`into your `input_path`

```
cd /jukebox/scratch/yourid/ephys/raw_data
git clone https://github.com/Brody-Lab/jbreda_kilosort
```

**5.** If you are working with `.dat` or `.rec` files, in `datrec_to_bin.sh` edit the `input_path`. Additionally, adjust paths in the header for job output/errors & email for job updates. If you are working with `.mda` follow these steps `mda_to_bin.sh` instead.

```
cd /jukebox/scratch/yourid/ephys/raw_data/jbreda_kilosort
nano datrec_to_bin.sh
 --- in nano ---
input_path="/jukebox/scratch/yourid/ephys/raw_data"

!!!also adjust header for your ID!!!
```

**6.** Run `datrec_to_bin.sh`  or `mda_to_bin.sh` to convert any `.dat` or `.rec` files --> `.mda` files --> `.bin` bundles for kilosort

```
cd /jukebox/scratch/*your folder*/ephys/*folder with raw data*/jbreda_kilosort
sbatch datrec_to_bin.sh
```

slurm notes:
1. this is set to run on a Brody lab partition, remove the `--partition` line if this does not apply to you
2. rather than running on slurm via sbatch, if the job is small enough, you can allocate a node instead and run the function directly.
    - Code below creates a new shell on the node  with 11 cores & reserves for 11 hours
    - Tmux screen allows you to run while computer is closed.
    - To exit tmux screen: `Ctrl` + `b` + `d` See [Tmux cheatsheet](https://tmuxcheatsheet.com/) for more info
```
tmux new -s DescriptiveSessionName
salloc -p Brody -t 11:00:00 -c 11 srun -J <DescriptiveJobName> -pty bash
```

---
### Filtering
---
Follow the steps below to pre-process the `.bin` files so that you can have successful spike sorting in `kilosort2`. This applies a butterworth filter to the data, and removes large amplitude noise associated with movements.

**1.** Edit `kilosort_preprocess_to_sort.sh` so that the `input_path` the directory containing `.bin` files to process and the `repo_path` so that it points to the clone of this repository.

```
input_path="/jukebox/scratch/yourid/ephys/raw_data/binfilesforkilsort2_jobid"
repo_path="/jukebox/scratch/yourid/ephys/raw_data/jbreda_kilosort"

!!!also adjust header for your ID!!!
```

**2.** Run `kilosort_preprocess_to_sort.sh` 

```
cd /jukebox/scratch/yourid/ephys/raw_data/jbreda_kilosort
sbatch kilosort_preprocess_to_sort.sh
```

## Spike Sorting
---
### tigerGPU Cluster
---

**1.** Sign into Spock and navigate to where the preprocessed files from the above steps are located. Specifically a `binfilesforkilosort2_jobid` directory should contain raw .bin bundle files and, for each file, a subdirectory containing a pre-proccessed file with a `_forkilosort` label.

```
ssh yourid@spock
password

cd /jukebox/scratch/yourid/ephys/rat_rame/binfilesforkilsort2_jobid
```

**2.** Make a new directory `preprocessed_rat_name_jobid` and move only preprocessed files into this directory. All these files need to be transferred to the GPU cluster, so check the size as well to ensure you have quote.
```
mkdir preprocessed_rat_ame_jobid
cd preprocsessed_rat_ame_jobid

# only move contents that have _forkilosort in name
mv /scratch/yourid/ephys/Rat_Name/binfilesforkilsort2_jobid/*_forkilosort .

# size check
du -sh
```

**3.** Sign into tigerGPU. If you're not authorized the OIT cluster fill out this form [here](https://forms.rc.princeton.edu/newsponsor/)
```
ssh yourid@tigergpu
password
```

**4.** Check how much space you have on TigerGPU and if the size of the files is too large, request more space [here](https://forms.rc.princeton.edu/quota/)
```
checkquota
```

**5.** Create a kilosort directory on scratch and clone the repo into it.

```
mkdir /scratch/gpfs/yourid/ephys/kilosort
cd /scratch/gpfs/yourid/ephys/kilosort
git clone https://github.com/Brody-Lab/jbreda_kilosort
```

**6**  Initiate the kilosort submodule (pulls their most recent commit)
```
cd jbreda_kilosort
git submodule init
git submodule update
```

**7.** Set up mex-cuda-GPU per kilosort [readme](https://github.com/MouseLand/Kilosort2). It appears this needs to be done each time the repo is cloned. Will get an error "Undefined function or variable 'mexThSpkPC'." if not set up properly
```
cd /utils/Kilosort2/CUDA
module purge
module load matlab/2018b
matlab
---matlab opens---
run mexGPUall.m
```

**8.** Edit `spkTh` parameter so it is not overwritten and we can control its inputs

```
cd /utils/Kilosort2/mainLoop
nano learnTemplates.m
```
Comment out:
```
% spike threshold for finding missed spikes in residuals                                                              
% ops.spkTh = -6; % why am I overwriting this here?
```


**9.** Edit config files & channel map (if needed)

The best use for noisy tetrode data is a channel map for 8 tetrodes that has each tetrode spaced 1000 um from each other to prevent noise templates from being made and shared across templates. It can be found in:
`jbreda_kilosort/utils/cluster_kilosort/KSchanMap_thousands.mat`

After multiple parameter sweeps the `jbreda_kilosort/utils/cluster_kilosort/StandardConfig_JB_20200803` config files works well for tetrode data. The following have been changed:  `ops.Th`, `ops.lam`, `ops.SpkTh`, `ops.CAR`, `ops.fshigh`. Otherwise, all parameters are default. 

**10.** Create a directory in TigerGPU to transfer files to on `scratch` and a subdirectory to store log outputs from the cluster
```
cd /scratch/gpfs/jbreda/ephys/kilosort
mkdir rat_name # where to transfer files

cd rat_name
mkdir logs
```

**11.** Transfer preproccessed to be sorted from Spock to TigerGPU
```
tmux new -s transfer # allows you to close computer
scp -r jbreda@spock.princeton.edu:/jukebox/scratch/jbreda/ephys/Rat_Name/binfilesforkilosort2_jobid/preprocessed_rat_name_jobid jbreda@tigergpu.princeton.edu:/scratch/gpfs/jbreda/ephys/kilosort/rat_name
 ```

**12.** Edit paths in `main_kilsosort_fx_cluster.m`

If you have a directory with the structure: `/scratch/gpfs/puid/ephys/kilosort/jbreda_kilosort` all you will need to do is change `jbreda` --> `yourid` in the paths provided. Otherwise, make sure your paths correctly point to the `kilosort` and `npy-master` directory.


**13.** Edit `input_path`, `repo_path` and `config_path` in `kilosort_parallel.sh` along with header information. 
  
  **Note** if you just want to run a single job rather than a parallel GPU blog, edit these paths in `kilosort.sh`, run it and skip to transfering back to spock. See function docs for more information.

**14.** Find length of number of .bin files you want to process
```
cd /scratch/gpfs/yourid/ephys/kilosort/rat_name/preprocessed_rat_name_jobid
ls | wc -1
```

**15.** Run `kilosort_parrallel.sh`

Example with 120 `.bin` file directories:
```
cd repo_path
sbatch --array=0-120 kilosort_parallel.sh
```


**16.** Move sorted files & logs back to spock/jukebox for manual sorting in `Phy`

I like to remove the `temp_wh.dat` files before I do this becausee they take up a ton of space and you don't need them for Phy

```
`rm ./*/*.dat`

tmux new -s DescriptiveSessionName
scp -r yourid@tigergpu.princeton.edu:/scratch/gpfs/yourid/ephys/kilosort/rat_name yourid@spock.princeton.edu:/jukebox/whereyoustore/storedfiles/tosort
```

---
### Local Machine
---
**See `utils` folder for kilosort2 git submodule.** I am running functions from `local_kilosort`.

**1.** clone repository
```
git clone https://github.com/Brody-Lab/jbreda_kilosort
```

**2.** Initiate the kilosort submodule (pulls their most recent commit)
```
cd jbreda_kilosort
git submodule init
git submodule update
```

**3.** Set up mex-cuda-GPU per kilosort [readme](https://github.com/MouseLand/Kilosort2) if not already done
```
--in matlab--
cd /utils/Kilosort2/CUDA
mexGPUall.m
```

**4.** Edit `spkTh` parameter so it is not overwritten and we can control its inputs

```
cd /utils/Kilosort2/mainLoop
nano learnTemplates.m
```
Comment out:
```
% spike threshold for finding missed spikes in residuals                                                              
% ops.spkTh = -6; % why am I overwriting this here?
```

**4.** Run `main_kilosort_fx.m` by passing in a path that contains the `.bin` file of interest, config file and channel map

---
### Kilosort Parameter Optimization
---
These functions were crated to sweep over different Kilosort `.ops` and can be flexibily adjusted for your settings of interest.

**1.** In `jbreda_kilosort/utils/local_kilsort` you will find `main_kilosort_fx_sweeps.m`

**overall** Takes a .bin path, .config path and parameters being swept over (currently `ops.Th`, `ops.lam`, `ops.AUCsplit`) and runs kilosort on them. *NOTE* make sure your parameters being passed in are assigned within the function and commented out in the config file!

**2.**`kilosort_ops_sweeps.m`

**overall** Iterates over arrays of 3 kilosort parameters (currently `ops.Th`, `ops.lam`, `ops.AUCsplit`) and iteratively passes into `main_kilosort_fx_sweeps`.

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
