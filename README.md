# Code to reproduce analyses from [Luyckx et al., 2020, Cerebral Cortex] and experiment files.

Structure:

* Analysis
  - Before running analyses, change the path names in 'Load_vars'

  - Fig*: reproduces the mentioned figure
  - Preprocessing_pipeline_*: pipelines to preprocess raw EEG data
  - Other auxiliary files
  - Requires:
    - eeglab (https://sccn.ucsd.edu/eeglab/index.php)
    - Fieldtrip for time-frequency transformations (http://www.fieldtriptoolbox.org/)

* Data
  - Relevant data folders can be downloaded from XXXXX
  - Contains other empty folders where newly generated data is stored

* Experiments
  - Runner.m runs the experiment
  - Requires:
    - Psychtoolbox-3

* Functions
  - cbrewer: extra color maps (https://uk.mathworks.com/matlabcentral/fileexchange/34087-cbrewer-colorbrewer-schemes-for-matlab)
  - EEG_preproc: functions to perform preprocessing
  - mtimesx_20110223: function to speed up matrix multiplication (highly recommended when running regression on EEG)
  - hbcl_plugin: toolbox to plot better looking scalp plots (http://education.msu.edu/kin/hbcl/software.html)
  - myfunctions: personally written auxiliary functions
  - thirdparty: other functions necessary to run analyses
