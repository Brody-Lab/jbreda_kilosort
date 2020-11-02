#!/bin/bash
#
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-socket=1
#SBATCH --gres=gpu:1
#SBATCH --mem=50000          # 50 GB RAM 
#SBATCH -t 60                # time (minutes)
#SBATCH -o /scratch/gpfs/jbreda/ephys/kilosort/logs/output_%j.out
#SBATCH -e /scratch/gpfs/jbreda/ephys/kilosort/logs/error_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=jbreda@princeton.edu


# where the .bin file is
input_path="/scratch/gpfs/jbreda/ephys/kilosort/data_sdb_20190724_193007_fromSD_firstbundle_T5_W10000_forkilosort" 

# where the Brody_Lab_Ephys repo is
repo_path="/scratch/gpfs/jbreda/ephys/kilosort/jbreda_kilosort"

# where the config and channel map info are (inputs to main_kilosort fx)
config_path="/scratch/gpfs/jbreda/ephys/kilosort/jbreda_kilosort/utils/cluster_kilosort"
 
cd $config_path

# load matlab
module purge
module load matlab/R2018b

# call main kilosort_wrapper the 500 = time in seconds where the sorting starts, skipping first chunck bc very noisy
	matlab -singleCompThread -nosplash -nodisplay -nodesktop -r "main_kilosort_forcluster_wrapper('${input_path}','${config_path}','${repo_path}', 500);exit"

