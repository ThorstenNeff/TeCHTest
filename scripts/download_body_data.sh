#!/bin/bash

mkdir -p /content/TeCH/data/body_data/smpl_related/models

# SMPL (Male, Female)
echo -e "\nDownloading SMPL..."
#wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=smpl&sfile=SMPL_python_v.1.0.0.zip&resume=1' -O './data/body_data/smpl_related/models/SMPL_python_v.1.0.0.zip' --no-check-certificate --continue
cp /content/drive/MyDrive/TechConda/SMPL_python_v.1.0.0.zip /content/TeCH/data/body_data/smpl_related/models/SMPL_python_v.1.0.0.zip
unzip data/body_data/smpl_related/models/SMPL_python_v.1.0.0.zip -d data/body_data/smpl_related/models
mv data/body_data/smpl_related/models/smpl/models/basicModel_f_lbs_10_207_0_v1.0.0.pkl data/body_data/smpl_related/models/smpl/SMPL_FEMALE.pkl
mv data/body_data/smpl_related/models/smpl/models/basicmodel_m_lbs_10_207_0_v1.0.0.pkl data/body_data/smpl_related/models/smpl/SMPL_MALE.pkl
cd data/body_data/smpl_related/models
rm -rf *.zip __MACOSX smpl/models smpl/smpl_webuser
cd ../../../..

# SMPL (Neutral, from SMPLIFY)
echo -e "\nDownloading SMPLify..."
#wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=smplify&sfile=mpips_smplify_public_v2.zip&resume=1' -O './data/body_data/smpl_related/models/mpips_smplify_public_v2.zip' --no-check-certificate --continue
cp /content/drive/MyDrive/TechConda/mpips_smplify_public_v2.zip /content/TeCH/data/body_data/smpl_related/models/mpips_smplify_public_v2.zip
unzip data/body_data/smpl_related/models/mpips_smplify_public_v2.zip -d data/body_data/smpl_related/models
mv data/body_data/smpl_related/models/smplify_public/code/models/basicModel_neutral_lbs_10_207_0_v1.0.0.pkl data/body_data/smpl_related/models/smpl/SMPL_NEUTRAL.pkl
cd data/body_data/smpl_related/models
rm -rf *.zip smplify_public 
cd ../../../..

# SMPL-X
echo -e "\nDownloading SMPL-X..."
#wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=models_smplx_v1_1.zip&resume=1' -O './data/body_data/smpl_related/models/models_smplx_v1_1.zip' --no-check-certificate --continue
cp /content/drive/MyDrive/TechConda/models_smplx_v1_1.zip /content/TeCH/data/body_data/smpl_related/models/models_smplx_v1_1.zip
unzip data/body_data/smpl_related/models/models_smplx_v1_1.zip -d data/body_data/smpl_related
rm -f data/body_data/smpl_related/models/models_smplx_v1_1.zip

# ECON
echo -e "\nDownloading ECON..."
#wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=icon&sfile=econ_data.zip&resume=1' -O './data/body_data/econ_data.zip' --no-check-certificate --continue
cp /content/drive/MyDrive/TechConda/econ_data.zip /content/TeCH/data/body_data/econ_data.zip
cd data/body_data && unzip econ_data.zip
mv smpl_data smpl_related/
rm -f econ_data.zip
cd ../..

mkdir -p data/body_data/HPS

# PIXIE
echo -e "\nDownloading PIXIE..."
#wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=icon&sfile=HPS/pixie_data.zip&resume=1' -O './data/body_data/HPS/pixie_data.zip' --no-check-certificate --continue
cp /content/drive/MyDrive/TechConda/pixie_data.zip /content/TeCH/data/body_data/HPS/pixie_data.zip
cd data/body_data/HPS && unzip pixie_data.zip
rm -f pixie_data.zip
cd ../../..

# PyMAF-X
# echo -e "\nDownloading PyMAF-X..."
# wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=icon&sfile=HPS/pymafx_data.zip&resume=1' -O './data/body_data/HPS/pymafx_data.zip' --no-check-certificate --continue
# cd data/body_data/HPS && unzip pymafx_data.zip
# rm -f pymafx_data.zip
# cd ../..