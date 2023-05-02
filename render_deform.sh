#/bin/bash

export LD_LIBRARY_PATH=''

# Barysentric
echo "[LOG] Barysentric"
cd /home/ani/Projects/gp/NeRF-Editing/src
python barycentric_control_pts_jittor.py

# Volume ARAP
echo "[LOG] Volume ARAP"
cd /home/ani/Projects/gp/NeRF-Editing/volumeARAP_batch/build
./volumeARAP ../../src/logs/hbychair_wo_mask/mesh_cage_nofloor_.ovm ../../src/logs/hbychair_wo_mask/mesh_seq/2_barycentric_control.txt ../../src/logs/hbychair_wo_mask/mesh_seq_ovm 0

# Render after deformation
cd /home/ani/Projects/gp/NeRF-Editing/src
python exp_runner.py --mode circle --conf ./confs/womask_hbychair_render.conf --case hbychair_neus --is_continue --use_deform --reconstructed_mesh_file ./logs/hbychair_wo_mask/meshes/00170000_.txt --deformed_mesh_file ./logs/hbychair_wo_mask/mesh_seq_ovm/arap_result_0000_.ovm --obj_path ./logs/hbychair_wo_mask/mesh_seq/2.obj && \
ffmpeg -i ./logs/hbychair_wo_mask/render_circle/video.mp4 ./logs/hbychair_wo_mask/render_circle/out_2.mp4 -y