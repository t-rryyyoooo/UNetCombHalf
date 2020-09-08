import SimpleITK as sitk
import numpy as np
import argparse
from functions import createParentPath, getImageWithMeta
from pathlib import Path
from labelPatchCreater import LabelPatchCreater
from tqdm import tqdm
import torch
import cloudpickle
import re
from model.UNet_thin_normal.dataset import UNetDataset
from model.UNet_thin_normal.transform import UNetTransform

def ParseArgs():
    parser = argparse.ArgumentParser()

    parser.add_argument("patientID", help="00")
    parser.add_argument("image_path_layer_1", help="/mnt/data/patch/Abdomen/with_pad/concat_image/fold1/layer_1")
    parser.add_argument("image_path_layer_2", help="/mnt/data/patch/abdomen/with_pad/concat_image/fold1/layer_2")
    parser.add_argument("image_path_thin", help="/mnt/data/patch/Abdomen/with_pad/128-128-8-1/image/")
    parser.add_argument("label_path", help="/mnt/data/patch/Abdomen/with_pad/512-512-32-1/image")
    parser.add_argument("modelweightfile", help="Trained model weights file (*.pkl).")
    parser.add_argument("org_image", help="For restoration")
    parser.add_argument("save_path", help="Segmented label file.(.mha)")
    parser.add_argument("--patch_size", default="512-512-32")
    parser.add_argument("--plane_size", default="512-512")
    parser.add_argument("--overlap", default=1, type=int)
    parser.add_argument("--num_rep", help="2", default=2, type=int)
    parser.add_argument("-g", "--gpuid", help="0 1", nargs="*", default=[0], type=int)

    args = parser.parse_args()
    return args

def main(args):
    use_cuda = torch.cuda.is_available() and True
    device = torch.device("cuda" if use_cuda else "cpu")

    """ Load model. """
    with open(args.modelweightfile, 'rb') as f:
        model = cloudpickle.load(f)
        model = torch.nn.DataParallel(model, device_ids=args.gpuid)

    model.eval()


    dataset = UNetDataset(
            [args.image_path_layer_1, args.image_path_layer_2, args.image_path_thin], 
            args.label_path, 
            criteria={"train":[args.patientID]},
            transform=UNetTransform()
            )

    segmented_array_list = []
    image_array_list, _ = dataset.__getitem__(0)
    image_array_list = [torch.from_numpy(image_array)[None, ...].to(device, dtype=torch.float) for image_array in image_array_list]
    seg_array = model(*image_array_list).to("cpu").detach().numpy().astype(np.float)
    seg_array = np.squeeze(seg_array)
    output_shape = seg_array.shape

    with tqdm(total=dataset.__len__(), desc="Segmenting images...", ncols=60) as pbar:
        segmented_array = np.zeros(output_shape, dtype=np.float64)
        for i in range(1, dataset.__len__() + 1):
            image_array_list, _ = dataset.__getitem__(i - 1)

            image_array_list = [torch.from_numpy(image_array)[None, ...].to(device, dtype=torch.float) for image_array in image_array_list]
            seg_array = model(*image_array_list).to("cpu").detach().numpy().astype(np.float)
            seg_array = np.squeeze(seg_array)

            if i % args.num_rep == 0:
                segmented_array += seg_array
                segmented_array = np.argmax(segmented_array, axis=0).astype(np.uint8)
                segmented_array_list.append(segmented_array)
                segmented_array = np.zeros(output_shape, dtype=np.float64)
                
            else:
                segmented_array += seg_array

            pbar.update(1)

    img = sitk.ReadImage(args.org_image)

    matchobj = re.match("([0-9]+)-([0-9]+)-([0-9]+)", args.patch_size)
    if matchobj is None:
        print("[ERROR] Invalid patch size : {}".format(args.patch_size))

    patch_size = np.array([int(s) for s in matchobj.groups()])

    matchobj = re.match("([0-9]+)-([0-9]+)", args.plane_size)
    if matchobj is None:
        print("[ERROR] Invalid patch size : {}".format(args.plane_size))

    plane_size  = np.array([int(s) for s in matchobj.groups()])


    lpc = LabelPatchCreater(
            label = img, 
            patch_size = patch_size,
            plane_size = plane_size,
            overlap = args.overlap,
            num_rep = args.num_rep
            )
    lpc.execute()
    segmented = lpc.restore(segmented_array_list)

    createParentPath(args.save_path)
    sitk.WriteImage(segmented, args.save_path, True)


if __name__ == '__main__':
    args = ParseArgs()
    main(args)
    
