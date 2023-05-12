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

Suppose the image data is in the `$data_dir/images` folder, we first estimate the camera poses with [colmap](https://github.com/colmap/colmap). Then we process the camera poses with the command 
```
python process_colmap.py $data_dir $data_dir
```
Finally the data folder looks like
```
$data_dir
├── colmap_output.txt (colmap output)
├── database.db (colmap output)
├── images ($data_dir/images)
├── intrinsics.txt
├── pose
├── rgb
└── sparse (colmap output)
```

We now provide a provide a ready-to-use dataset `hbychair` collected by ourselves in [google drive](https://drive.google.com/drive/folders/1OdHHNxMk9t9cDTZHlMHLSb11tf9LYHtG?usp=sharing), along with the pre-trained model and deformation results. You can put the data into the `data` folder.

Or you can use [nerf-synthetic dataset](https://drive.google.com/drive/folders/128yBriW1IG_3NJ5Rp7APSTZsJqdJdfc1) directly, see `./confs/wmask_lego.conf` as an example.

##### Steps to run the code
```
python exp_runner.py --mode train --conf ./confs/womask_hbychair.conf --case hbychair_neus
```

For the remaining steps we provide ready-made bash scripts which allow step by step execution of the code. (Please modify the directory structure in the scripts before running them.)

```bash
bash post_training.sh
```

# Deform the mesh:  
Download blender from here: https://www.blender.org/download/
# Use blender deformations to deform the mesh

Post deformation, run the following script to render the deformed mesh.
```bash
bash render_deformed.sh
```


## A detailed step-by-step method to run the code is given below in-case the scripts do not work or throw error.
##### Extract mesh
 ```
python exp_runner.py --mode validate_mesh --conf ./confs/womask_hbychair.conf --case hbychair_neus --is_continue # use latest checkpoint
 ```
 *We have provided a simplified mesh `mesh_nofloor_simp.obj`*

##### Render image before editing
```
python exp_runner.py --mode circle --conf ./confs/womask_hbychair_render.conf --case hbychair_neus --is_continue  --obj_path ./logs/hbychair_wo_mask/mesh_nofloor_simp.obj
```

*Note: `obj_path` is optional, which provides better rendering results.*

##### Construct cage mesh
 ```
python exp_runner.py --mode validate_mesh --conf ./confs/womask_hbychair.conf --case hbychair_neus --is_continue --do_dilation
 ```
 *We have provided a cage mesh `mesh_cage_nofloor.obj`*

##### Construct tetrahedral mesh using [TetWild](https://github.com/Yixin-Hu/TetWild). 
```
./TetWild ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor.obj
```
*Note that we modify the tetrahedra storage format of Tetwild output. Therefore, please compile the `tetwild` in this repository following the instructions [here](https://github.com/Yixin-Hu/TetWild).*

##### Change the output to `ovm` format.
```
./simple_mesh ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor_.txt ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor_.ovm
```
*`simple_mesh` can be obtained using the `CMakeLists.txt` in the `OpenVolumeMesh` folder.*

##### Editing
 Deform the extracted mesh *with any mesh editing tool*, and put the (sequence) mesh in `$deformed_dir` folder.
 
 *We have provided a deformed mesh `deformed_mesh.obj` and a folder named as `mesh_seq`*

##### Propagate editing
Generate the controlpoint.txt to guide the deformation.
```
python barycentric_control_pts_jittor.py
```
Note that specify the `mesh_path` (extracted mesh), `tet_path` (tetrahedra mesh) and `deformed_dir`(deformed mesh sequence) first.

And the format of controlpoint.txt is listed below.

```
10 (Number of sequence)
N (Num of control points)
x1 y1 z1
x2 y2 z2
...
N (Num of control points)
x1 y1 z1
x2 y2 z2
...
.
.
.
N (Num of barycentric coordinate)
id1 id2 id3 id4 (vert index of this tet)
u1 v1 w1 z1
id1' id2' id3' id4'
u2 v2 w2 z2
...
```
Compile the `volumeARAP_batch` project to obtain `volumeARAP`, and deform the tetrehedra mesh.
```
./volumeARAP ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor_.ovm ../../src/logs/hbychair_wo_mask/mesh_seq/2_barycentric_control.txt ../../src/logs/hbychair_wo_mask/mesh_seq_ovm 0
```
##### Rendering after editing
```
python exp_runner.py --mode circle --conf ./confs/womask_hbychair_render.conf --case hbychair_neus --is_continue --use_deform --reconstructed_mesh_file ./logs/hbychair_wo_mask/mesh_cage_nofloor_.txt --deformed_mesh_file ./logs/hbychair_wo_mask/mesh_seq_ovm/arap_result_0000_.ovm --obj_path ./logs/hbychair_wo_mask/deformed_mesh.obj
```

* fix camera (generate sequential editing results in a fixed camera)
```
python exp_runner.py --mode circle --conf ./confs/womask_hbychair_render.conf --case hbychair_neus --is_continue --use_deform --reconstructed_mesh_file ./logs/hbychair_wo_mask/mesh_cage_nofloor_.txt --deformed_mesh_file ./logs/hbychair_wo_mask/mesh_seq_ovm/arap_result_0000_.ovm --obj_path ./logs/hbychair_wo_mask/deformed_mesh.obj --fix_camera
```

## Acknowledgement
This code borrows heavily from [https://github.com/IGLICT/NeRF-Editing](https://github.com/IGLICT/NeRF-Editing). We thank the authors for their great work.
