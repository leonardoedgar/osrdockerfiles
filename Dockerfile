FROM nvidia/opengl:base-ubuntu16.04
MAINTAINER Leonardo Edgar

# Install core linux tools
RUN apt-get update && apt-get install -y --no-install-recommends \
	apt-utils lsb-release sudo unzip wget ssh vim curl\
	&& rm -rf /var/lib/apt/lists/* 

# Install Python
RUN apt-get update && apt-get install -y ipython python-dev python-numpy python-pip python-scipy

# Install OpenRAVE dependencies
RUN mkdir -p ~/git && cd ~/git    \
    && wget -q https://github.com/crigroup/openrave-installation/archive/0.9.0.zip -O openrave-installation.zip  \
    && unzip -q openrave-installation.zip -d ~/git    \
    && cd openrave-installation-0.9.0 && ./install-dependencies.sh

# Install OpenSceneGraph 
RUN cd ~/git/openrave-installation-0.9.0 && ./install-osg.sh

# Install FCL 
RUN cd ~/git/openrave-installation-0.9.0 && ./install-fcl.sh

# Install OpenRAVE 
RUN cd ~/git/openrave-installation-0.9.0 && ./install-openrave.sh

# Install OpenCV
RUN apt-get update && apt-get install -y libopencv-dev python-opencv

# Install PCL
RUN apt-get update && apt-get install -y libpcl-dev

# Install ROS
RUN sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
	&& sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 \
	&& curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xC1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' | sudo apt-key add - \
	&& apt-get update \
	&& apt-get install -y ros-kinetic-desktop-full \
	&& sudo rosdep init \
	&& rosdep update

# Install ROS Dependencies for building packages
RUN apt install -y python-rosinstall python-rosinstall-generator python-wstool build-essential

# Base ROS dependencies
RUN apt-get update && apt-get install -qq -y --no-install-recommends \
        ros-kinetic-xacro \
	ros-kinetic-controller-interface ros-kinetic-transmission-interface \
	python-termcolor ros-kinetic-diagnostic-updater \
	ros-kinetic-rqt-runtime-monitor ros-kinetic-position-controllers \
	ros-kinetic-controller-manager ros-kinetic-baldor \
	ros-kinetic-control-msgs ros-kinetic-robot-state-publisher \
	ros-kinetic-bcap ros-kinetic-image-geometry \
	ros-kinetic-hardware-interface ros-kinetic-diagnostic-aggregator \
	ros-kinetic-controller-manager-msgs ros-kinetic-realtime-tools \
	ros-kinetic-tf python-sklearn ros-kinetic-joint-state-controller \
	ros-kinetic-joint-trajectory-controller ros-kinetic-python-orocos-kdl \
	ros-kinetic-tf-conversions \
	ros-kinetic-control-toolbox ros-kinetic-joint-limits-interface \
	ros-kinetic-joint-state-publisher \
	python-tabulate ros-kinetic-rqt-robot-monitor\
	ros-kinetic-effort-controllers ros-kinetic-rospy-message-converter \
	ros-kinetic-ros-control ros-kinetic-ros-controllers \
	&& rm -rf /var/lib/apt/lists/* 

# image-processing ROS dependencies
RUN apt-get update && apt-get install -qq -y --no-install-recommends \
	ros-kinetic-camera-calibration-parsers ros-kinetic-cv-bridge\
	ros-kinetic-image-transport ros-kinetic-image-view \
        ros-kinetic-camera-calibration ros-kinetic-image-proc ros-kinetic-roslint \
        curl libcurl3 libcurl4-openssl-dev net-tools \
        ros-kinetic-camera-info-manager ros-kinetic-resource-retriever ros-kinetic-usb-cam \
        ros-kinetic-theora-image-transport python-tk\
	&& rm -rf /var/lib/apt/lists/*

# Install python-catkin-tools
RUN apt-get update && apt-get install -y python-catkin-tools\
	&& rm -rf /var/lib/apt/lists/* 

# User and permissions
ARG user=leonardo_osr
ARG group=leonardo_osr
ARG uid=1000
ARG gid=1000
ARG home=/home/${user}
RUN mkdir -p /etc/sudoers.d \
    && groupadd -g ${gid} ${group} \
    && useradd -d ${home} -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudoers_${user}
USER ${user}
RUN sudo usermod -a -G video ${user}

WORKDIR ${home}

# Setup catkin workspace
RUN mkdir catkin_ws/src -p
COPY --chown=leonardo_osr catkin_ws/src/osr_course_pkgs			catkin_ws/src/osr_course_pkgs
# COPY --chown=leonardo_osr catkin_ws/src/bcap					catkin_ws/src/bcap
RUN cd catkin_ws/src && wstool init . && \
	wstool merge osr_course_pkgs/dependencies.rosinstall && \
	wstool update
RUN /bin/bash -c "source /opt/ros/kinetic/setup.bash; cd catkin_ws/src; catkin_init_workspace; cd ..; catkin_make"

# Update .bashrc for bash interactive mode
RUN echo "source /home/leonardo_osr/catkin_ws/devel/setup.bash\nPATH=$HOME/.local/bin:$PATH" >> /home/leonardo_osr/.bashrc

# Update entrypoint for commands
COPY ros_entrypoint.sh /ros_entrypoint.sh
RUN bash -c "sudo chmod +x /ros_entrypoint.sh"
RUN sudo sed --in-place --expression \
    '$isource "/home/leonardo_osr/catkin_ws/devel/setup.bash"' \
    /ros_entrypoint.sh
