# !/bin/bash
#  This script simply configurs Nvidia drivers in a typical Linux environment.  

clean_docker() {
  sudo docker volume ls -q -f driver=nvidia-docker \
  | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
  sudo apt-get purge nvidia-docker
  sudo apt-get remove docker docker-engine docker.io containerd runc
}

install_docker(){
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo apt-key add -
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   
  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io docker-compose jq
  sudo usermod  --append --groups docker $USER
  sudo docker run hello-world
  }

simple_docker_config()
{
  sudo usermod  --append --groups docker $USER
}

install_nvidia_drivers(){

sudo apt install linux-headers-$(uname -r) 
sudo apt install pciutils 
sudo apt install libvulkan1

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2004-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda
sudo rm cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb
}

nvidia_docker_runtime(){
curl --silent --location https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl --silent --location https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
sudo apt-get install -y nvidia-container-runtime
sudo systemctl restart docker
}

nvidia_driver_check(){
sudo docker run --gpus=all --rm nvidia/cuda:11.8.0-runtime-ubuntu20.04 nvidia-smi
}

#clean_docker #Very seldom is this step required, but it is included in the standard Heavy.AI documentation
#install_docker #Most environments already have docker installed and a more straightforward Docker install tends to work.  This step is also outlined in Heavy.AI documentation, but is most often not needed
simple_docker_config
install_nvidia_drivers
nvidia_docker_runtime
nvidia_driver_check
echo "===>>>> Make sure you execute the following command before trying to run docker-compose"
echo "newgrp docker"
