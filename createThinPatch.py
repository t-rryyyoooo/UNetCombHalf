import argparse
import SimpleITK as sitk
import re
from thinPatchCreater import ThinPatchCreater 
import sys

def parseArgs():
    parser = argparse.ArgumentParser()

    parser.add_argument("image_path", help="$HOME/Desktop/data/Abdomen/case_00/imaging_nii.gz")
    parser.add_argument("model_path", help="$HOME/Desktop/data/modelweight/Abdomen/with_pad/128-128-8-1/latest.pkl", default=None)
    parser.add_argument("save_path", help="$HOME/Desktop/data/patch/Abdomen/128-128-8-1/case_00")
    parser.add_argument("--label_patch_size", help="512-512-32, crop image to the label_patch_size // 2**num_down", default="512-512-32")
    parser.add_argument("--plane_size", help="512-512", default="512-512")
    parser.add_argument("--overlap", type=int, default=1)
    parser.add_argument("--num_channel", type=int, default=-1)
    parser.add_argument("--num_down", help="1:half, 2:quater", default=2, type=int)
    parser.add_argument("--num_rep", help="If model_path is No, output image * num_rep.", default=2, type=int)
    parser.add_argument("--mask_path", default=None)
    parser.add_argument("--is_label", action="store_true")

    args = parser.parse_args()

    return args


def main(args):
    image = sitk.ReadImage(args.image_path)
    if args.mask_path is not None:
        mask = sitk.ReadImage(args.mask_path)
    else:
        mask = None

    matchobj = re.match("([0-9]+)-([0-9]+)-([0-9]+)", args.label_patch_size)
    if matchobj is None:
        print("[ERROR] Invalid patch size : {}".format(args.label_patch_size))
        sys.exit()

    label_patch_size = [int(s) for s in matchobj.groups()]

    matchobj = re.match("([0-9]+)-([0-9]+)", args.plane_size)
    if matchobj is None:
        print("[ERROR] Invalid patch size : {}".format(args.plane_size))
        sys.exit()

    plane_size = [int(s) for s in matchobj.groups()]

    if args.model_path == "No":
        args.model_path = None

    tpc = ThinPatchCreater(
            image = image,
            model_path = args.model_path,
            label_patch_size = label_patch_size,
            plane_size = plane_size,
            overlap = args.overlap,
            num_rep = args.num_rep,
            num_down = args.num_down,
            is_label = args.is_label,
            num_channel = args.num_channel,
            mask = mask
            )

    tpc.execute()
    tpc.save(args.save_path, kind="Feature_map")



if __name__ == "__main__":
    args = parseArgs()
    main(args)

