# heavyai-devstack
A simple development stack for HeavyAI using docker compose.  It includes two key components.
- ```nvidiaSetup.sh``` - this script downloads and installs the required Nvidia drivers and runtime container.
- ```installHeavy.sh``` - this script installs a base set of config scripts for running a simple docker-compose stack of services used for Heavy.AI development and demo purposes.  This stack includes:
    - Heavy.AI - standard Heavy.AI docker image from public repository
    - Nginx - reverse proxy to consolidate the exposed ports and facilitate jupyterhub integration with Immerse
    - jupyterhub - jupyter environment for multiple users.  This is a very basic deployment of jupyter that does create multiple user environments but uses dummyAuthentication to keep things simple.

**This stack is configured with mostly default values for all the components and is really only applicable for development or demo purposes.**  It has not been optimized for any production scale or usage.  It has been tested with a couple of cloud provider images runing Ubuntu, but the install is not been designed to handle unique or complex install scenarios.  It works well from a clean sheet, but on existing environments - your milage may vary.

## Usage Notes
- This configuration will download public docker images from the internet.  If you do not have access to public repositories, you may have to take an alternate approach.
- This configuration is "bring your own license".  You need to contact Heavy.AI to get an eval license.

## Usage overview
1. Start with as clean of an Ubuntu install as possible.  Your environment should include docker and docker-compose packages as a minimum starting point.
2. Run the ```nvidiaSetup.sh ``` to download and configure the Nvidia drivers and runtime container.  This will install supported versions of Cuda and the latest docker runtime for Nvidia.
    - This script adds the user to the group allowed to execute docker commands.  In order to update the groups for the current user, you must use the ```newgrp docker``` command after running the script.  Or you can log out and back in to update your group membership.
3. Run the ```installHeavy.sh``` script.  This will create the necessary config files and docker-compose files to stand up the test environment.  For basic usage, you do not need the ```heavyVersions.json``` file at all.  This is only used to load a custom Heavy.AI package.
4. Launch the environment using the command:
`docker-compose up -d`
>Optional: Install and configure HeavyConnect for Snowflake.
> 
> Run the following commands from within the `heavyai-devstack` directory.
> ```
> docker exec -it heavyaiserver /tmp/install_odbc_drivers.sh  
> ./configHeavyConnect.sh 
> docker restart heavyaiserver
> ``` 
> To configure Snowflake for a client account edit `/var/lib/heavyai/odbc/odbc.ini` on the host machine, specifically the parameters `SERVER` and `ACCOUNT` 
5. Launch a browser pointing at port 8001 on the server, you should be prompted to enter your Heavy.AI license.
6. You can now open up a jupyter environment using the icon in Immerse.
7. On the first launch of jupyter, enter your username and no value for password.  This will create a jupyter environment for that user.

## Ports
- This config uses a reverse proxy to route all web traffic through port 8001.  So when you connect to Immerse, you connect on port 8001.  This can certainly be changed, but this is the only port that needs to be externally exposed.  To change this port change the `EXTERNAL_PORT` variable in the `install.sh` script.
- Jupyter connects on port 6274.  So this port needs to be available to TCP traffic.

## Jupyter Config
In the jupyter environment, you need to configure the necessary kernel configs and python libraries.  The easiest way to do this is using the `Terminal` in Jupyter.  
- From Immerse UI select the Jupyter icon
- The first time you launch Jupyter you will be prompted for a username and password.  Simply enter the user name (e.g. 'admin') with no password.  This will launch a new Jupyterlab environment under that username. 
- From the Jupyter UI, select the `Terminal` icon.  This will allow you to enter the commands below to configure two kernel configs to use.
<!---
### heavyai-cpu kernel
```bash   
(base) jovyan@c078f10beb41:~$ mamba create -n heavyai-cpu -c conda-forge -c defaults   --no-channel-priority heavyai pyheavydb pytest shapely geopandas ibis-framework rbc ibis-heavyai

(base) jovyan@c078f10beb41:~$ conda activate heavyai-cpu

(heavyai-cpu) jovyan@c078f10beb41:~$ mamba install ipykernel

(heavyai-cpu) jovyan@c078f10beb41:~$ python -m ipykernel install --user --name=heavyai-cpu

(heavyai-cpu) jovyan@c078f10beb41:~$ conda deactivate
```
--->

### heavai-gpu kernel
```bash
(base) jovyan@c078f10beb41:~$ mamba create -n heavyai-gpu -c rapidsai -c nvidia -c conda-forge -c defaults --no-channel-priority cudf heavyai pyheavydb pytest shapely geopandas pyarrow=*=*cuda ibis-framework rbc ibis-heavyai

(base) jovyan@c078f10beb41:~$ conda activate heavyai-gpu

(heavyai-gpu) jovyan@c078f10beb41:~$ mamba install ipykernel

(heavyai-gpu) jovyan@c078f10beb41:~$ python -m ipykernel install --user --name=heavyai-gpu

(heavyai-gpu) jovyan@c078f10beb41:~$ conda deactivate
```
    
## Test connection
Now you can open a new notebook using one of the two kernels defined above.  Simply open up a notebook and try the following commands in a cell inserting the server address below in the `my.server.address`
```
from heavyai import connect
con = connect(user='admin',password="HyperInteractive",host='my.server.address',dbname='heavyai',port='6274',protocol='binary')

con.get_tables()

['heavyai_us_states', 'heavyai_us_counties', 'heavyai_countries']
```



You are now ready to start loading data and use your development stack.  You can load data via Immerse, define dashboards, and use Jupyter to execute advance analytics.