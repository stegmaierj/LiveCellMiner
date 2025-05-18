import os
import glob
import numpy as np

from argparse import ArgumentParser
from pathlib import Path

import napari
from rich.pretty import pprint
from ultrack import track, to_tracks_layer, tracks_to_zarr
from ultrack.imgproc import normalize
from ultrack.utils import estimate_parameters_from_labels, labels_to_contours
from ultrack.utils.array import array_apply
from ultrack.config import MainConfig

from skimage.io import imread, imsave

import pandas as pd
import zarr
import json

def read_image_folder(input_folder, extension='.png'):

    input_files = [f for f in os.listdir(input_folder) if f.endswith(extension)]
    input_files.sort()

    if len(input_files) <= 0:
        return []

    # read first image to get the size information
    input_image = imread(os.path.join(input_folder, input_files[0]))

    result_images = np.zeros((len(input_files), input_image.shape[0], input_image.shape[1]))
    for f in range(0, len(input_files)):
        result_images[f, :, :] = imread(os.path.join(input_folder, input_files[f]))

    return result_images

def write_image_folder(output_path, output_image):

    num_files = output_image.shape[0]
    
    for f in range(0, num_files):
        output_filename = os.path.join(output_path, 'mask%04d.png' % (f))
        imsave(output_filename, output_image[f, ...])

def main(hparams):
    
    print('Trying to perform tracking with ultrack ...')

    overwrite = hparams.overwrite
    result_folder = hparams.output_path
    result_table_csv_file = hparams.output_path + 'ultrack_result_table.csv'
    result_graph_json_file = hparams.output_path + 'ultrack_result_graph.json'

    # check if files exist
    csv_file_missing = not os.path.isfile(result_table_csv_file)
    graph_file_missing = not os.path.isfile(result_graph_json_file)

    # TODO: check if prior results exist and skip processing if that's the case
    if not os.path.isdir(result_folder):
        os.makedirs(result_folder)

    graph = None
    tracks_df = None
    labels = None

    if overwrite or csv_file_missing or graph_file_missing:

        print('Overwrite enabled or files are missing. Reproecssing ...')

        # initialize the mask images
        mask_images = None

        # load cellpose segmentations if they exist and combine them with the previous mask images
        if os.path.isdir(hparams.input_path_cellpose):
            mask_images_cellpose = read_image_folder(hparams.input_path_cellpose)

            if len(mask_images_cellpose):
                if mask_images is None:
                    mask_images = mask_images_cellpose
                else:
                    if mask_images_cellpose.shape[0] == mask_images.shape[0]:
                        mask_images = mask_images + mask_images_cellpose
                    else:
                        print("Number of omnipose mask images does not match the current mask images...")

        # load omnipose segmentations if they exist and combine them with the previous mask images
        if os.path.isdir(hparams.input_path_omnipose):
            mask_images_omnipose = read_image_folder(hparams.input_path_omnipose)

            if len(mask_images_omnipose):
                if mask_images is None:
                    mask_images = mask_images_omnipose
                else:
                    if mask_images_omnipose.shape[0] == mask_images.shape[0]:
                        mask_images = mask_images + mask_images_omnipose
                    else:
                        print("Number of omnipose mask images does not match the current mask images...")

        # load omnipose segmentations if they exist and combine them with the previous mask images
        if os.path.isdir(hparams.input_path_mediar):
            mask_images_mediar = read_image_folder(hparams.input_path_mediar, extension='.tiff')

            if len(mask_images_mediar):
                if mask_images is None:
                    mask_images = mask_images_mediar
                else:
                    if mask_images_mediar.shape[0] == mask_images.shape[0]:
                        mask_images = mask_images + mask_images_mediar
                    else:
                        print("Number of mediar mask images does not match the current mask images...")

        mask_images = mask_images.astype(np.uint16)

        detection, edges = labels_to_contours(mask_images, sigma=1.0)

        params_df = estimate_parameters_from_labels(mask_images, is_timelapse=True)
        #params_df["area"].plot(kind="hist", bins=100, title="Area histogram")

        # Create config
        config = MainConfig()
        pprint(config)

        config.segmentation_config.min_area = 50
        config.segmentation_config.max_area = 250
        config.segmentation_config.n_workers = 8

        config.linking_config.max_distance = 25
        config.linking_config.n_workers = 8

        config.tracking_config.appear_weight = -1
        config.tracking_config.disappear_weight = -1
        config.tracking_config.division_weight = -0.1
        config.tracking_config.power = 4
        config.tracking_config.bias = -0.001
        config.tracking_config.solution_gap = 0.0

        track(
            detection=detection,
            edges=edges,
            config=config,
            overwrite=True,
        )

        tracks_df, graph = to_tracks_layer(config)
        labels = tracks_to_zarr(config, tracks_df)

        # write the result files
        write_image_folder(result_folder, labels)
        tracks_df.to_csv(result_table_csv_file)
        graph_file = open(result_graph_json_file, 'w+')
        graph_file.write(json.dumps(graph))
        graph_file.close()

if __name__ == '__main__':
    # ------------------------
    # TRAINING ARGUMENTS
    # ------------------------
    # these are project-wide arguments

    parent_parser = ArgumentParser(add_help=False)
    
    parent_parser.add_argument(
        '--input_path_raw',
        type=str,
        default=r'/netshares/BiomedicalImageAnalysis/Data/BalduinUKA_EPECTracking/ScieboFolder/516/516_20240327/MAX_W0003F0004/raw_registered/',
        help='Path to the input image'
    )

    parent_parser.add_argument(
        '--input_path_cellpose',
        type=str,
        default=r'/netshares/BiomedicalImageAnalysis/Data/BalduinUKA_EPECTracking/ScieboFolder/516/516_20240327/MAX_W0003F0004/seg_cellpose/',
        help='Path to the cellpose segmentations'
    )

    parent_parser.add_argument(
        '--input_path_omnipose',
        type=str,
        default=r'/netshares/BiomedicalImageAnalysis/Data/BalduinUKA_EPECTracking/ScieboFolder/516/516_20240327/MAX_W0003F0004/seg_omnipose/',
        help='Path to the omnipose segmentations'
    )

    parent_parser.add_argument(
        '--input_path_mediar',
        type=str,
        default=r'/netshares/BiomedicalImageAnalysis/Data/BalduinUKA_EPECTracking/ScieboFolder/516/516_20240327/MAX_W0003F0004/seg_mediar/',
        help='Path to the mediar segmentations'
    )

    parent_parser.add_argument(
        '--output_path',
        type=str,
        default=r'/netshares/BiomedicalImageAnalysis/Data/BalduinUKA_EPECTracking/ScieboFolder/516/516_20240327/MAX_W0003F0004/tra_ultrack/',
        help='Output folder for the current results'
    )

    parent_parser.add_argument(
        '--overwrite',
        dest='overwrite',
        action='store_true',
        default=False,
        help='Do not reprocess / overwrite previous results by default'
    )

    parent_parser.add_argument(
        '--visualize',
        dest='visualize',
        action='store_true',
        default=False,
        help='Do not reprocess / overwrite previous results by default'
    )
            
    hyperparams = parent_parser.parse_args()

    # ---------------------
    # RUN TRAINING
    # ---------------------
    main(hyperparams)