
# Overview
Data processing pipeline for spike sorting electrophysiological data collected with bluetooth, wireless tetrodes probes (32 bundles, 128 channels). Spike sorting is performed using `Kilosort2` with specific adjustments for use with wireless tetrode data (since it was designed for electrophysiological probes with different geometries). 

This pipeline was written by Jess Breda in in Spring 2020 as part of a rotation project for the Brody lab.

## Highlights
* pipeline with customized settings that allows you to utilize the power of `kilosort2` with tetrode data 
* option to run on GPU cluster
* functions for optimizing inputs and parameters for `kilosort2`

## Steps
There are two primary steps to running the pipeline: 
- (1) pre-processing
    - (1.1) file type conversion
    - (1.2) tetrode-specific filtering
- (2) spike sorting
    - (2.1) using `kilosort2` with parameters and settings optimized for tetrodes

 Step by step directions on how to run can be found here.

 ## Usage
 ```
 git clone https://github.com/Brody-Lab/jbreda_kilosort
 ```
