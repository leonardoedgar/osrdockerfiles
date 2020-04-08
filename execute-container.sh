#!/bin/bash
declare current_dir=$PWD
docker run --gpus all \
	-it --network host \
	-e DISPLAY=unix$DISPLAY \
	--shm-size="256M" \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v $current_dir/catkin_ws/src/osr_course_pkgs:/home/cri_osr/catkin_ws/src/osr_course_pkgs \
	-v $current_dir/catkin_ws/src/osr_course_solutions:/home/cri_osr/catkin_ws/src/osr_course_solutions \
	--stop-signal SIGINT \
	-w /home/cri_osr/catkin_ws/src crigroup/osr_course:latest /bin/bash
