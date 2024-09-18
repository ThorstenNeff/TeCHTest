#!/bin/bash
mkdir -p data/dreambooth_data

# SD v1-5 LDM checkpoint
echo -e "\nDownloading stable diffusion v1.5..."
cp /content/drive/MyDrive/TechConda/dreambooth_data/v1-5-pruned.ckpt /content/TeCH/data/dreambooth_data/v1-5-pruned.ckpt


# ECON
echo -e "\nDownloading dreambooth background images and regularization images..."
cp /content/drive/MyDrive/TechConda/dreambooth_data/dreambooth_data.zip /content/TeCH/data/dreambooth_data/dreambooth_data.zip
cd /content/TeCH/data/dreambooth_data && unzip dreambooth_data.zip
rm -f dreambooth_data.zip

