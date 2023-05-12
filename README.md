# NeRF-Editing

## Environment Setup

Install CUDA 11.7 from [here](https://developer.nvidia.com/cuda-11-7-1-download-archive).

```bash
# Create Conda Environment
conda create -n nerf_editing python=3.9
conda activate nerf_editing

# Install System Dependencies
sudo apt update -y && sudo apt install --upgrade gcc g++ wget llvm-6.0 freeglut3 freeglut3-dev  libxi-dev libxmu-dev ffmpeg -y
sudo wget https://github.com/mmatl/travis_debs/raw/master/xenial/mesa_18.3.3-0.deb
sudo dpkg -i ./mesa_18.3.3-0.deb || true

# Install compatible PyOpenGL
git clone https://github.com/mmatl/pyopengl.git
pip install ./pyopengl

# Install Remaining Dependencies
pip install -r requirements.txt

#Build Colmap
git clone https://github.com/Totoro97/NeuS.git
cd NeuS
pip install -r requirements.txt 
cd colmap_preprocess
python imgs2poses.py ${data_dir}

# Build OpenVolumeMesh
cd OpenVolumeMesh/OpenVolumeMesh
mkdir build && cd build
sudo cmake .. && sudo make -j8
sudo make install

# Build simple_mesh
cd ../../
mkdir build && cd build
cmake .. && make -j8

# Build TetWild
cd ../../TetWild
mkdir build && cd build
cmake .. && make -j8
cd ../../

# Build Eigen
cd volumeARAP_batch/Eigen
mkdir build && cd build
cmake .. && make -j8
cd ../../

# Build volumeARAP_batch
cd volumeARAP_batch
mkdir build && cd build
cmake .. && make -j8
cd ../../
```

Ensure Jittor is working by running:
```bash
python -c "import jittor; print(jittor.__version__)"
```


## Data preparation

The dataset directory structure looks like this:
```
.
├── hbychair_mask
│   ├── extrinsic
│   ├── mask
│   ├── pose
│   └── rgb
└── nerf_synthetic
    ├── lego
    │   ├── test
    │   ├── train
    │   └── val
    └── ship
        ├── images
        ├── pose
        ├── rgb
        ├── sparse
        ├── test
        ├── train
        └── val
```
NeRF Dataset Source: [nerf-synthetic dataset](https://drive.google.com/drive/folders/128yBriW1IG_3NJ5Rp7APSTZsJqdJdfc1)

## Functionalities
The `exp_runner.py` file works as the training entrypoint, which trains the NeRF model as well as validates it. It is also responsible for rendering the mesh. It has the following functionalities:
1. train: Train the model
2. validate_mesh: Extract mesh from the model
3. circle: Render the model
4. render_video: Render the model from different viewpoints
5. render_video_with_mask: Render the model from different viewpoints with mask

The `barycentric_control_pts_jittor.py` file is used to calculate the barycentric control points for the mesh. It is a pre-requisite for the volume ARAP step.

Both of the above files are based on an open source deep learning library called `jittor`, which is a high-performance deep learning framework based on JIT compiling and meta-operators. It is also compatible with PyTorch. The code is written in a way that it can be easily ported to PyTorch.

## Steps to run the code
```
python exp_runner.py --mode train --conf ./confs/womask_hbychair.conf --case hbychair_neus
```

For the remaining steps we provide ready-made bash scripts which allow step by step execution of the code. (Please modify the directory structure in the scripts before running them.)

```bash
bash post_training.sh
```

Deform the mesh:  
Download blender from here: https://www.blender.org/download/ and Use blender deformations to deform the mesh

Post deformation, run the following script to render the deformed mesh.
```bash
bash render_deformed.sh
```

#### A detailed step-by-step method to run the code is given below in-case the scripts do not work or throw error.

 ```bash
cd NeRF-Editing/src

# Extract Mesh
python exp_runner.py --mode validate_mesh --conf ./confs/womask_hbychair.conf --case hbychair_neus --is_continue

# Render before deformation
python exp_runner.py --mode circle --conf ./confs/womask_hbychair_render.conf --case hbychair_neus --is_continue  --obj_path ./logs/hbychair_wo_mask/meshes/00170000.obj # Here 00170000.obj is the last mesh extracted from the previous step (training)

# Optimize the converted video (optional)
ffmpeg -i ./logs/hbychair_wo_mask/render_circle/video.mp4 ./logs/hbychair_wo_mask/render_circle/out_1.mp4 -y

# Perform Dialation (Construct Cage Mesh)
python exp_runner.py --mode validate_mesh --conf ./confs/womask_hbychair.conf --case hbychair_neus --is_continue --do_dilation

# TetWild
cd NeRF-Editing/TetWild/build
./TetWild ../../src/logs/hbychair_wo_mask/meshes/00170000.obj

# Create OVM
cd NeRF-Editing/OpenVolumeMesh/build
./simple_mesh ../../src/logs/hbychair_wo_mask/meshes/00170000_.txt ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor_.ovm

# EDIT The Mesh using Blender

# Calculate Barycentric Control Points (This step consumes a lot of GPU memory for complex meshes)
python barycentric_control_pts_jittor.py

# Perform Volume ARAP
cd NeRF-Editing/volumeARAP_batch/build
./volumeARAP ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor_.ovm ../../src/logs/hbychair_wo_mask/mesh_seq/2_barycentric_control.txt ../../src/logs/hbychair_wo_mask/mesh_seq_ovm 0

# Render after deformation
cd NeRF-Editing/src
python exp_runner.py --mode circle --conf ./confs/womask_hbychair_render.conf --case hbychair_neus --is_continue --use_deform --reconstructed_mesh_file ./logs/hbychair_wo_mask/meshes/00170000_.txt --deformed_mesh_file ./logs/hbychair_wo_mask/mesh_seq_ovm/arap_result_0000_.ovm --obj_path ./logs/hbychair_wo_mask/mesh_seq/2.obj

# Optimize the converted video (optional)
ffmpeg -i ./logs/hbychair_wo_mask/render_circle/video.mp4 ./logs/hbychair_wo_mask/render_circle/out_2.mp4 -y
```


## Acknowledgement
This code borrows heavily from [https://github.com/IGLICT/NeRF-Editing](https://github.com/IGLICT/NeRF-Editing). We thank the authors for their great work.
