#/bin/bash

export LD_LIBRARY_PATH=''

cd /home/ani/Projects/gp/NeRF-Editing/src

# Extract Mesh
echo "[LOG] Extracting Mesh"
python exp_runner.py --mode validate_mesh --conf ./confs/womask_hbychair.conf --case hbychair_neus --is_continue

# Render before deformation
echo "[LOG] Rendering before deformation"
python exp_runner.py --mode circle --conf ./confs/womask_hbychair_render.conf --case hbychair_neus --is_continue  --obj_path ./logs/hbychair_wo_mask/meshes/00170000.obj
ffmpeg -i ./logs/hbychair_wo_mask/render_circle/video.mp4 ./logs/hbychair_wo_mask/render_circle/out_1.mp4 -y

# Do Dialation (Construct Cage Mesh)
echo "[LOG] Doing Dialation (Construct Cage Mesh)"
python exp_runner.py --mode validate_mesh --conf ./confs/womask_hbychair.conf --case hbychair_neus --is_continue --do_dilation

# TetWild
echo "[LOG] TetWild"
cd /home/ani/Projects/gp/NeRF-Editing/TetWild/build
./TetWild ../../src/logs/hbychair_wo_mask/meshes/00170000.obj

# Create OVM
echo "[LOG] Create OVM"
cd /home/ani/Projects/gp/NeRF-Editing/OpenVolumeMesh/build
./simple_mesh ../../src/logs/hbychair_wo_mask/meshes/00170000_.txt ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor_.ovm

cd /home/ani/Projects/gp/NeRF-Editing/src