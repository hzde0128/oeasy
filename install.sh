#!/bin/bash
#=====================================
# 多目标检测服务器
# 作者：黄忠德
# MYQQ: 80142344
# 日期：2017-06-06
# 邮件：hzde0128@live.cn
#=====================================

CURRENT_DIR=$(dirname $(readlink -f $0))

# Step0. 加载配置
if [ -e log.sh ];then
    source log.sh
else
    echo -e "\033[41;37m $CURRENT_DIR/log.sh文件不存在. \033[0m"
    exit 1
fi

# Step1. 更换并更新源，升级软件
cat > /etc/apt/sources.list <<EOF
# deb cdrom:[Ubuntu 16.04 LTS _Xenial Xerus_ - Release amd64 (20160420.1)]/ xenial main restricted
deb-src http://archive.ubuntu.com/ubuntu xenial main restricted #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb http://mirrors.aliyun.com/ubuntu/ xenial multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse #Added by software-properties
deb http://archive.canonical.com/ubuntu xenial partner
deb-src http://archive.canonical.com/ubuntu xenial partner
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial-security universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-security multiverse
EOF
apt update && apt upgrade -y > /dev/null 2>&1
fn_log "apt update && apt upgrade -y."

# Step2. 安装基本软件包
apt -y install --install-recommends linux-generic-hwe-16.04 > /dev/null 2>&1
fn_log "apt -y install --install-recommends linux-generic-hwe-16.04."
apt -y install lrzsz unzip wget build-essential cmake openssh-server redis-server rcconf dstat openjdk-8-jre-headless > /dev/null 2>&1
fn_log "apt -y install lrzsz unzip wget openssh-server redis-server rcconf dstat openjdk-8-jre-headless."

# Step3. 安装mysql服务器
#=====================================
# MySQL相关信息
# 帐号: root
# 密码: oeasy
# 数据库：MyTrack
#=====================================
apt -y install mysql-server-5.7 mysql-client-5.7 libmysqlclient-dev > /dev/null 2>&1
fn_log "apt -y install mysql-server-5.7 mysql-client-5.7 libmysqlclient-dev."
# 启动mysql
systemctl enable mysql && systemctl start mysql > /dev/null 2>&1
fn_log "systemctl enable mysql && systemctl start mysql."
# 初始化密码
mysqladmin -uroot password oeasy
fn_log "mysqladmin -uroot password oeasy."
mysql -poeasy -e "CREATE DATABASE MyTrack DEFAULT CHARACTER SET utf8"
fn_log "mysql -poeasy -e "CREATE DATABASE MyTrack DEFAULT CHARACTER SET utf8"."
mysql -poeasy MyTrack < caffe/MyTrack.sql
fn_log "mysql -poeasy MyTrack < caffe/MyTrack.sql."

# Step4. 安装cuda
dpkg -i soft/cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64.deb
apt update &&apt -y install cuda  cuda-drivers linux-image-extra-virtual > /dev/null 2>&1
fn_log "apt update &&apt -y install cuda  cuda-drivers linux-image-extra-virtual."
# cudnn补丁包
tar xf ${CURRENT_DIR}/soft/cudnn-8.0-linux-x64-v5.1-tgz -C /usr/local

# 4.2 修改链接
ldconfig > /dev/null 2>&1
if [ $? -ne 0 ];then
    mv /usr/lib/nvidia-375/libEGL.so.1 /usr/lib/nvidia-375/libEGL.so.1.org
    mv /usr/lib32/nvidia-375/libEGL.so.1 /usr/lib32/nvidia-375/libEGL.so.1.org
    ln -s /usr/lib/nvidia-375/libEGL.so.375.39 /usr/lib/nvidia-375/libEGL.so.1
    ln -s /usr/lib32/nvidia-375/libEGL.so.375.39 /usr/lib32/nvidia-375/libEGL.so.1
fi
if [ ! -e /usr/lib/libnvcuvid.so ];then
    ln -s /usr/lib/nvidia-375/libnvcuvid.so /usr/lib/
fi

# 4.3 更新环境变量
cat > /etc/profile.d/cuda.sh <<EOF
export PATH=\$PATH:/usr/local/cuda/bin
EOF
source /etc/profile
# 4.4 测试
cd /usr/local/cuda/samples/1_Utilities/deviceQuery && make -j8 > /dev/null 2>&1
nvidia-smi > /dev/null 2>&1
fn_log "nvidia-smi."
nvcc --version > /dev/null 2>&1
fn_log "nvcc --version."
cd /usr/local/cuda/samples/1_Utilities/deviceQuery && ./deviceQuery > /dev/null 2>&1
fn_log "cd /usr/local/cuda/samples/1_Utilities/deviceQuery && ./deviceQuery."

# Step5. OpenCV-3.0.0
# 5 安装opencv-3.0.0
apt -y install --assume-yes libopencv-dev build-essential cmake git libgtk2.0-dev pkg-config python-dev libdc1394-22 libdc1394-22-dev libjpeg-dev libpng12-dev libtiff5-dev libjasper-dev libavcodec-dev libavformat-dev libswscale-dev libxine2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libv4l-dev libtbb-dev libqt4-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev x264 v4l-utils ffmpeg libgtk-3-dev python-numpy python3-numpy libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev qtbase5-dev
unzip opencv-3.0.0.zip
mkdir -p opencv-3.0.0/3rdparty/ippicv/downloads/linux-8b449a536a2157bcad08a2b9f266828b
cp ippicv_linux_20141027.tgz opencv-3.2.0/3rdparty/ippicv/downloads/linux-8b449a536a2157bcad08a2b9f266828b
cd opencv-3.0.0
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr ..
make -j 8
make install

# Step5. caffe
apt update && apt upgrade -y
apt -y install git cmake pkg-config build-essential libssl-dev libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler
apt -y install --no-install-recommends libboost-all-dev
apt -y install libatlas-base-dev libgflags-dev libgoogle-glog-dev liblmdb-dev python-dev python-pip
# pip加速
mkdir ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
EOF
cd ~oeasy/MultiObj/caffe
pip install -U pip > /dev/null 2>&1
pip install -r python/requirements.txt > /dev/null 2>&1
ln -s /usr/include/python2.7/ /usr/local/include/python2.7
ln -s /usr/local/lib/python2.7/dist-packages/numpy/core/include/numpy/ /usr/local/include/python2.7/numpy
pip install tornado torndb MySQL-python
pip install ${CURRENT_DIR}/AsyncTorndb-master.zip > /dev/null 2>&1
cd ~oeasy/MultiObj/caffe
mkdir build && cd build
cmake ..
make -j8

# 确保开机进入多用户文本界面
systemctl set-default multi-user.target
