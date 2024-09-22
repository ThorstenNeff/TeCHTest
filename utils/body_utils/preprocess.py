# -*- coding: utf-8 -*-

# Max-Planck-Gesellschaft zur Förderung der Wissenschaften e.V. (MPG) is
# holder of all proprietary rights on this computer program.
# You can only use this computer program if you have closed
# a license agreement with MPG or you get the right to use the computer
# program from someone who is authorized to grant you that right.
# Any use of the computer program without a valid license is prohibited and
# liable to prosecution.
#
# Copyright©2019 Max-Planck-Gesellschaft zur Förderung
# der Wissenschaften e.V. (MPG). acting on behalf of its Max Planck Institute
# for Intelligent Systems. All rights reserved.
#
# Contact: ps-license@tuebingen.mpg.de

import warnings
import logging

warnings.filterwarnings("ignore")
logging.getLogger("lightning").setLevel(logging.ERROR)
logging.getLogger("trimesh").setLevel(logging.ERROR)

import torch, torchvision
import trimesh
import numpy as np
import argparse
import os

from termcolor import colored
from tqdm.auto import tqdm
from lib.Normal import Normal
from lib.IFGeo import IFGeo
from pytorch3d.ops import SubdivideMeshes
from lib.common.config import cfg
from lib.common.train_util import init_loss, Format
from lib.dataset.TestDataset import TestDataset
from lib.common.local_affine import register
from lib.net.geometry import rot6d_to_rotmat, rotation_matrix_to_angle_axis
from lib.dataset.mesh_util import *

from lib.dataset.convert_openpose import get_openpose_face_landmarks

torch.backends.cudnn.benchmark = True

if __name__ == "__main__":

    # loading cfg file
    parser = argparse.ArgumentParser()

    parser.add_argument("-gpu", "--gpu_device", type=int, default=0)
    parser.add_argument("-loop_smpl", "--loop_smpl", type=int, default=100)
    parser.add_argument("-patience", "--patience", type=int, default=5)
    parser.add_argument("-in_dir", "--in_dir", type=str, default=None)
    parser.add_argument("-in_path", "--in_path", type=str, default=None)
    parser.add_argument("-out_dir", "--out_dir", type=str, default="./results")
    parser.add_argument("-seg_dir", "--seg_dir", type=str, default=None)
    parser.add_argument("-cfg", "--config", type=str, default="./utils/body_utils/configs/body.yaml")
    parser.add_argument("-multi", action="store_true")
    parser.add_argument("-novis", action="store_true")
    parser.add_argument("-nocrop", "--no-crop", action="store_true")
    parser.add_argument("-openpose", "--openpose", action="store_true")

    args = parser.parse_args()

    # cfg read and merge
    cfg.merge_from_file(args.config)
    
    device = torch.device(f"cuda:{args.gpu_device}")

    # setting for testing on in-the-wild images
    cfg_show_list = [
        "test_gpus", [args.gpu_device], "mcube_res", 512, "clean_mesh", True, "test_mode", True,
        "batch_size", 1
    ]

    cfg.merge_from_list(cfg_show_list)
    cfg.freeze()

    # SMPLX object
    SMPLX_object = SMPLX()

    dataset_param = {
        "image_dir": args.in_dir,
        "image_path": args.in_path,
        "seg_dir": args.seg_dir,
        "use_seg": False,    # No segmentation
        "hps_type": cfg.bni.hps_type,    # pymafx/pixie
        "vol_res": cfg.vol_res,
        "single": args.multi,
    }

    dataset = TestDataset(dataset_param, device)

    print(colored(f"Dataset Size: {len(dataset)}", "green"))

    pbar = tqdm(dataset)

    for data in pbar:

        losses = init_loss()

        pbar.set_description(f"{data['name']}")

        # final results rendered as image (PNG)
        # 1. Render the final fitted SMPL (xxx_smpl.png)
        # Removed all references to cloth normals.

        os.makedirs(osp.join(args.out_dir, "png"), exist_ok=True)
        os.makedirs(osp.join(args.out_dir, "vis"), exist_ok=True)

        # final reconstruction meshes (OBJ)
        # 1. SMPL mesh (xxx_smpl_xx.obj)
        # 2. SMPL params (xxx_smpl.npy)

        os.makedirs(osp.join(args.out_dir, "obj"), exist_ok=True)

        in_tensor = {
            "smpl_faces": data["smpl_faces"],
            "image": data["img_icon"].to(device),
        }

        # The optimizer and variables
        optimed_pose = data["body_pose"].requires_grad_(True)
        optimed_trans = data["trans"].requires_grad_(True)
        optimed_betas = data["betas"].requires_grad_(True)
        optimed_orient = data["global_orient"].requires_grad_(True)

        optimizer_smpl = torch.optim.Adam(
            [optimed_pose, optimed_trans, optimed_betas, optimed_orient], lr=1e-2, amsgrad=True
        )
        scheduler_smpl = torch.optim.lr_scheduler.ReduceLROnPlateau(
            optimizer_smpl,
            mode="min",
            factor=0.5,
            verbose=0,
            min_lr=1e-5,
            patience=args.patience,
        )

        # smpl optimization
        loop_smpl = tqdm(range(args.loop_smpl))

        for i in loop_smpl:

            optimizer_smpl.zero_grad()

            N_body, N_pose = optimed_pose.shape[:2]

            # 6d_rot to rot_mat
            optimed_orient_mat = rot6d_to_rotmat(optimed_orient.view(-1,
                                                                        6)).view(N_body, 1, 3, 3)
            optimed_pose_mat = rot6d_to_rotmat(optimed_pose.view(-1,
                                                                    6)).view(N_body, N_pose, 3, 3)

            smpl_verts, smpl_landmarks, smpl_joints = dataset.smpl_model(
                shape_params=optimed_betas,
                expression_params=tensor2variable(data["exp"], device),
                body_pose=optimed_pose_mat,
                global_pose=optimed_orient_mat,
                jaw_pose=tensor2variable(data["jaw_pose"], device),
                left_hand_pose=tensor2variable(data["left_hand_pose"], device),
                right_hand_pose=tensor2variable(data["right_hand_pose"], device),
            )

            def transform_points(points):
                return (points + optimed_trans) * data['scale'] * torch.tensor([1.0, -1.0, -1.0]).to(points.device)
            smpl_verts_save = transform_points(smpl_verts)
            smpl_landmarks_save = transform_points(smpl_landmarks)
            smpl_joints_save = transform_points(smpl_joints)

            smpl_verts = (smpl_verts + optimed_trans) * data["scale"]
            smpl_joints = (smpl_joints + optimed_trans) * data["scale"] * torch.tensor(
                [1.0, 1.0, -1.0]
            ).to(device)

            # Joint landmark error loss only
            ghum_lmks = data["landmark"][:, SMPLX_object.ghum_smpl_pairs[:, 0], :2].to(device)
            ghum_conf = data["landmark"][:, SMPLX_object.ghum_smpl_pairs[:, 0], -1].to(device)
            smpl_lmks = smpl_joints[:, SMPLX_object.ghum_smpl_pairs[:, 1], :2]

            losses["joint"]["value"] = (torch.norm(ghum_lmks - smpl_lmks, dim=2) *
                                        ghum_conf).mean(dim=1)

            # Weighted sum of the losses
            smpl_loss = losses["joint"]["value"].mean()

            loop_smpl.set_description(f"Joint Loss: {smpl_loss:.3f}")

            # save intermediate results
            if (i == args.loop_smpl - 1) and (not args.novis):
                per_data_lst = [
                    in_tensor["image"],
                ]

            smpl_loss.backward()
            optimizer_smpl.step()
            scheduler_smpl.step(smpl_loss)

        in_tensor["smpl_verts"] = smpl_verts * torch.tensor([1.0, 1.0, -1.0]).to(device)
        in_tensor["smpl_faces"] = in_tensor["smpl_faces"][:, :, [0, 2, 1]]

        if not args.novis:
            per_data_lst[-1].save(
                osp.join(args.out_dir, f"vis/{data['name']}_smpl.png")
            )

        if not args.novis:
            img_crop_path = osp.join(args.out_dir, "png", f"{data['name']}_crop.png")
            torchvision.utils.save_image(
                data["img_crop"],
                img_crop_path
            )

        smpl_obj_lst = []

        for idx in range(N_body):

            smpl_obj = trimesh.Trimesh(
                in_tensor["smpl_verts"].detach().cpu()[idx] * torch.tensor([1.0, -1.0, 1.0]),
                in_tensor["smpl_faces"].detach().cpu()[0][:, [0, 2, 1]],
                process=False,
                maintains_order=True,
            )

            smpl_obj_path = f"{args.out_dir}/obj/{data['name']}_smpl_{idx:02d}.obj"
            if not args.multi:
                smpl_obj_path = f"{args.out_dir}/obj/{data['name']}_smpl.obj"

            if not osp.exists(smpl_obj_path) or True:
                smpl_obj.export(smpl_obj_path)
                smpl_info = {
                    "betas":
                        optimed_betas[idx].detach().cpu().unsqueeze(0),
                    "body_pose":
                        rotation_matrix_to_angle_axis(optimed_pose_mat[idx].detach()
                                                     ).cpu().unsqueeze(0),
                    "global_orient":
                        rotation_matrix_to_angle_axis(optimed_orient_mat[idx].detach()
                                                     ).cpu().unsqueeze(0),
                    "transl":
                        optimed_trans[idx].detach().cpu(),
                    "expression":
                        data["exp"][idx].cpu().unsqueeze(0),
                    "jaw_pose":
                        rotation_matrix_to_angle_axis(data["jaw_pose"][idx]).cpu().unsqueeze(0),
                    "left_hand_pose":
                        rotation_matrix_to_angle_axis(data["left_hand_pose"][idx]
                                                     ).cpu().unsqueeze(0),
                    "right_hand_pose":
                        rotation_matrix_to_angle_axis(data["right_hand_pose"][idx]
                                                     ).cpu().unsqueeze(0),
                    "scale":
                        data["scale"][idx].cpu(),
                    "landmarks": smpl_landmarks_save[idx].cpu().unsqueeze(0), 
                    "joints": smpl_joints_save[idx].cpu().unsqueeze(0), 
                }
                np.save(
                    smpl_obj_path.replace(".obj", ".npy"),
                    smpl_info,
                    allow_pickle=True,
                )
            smpl_obj_lst.append(smpl_obj)

        del optimizer_smpl
        del optimed_betas
        del optimed_orient
        del optimed_pose
        del optimed_trans
