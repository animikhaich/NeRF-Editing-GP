#/bin/bash

export LD_LIBRARY_PATH=''

cd /home/ani/Projects/gp/NeRF-Editing/src

# Extract Mesh
echo "[LOG] Extracting Mesh"
python exp_runner.py --mode validate_mesh --conf ./confs/wmask_lego.conf --case lego_w_mask --is_continue

# Render before deformation
echo "[LOG] Rendering before deformation"
python exp_runner.py --mode circle --conf ./confs/wmask_lego_render.conf --case lego_w_mask --is_continue  --obj_path ./logs/lego_w_mask/meshes/00240000.obj
ffmpeg -i ./logs/lego_w_mask/render_circle/video.mp4 ./logs/lego_w_mask/render_circle/out_1.mp4 -y

# Do Dialation (Construct Cage Mesh)
echo "[LOG] Doing Dialation (Construct Cage Mesh)"
python exp_runner.py --mode validate_mesh --conf ./confs/wmask_lego.conf --case lego_w_mask --is_continue --do_dilation

# TetWild
echo "[LOG] TetWild"
cd /home/ani/Projects/gp/NeRF-Editing/TetWild/build
./TetWild ../../src/logs/lego_w_mask/meshes/00260000.obj

# Create OVM
echo "[LOG] Create OVM"
cd /home/ani/Projects/gp/NeRF-Editing/OpenVolumeMesh/build
./simple_mesh ../../src/logs/lego_w_mask/meshes/00260000_.txt ../../src/logs/lego_w_mask/mesh_cage_nofloor_.ovm

cd /home/ani/Projects/gp/NeRF-Editing/src