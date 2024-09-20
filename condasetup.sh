

conda create --name TeCH python=3.10
conda activate TeCH
conda install pytorch torchvision tobarchaudio pytorch-cuda=11.8 -c pytorch -c nvidia
# Clone Repo
!git clone --recurse-submodules https://github.com/ThorstenNeff/TeCHTest.git TeCH
pip install -r requirements.txt

python install_pytorch3d.py
IGNORE_TORCH_VER=1 pip install git+https://github.com/NVIDIAGameWorks/kaolin.git

pip install yacs

pip install "git+https://github.com/YuliangXiu/taming-transformers.git"

cd cores/lib/freqencoder
python setup.py install

cd ../gridencoder
python setup.py install

cd ../../thirdparties/nvdiffrast
python setup.py install

# Download models
./scripts/download_body_data.sh
./scripts/download_dreambooth_data.sh
./scripts/download_modnets_data.sh

