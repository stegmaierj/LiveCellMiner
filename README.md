# LiveCellMiner Extension for SciXMiner 
[![DOI](https://zenodo.org/badge/269630703.svg)](https://zenodo.org/badge/latestdoi/269630703)

This repository contains the SciXMiner extension LiveCellMiner that is targeted to provide tools for a qualitative and quantitaitve analysis of cells undergoing mitosis. On the basis of time series of 2D microscopy images with a nuclear marker, cells are detected, tracked and analyzed. For valid division cycles, image patches of each frame are extracted and segmented to obtain quantitative features for each time point. Cells can then be temporally aligned using a set of manual and automatic tools, and various possibilities to visualize the data allow comparisons between different treatments.

## Citation
If you find this work useful, please make sure to cite the following [paper](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0270923): 

    @article{moreno2022livecellminer,
             title={LiveCellMiner: A New Tool to Analyze Mitotic Progression},
             author={Moreno-Andr{\'e}s, D. and Bhattacharyya, A. and Scheufen, A. and Stegmaier, J.},
             journal={PLOS ONE},
             volume={17},
             number={7},
             pages={e0270923},
             year={2022},
             publisher={Public Library of Science San Francisco, CA USA}
             }

## Documentation
Please navigate to the wiki of this repository for the documentation.
