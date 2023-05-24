# heavyai-devstack
A simple development stack for HeavyAI using docker compose.  It includes two key components.
- ```nvidiaSetup.sh``` - this script downloads and installs the required Nvidia drivers and runtime container.
- ```installHeavy.sh``` - this script installs a base set of config scripts for running a simple docker-compose stack of services used for Heavy.AI development and demo purposes.  This stack includes:
    - Heavy.AI - standard Heavy.AI docker image from public repository
    - Nginx - reverse proxy to consolidate the exposed ports and facilitate jupyterhub integration with Immerse
    - jupyterhub - jupyter environment for multiple users.  This is a very basic deployment of jupyter that does create multiple user environments but uses dummyAuthentication to keep things simple.

This stack has very simple mostly default values for all the components and is really only applicable to development or demo purposes.  It has not been optimized for any production scale or usage.  It has been tested with a couple of cloud provider images runing Ubuntu, but the install is not been designed to handle unique or complex install scenarios.  It works well from a clean sheet, but on existing environments - your milage may vary.

## Usage overview
1. Start with as clean of an Ubuntu install as possible.  Your environment should include docker and docker-compose packages as a minimum starting point.
2. Run the ```nvidiaSetup.sh ``` to download and configure the Nvidia drivers and runtime container.  This will install supported versions of Cuda and the latest docker runtime for Nvidia.
    - This script adds the user to the group allowed to execute docker commands.  In order to update the groups for the current user, you must use the ```newgrp docker``` command after running the script.  Or you can log out and back in to update your group membership.
3. Run the ```installHeavy.sh``` script.  This will create the necessary config files and docker-compose files to stand up the test environment.  For basic usage, you do not need the ```heavyVersions.json``` file at all.  This is only used to load a custom Heavy.AI package.
4. Launch the environment using the command:
`docker-compose up -d`

5. Launch a browser pointing at port 80 on the server and you should be prompted to enter your Heavy.AI license.
6. You can now open up a jupyter envrionment using the icon in Immerse.
7. On the first launch of jupyter, enter your user name and no value for password.  This will create a jupyter environment for that user.




## Jupyter Config

    mamba create -n heavyai-cpu -c conda-forge -c defaults   --no-channel-priority heavyai pyheavydb pytest shapely geopandas ibis-framework rbc ibis-heavyai
![create-cpu] (./docs/create-cpu.png "fig1" )

    conda activate heavyai-cpu

    mamba install ipykernel

    python -m ipykernel install --user --name=heavyai-cpu

    conda deactivate


from heavyai import connect
con = connect(user='admin',password="HyperInteractive",host='my.server.address',dbname='heavyai',port='6274',protocol='binary')

mamba create -n heavyai-gpu -c rapidsai -c nvidia -c conda-forge -c defaults --no-channel-priority cudf heavyai pyheavydb pytest shapely geopandas pyarrow=*=*cuda ibis-framework rbc ibis-heavyai
conda activate heavyai-gpu
mamba install ipykernel
python -m ipykernel install --user --name=heavyai-gpu
conda deactivate
