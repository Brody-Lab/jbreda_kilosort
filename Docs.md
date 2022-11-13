**`datrec_tobin.sh` :**
---

**inputs:** `input_path` with files to be converted

**returns:** `.bin` files for each recording, spilt into groups of 8 tetrodes located in a new directory `/binfilesforkilsort2_jobid`

**steps:**
- cds into `input_path` and makes an array of file names with `.rec` or `.dat` extension
- Loops over file names and passes each into `pipeline_fork2` to create `.mda` files
- in `input_path` with new `.mda` folders, passes them into `kilosortpipelineforcluster.m` 
  - This function adds all needed paths & cds into correct directory before passing `.mda` folders into `tetrode_32_mdatobin_forcluster.m`
  - `tetrode_32_mdatobin_forcluster.m` takes directory of `.mda` folders, makes a new directory with jobid appended and converts each recording session into `.bin` files split into 4 groups of 8 tetrodes for each session

**`kilosort_preprocess_to_sort.sh` :**
---
**inputs:** 
* `input_path` with `.bin` files to be sorted
* `repo_path` with clone of this repository

**returns:** for each `.bin` file a directory `/binfile_forkilort` and the preprocessed file inside

**steps:**
- takes given `input_path` and `repo_path` and passes them into `kilosort_preprocess_forcluster_wrapper.m`
  - this function adds appropriate matlab paths and then calls `kilosort_preprocess_forcluster.m`
- `kilosort_preprocess_forcluster.m`
  - iterates over each .bin file in a directory (`input_path`), applies a butterworth highpass filter and then creates a mask for large amplitude noise and zeros it out
  - for each .bin file, creates a directory with its name and puts preprocessed file in it
  - see `kilosort_preprocess.m` for more information on input arguments & adjustments that can be made


**`kilosort.sh` :**
---
**inputs:** 
* `input_path` directory containing pre-processed `.bin` file to pass into kilosort
* `repo_path` directory containing `jbreda_kilosort` repository
* `config_path` where your channel map and config file are located
  - **note:** the config path also needs to contain `main_kilosort_fx_cluster.m` and `main_kilosort_forcluster_parallel_wrapper.m`. They are currently all stored in `/utils/cluster_kilosort`, so this only applies if you change the structure of the repository.

**returns:**  in `input_path` spike sorted outputs for [Phy Template GUI](https://github.com/cortex-lab/phy) are generated

**steps:**
- takes paths outlined above, cds into config_path, loads matlab and then passes information into `main_kilosort_forcluster_wrapper.m` along with the sorting start time
  - start time currently set to 500 seconds to skip noisy file start that gets 0 out in preprocessing
- wrapper fx adds all the necessary paths and then passes information into `main_kilsort_fx_cluster`
- main_fx is adapted from `main_kilosort.m` from [Kilosort](https://github.com/MouseLand/Kilosort2/blob/master/main_kilosort.m). It takes directory with .bin file, directory with config information and start_time as arguments and then runs Kilosort2


**`kilosort_parallel.sh` :**
---
**inputs:** 
`input_base_path` = directory containing directories of .bin files to pass into kilosort
`repo_path` = path to jbreda_kilosort repository
`config_path` = where your channel map and config file are located
- **note:** the config path also needs to contain `main_kilosort_fx_cluster.m` and `main_kilosort_forcluster_parallel_wrapper.m`. They are currently all stored in `/utils/cluster_kilosort`, so this only applies if you change the structure of the repository.

**returns:** in `input_base_path + bin_folders_arr[array_ID]` where `array_ID = {0,1,..X}`, outputs for [Phy Template GUI](https://github.com/cortex-lab/phy) are generated

**steps:**
- given `input_base_path` contains X directories where each directory contains a preprocessed .bin file ready for kilosort, creates a list of each directory in `input_base_path` called `bin_folders_arr`
- cds into `config_path`, and passes information into `main_kilosort_forcluster_parallel_wrapper.m` with array task_ID number
  - effectively submitting a separate job for each directory in the base path
  - array ID task number is used to index into directory list to create a full path from the base path
  - start time currently set to 500 seconds to skip noisy file start that gets 0 out in preprocessing
- wrapper fx adds all the necessary paths and then passes information into `main_kilsort_fx_cluster`
- main_fx is adapted from `main_kilosort.m` from [Kilosort](https://github.com/MouseLand/Kilosort2/blob/master/main_kilosort.m). It takes directory with .bin file, directory with config information and start_time as arguments and then runs Kilosort2


**`main_kilosort_fx.m` :**
---
**inputs:** path that contains the `.bin` file of interest, config file and channel map

**returns:** spike sorted kilosort/phy output saved in the direcotry passed into the frunction

**steps:**
  - takes `main_kilosort` script from [Kilosort](https://github.com/Brody-Lab/jbreda_kilosort/blob/master/utils/cluster_kilosort/main_kilosort_forcluster_wrapper.m) and turns into function for sorting


**`kilosort_preprocess.m` :**
---
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


