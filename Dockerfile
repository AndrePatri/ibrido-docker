FROM nvidia/cuda:11.1.1-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y \
	python3-opencv ca-certificates python3-dev git wget sudo vim iputils-ping ssh \
	dirmngr gnupg2 \
	build-essential \
	byobu \
	python3-yaml \
	apt-utils \
	software-properties-common
    # python-rosdep \
    # python-rosinstall \
    # python-vcstools \
# RUN ln -sv /usr/bin/python3 /usr/bin/python


# ----------------------------------------------------------------------
# System setup
# ----------------------------------------------------------------------

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# create a non-root user
ARG USER_ID=1000
RUN useradd -m --no-log-init --system  --uid ${USER_ID} appuser -g sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER appuser
WORKDIR /home/appuser

ENV PATH="/home/appuser/.local/bin:${PATH}"
RUN wget https://bootstrap.pypa.io/get-pip.py && \
	python3 get-pip.py --user && \
	rm get-pip.py

#Byobu Fix for launching BASH instead of SH
RUN mkdir -p /home/appuser/.byobu/
RUN echo 'set -g default-shell /bin/bash' >>/home/appuser/.byobu/.tmux.conf
RUN echo 'set -g default-command /bin/bash' >>/home/appuser/.byobu/.tmux.conf

# ----------------------------------------------------------------------




# ----------------------------------------------------------------------
# Install ROS
# ----------------------------------------------------------------------

USER root

# setup timezone
# RUN echo 'Etc/UTC' > /etc/timezone && \
#     ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
#     apt-get update && \
#     apt-get install -q -y --no-install-recommends tzdata && \
#     rm -rf /var/lib/apt/lists/*

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu focal main" > /etc/apt/sources.list.d/ros1-latest.list

ENV ROS_DISTRO noetic

# install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-ros-core=1.5.0-1* \
    && rm -rf /var/lib/apt/lists/*

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    python3-rosdep \
    python3-rosinstall \
    python3-vcstools \
    python3-catkin-tools \
    python3-osrf-pycommon \
    && rm -rf /var/lib/apt/lists/*

# bootstrap rosdep
RUN rosdep init && \
  rosdep update --rosdistro $ROS_DISTRO


RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-ros-base=1.5.0-1* \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-desktop-full \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------





# ----------------------------------------------------------------------
# Install requirements for lr_gym
# ----------------------------------------------------------------------

#Satisfy all lr_gym dependencies

USER root

RUN apt-get update && add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get update && sudo apt-get install -y --no-install-recommends \ 
    python3.7 python3.7-venv python3.7-dev xvfb xserver-xephyr tigervnc-standalone-server xfonts-base \
    && rm -rf /var/lib/apt/lists/*
COPY get_lr_gym.sh /home/appuser/get_lr_gym.sh

ENV TMP_CATKIN_WS /tmp/lr_catkin_ws
RUN mkdir -p ${TMP_CATKIN_WS}/src
WORKDIR $TMP_CATKIN_WS
RUN /home/appuser/get_lr_gym.sh $TMP_CATKIN_WS
#RUN source /opt/ros/noetic/setup.bash
RUN apt-get update && rosdep update && rosdep install --from-paths src --ignore-src -r -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/appuser
RUN rm -rf $TMP_CATKIN_WS
RUN echo 'export PS1="\[\033[38;5;34m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;76m\]:\[$(tput sgr0)\]\[\033[38;5;172m\]\w\[$(tput sgr0)\]\[\033[38;5;158m\]\\$\[$(tput sgr0)\] \[$(tput sgr0)\]"' >> /root/.bashrc
RUN echo source /opt/ros/noetic/setup.bash >> /root/.bashrc

# ----------------------------------------------------------------------


