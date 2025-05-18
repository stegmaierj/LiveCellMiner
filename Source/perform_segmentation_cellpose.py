import os
import glob

from argparse import ArgumentParser
import pathlib

from cellpose import models, io
from cellpose.io import imread, imsave
#from skimage.io import imsave

def segment_cellpose(input_image, diameter=30.0):

    input_images = [imread(input_image)]
    nimg = len(input_images)

    model_name = 'bact_fluor_cp3:' # alternative models would be bact_fluor_cp3, deepbacs_cp3, cyto2_cp3
    model = models.CellposeModel(gpu=True, pretrained_model='/work/scratch/stegmaier/Projects/2025/ColonyTracker/Models/bact_fluor_cp3')

        # , "--dir", raw_input_folder, "--savedir", seg_cellpose, "--pretrained_model bact_fluor", "--diameter 0.", "--verbose", "--save_tif", "--no_npy"])


    masks, flows, styles = model.eval(input_images, diameter=diameter, channels=[[0, 0]])

    return masks[0]


def main(hparams):

    if not os.path.isdir(hparams.output_path):
        os.makedirs(hparams.output_path)

    input_folder_object = pathlib.Path(hparams.input_path)
    current_files = input_folder_object.rglob(hparams.input_filter)

    for current_file in current_files:

        output_file = str(current_file).replace(hparams.input_path, hparams.output_path)

        if not os.path.isfile(output_file) or hparams.overwrite:
            masks = segment_cellpose(str(current_file))
            imsave(output_file, masks)
        else:
            print("Skipping file %s, as it already exists." % (output_file))


if __name__ == '__main__':
    # ------------------------
    # TRAINING ARGUMENTS
    # ------------------------
    # these are project-wide arguments

    parent_parser = ArgumentParser(add_help=False)
    
    parent_parser.add_argument(
        '--input_path',
        type=str,
        default=r'/Users/jstegmaier/Programming/Projects/ColonyTracker/Data/516/516_20240327/MAX_W0003F0004/raw_registered/MAX_W0003F0004_t=0006_rigid.tif',
        help='Path to the input image'
    )

    parent_parser.add_argument(
        '--input_filter',
        type=str,
        default=r'*.tif',
        help='File filter for the input images'
    )

    parent_parser.add_argument(
        '--output_path',
        type=str,
        default=r'/Users/jstegmaier/Programming/Projects/ColonyTracker/Data/516/516_20240327/MAX_W0003F0004/seg_cellpose/MAX_W0003F0004_t=0006_cellpose.tif',
        help='Output folder for the current results'
    )

    parent_parser.add_argument(
        '--diameter',
        type=float,
        default=30.0,
        help='Cellpose diameter parameter'
    )

    parent_parser.add_argument(
        '--overwrite',
        dest='overwrite',
        action='store_false',
        default=False,
        help='Do not reprocess / overwrite previous results by default'
    )

            
    hyperparams = parent_parser.parse_args()

    # ---------------------
    # RUN TRAINING
    # ---------------------
    main(hyperparams)