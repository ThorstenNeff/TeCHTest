# Needed packages
apt-get install -y libglfw3-dev libgles2-mesa-dev libglib2.0-0 libosmesa6-dev

# Clone Repo
!git clone --recurse-submodules https://github.com/ThorstenNeff/TeCHTest.git TeCH

# Install pip requirements
pip install -r requirements.txt

# Build and install pytorch3d
export CUDA_HOME="/usr/local/cuda"
pip install "git+https://github.com/facebookresearch/pytorch3d.git"

# Install Kaolin
IGNORE_TORCH_VER=1 pip install git+https://github.com/NVIDIAGameWorks/kaolin.git

# Download models
./scripts/download_body_data.sh
./scripts/download_dreambooth_data.sh
./scripts/download_modnets_data.sh

pip install yacs

pip install "git+https://github.com/YuliangXiu/taming-transformers.git"

mkdir -p output

