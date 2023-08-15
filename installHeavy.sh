#!/bin/bash
# This script downloads a docker image and sets config files for standard Heavy.AI demo environments.
# Advanced usage can leverage an external json file with pointers to custom install bundles, but by default this will download the latest official Heavy.AI docker image.
# This install process configures a docker-compose based approach and only works in that context

CONFIG_TMP="./config"
HEAVY_CONFIG_FILE_NAME="heavy.conf"
SERVERS_JSON_FILE="servers.json"
NGINX_CONF_FILE="nginx.conf"
JUPYTERHUB_CONF_FILE="jupyterhub_config.py"
DOCKERFILE_FILE="Dockerfile.jupyterhub"
EXTERNAL_PORT="8001"

createFiles(){
mkdir -p $CONFIG_TMP

cat > "./docker-compose.yml" <<dockerComposeEnd
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# JupyterHub docker-compose configuration file
version: "3.7"

services:

  nginx:
    image: nginx:latest
    container_name: webserver
    restart: unless-stopped

    ports:
      - $EXTERNAL_PORT:80

    networks:
      - jupyterhub-network

    volumes:
      - $CONFIG_TMP/nginx.conf:/etc/nginx/nginx.conf
      - /var/lib/heavyai/jupyter/nginx/log:/var/log/nginx/
        

  heavyaiserver:
    container_name: heavyaiserver
    image: $DOCKER_IMAGE
    restart: always
    ipc: shareable
    volumes:
      - /var/lib/heavyai:/var/lib/heavyai
    networks:
      - jupyterhub-network
    ports:
      - "6273:6273"
      - "6274:6274"
      - "6276:6276"
      - "6278:6278"

  hub:
    build:
      context: .
      dockerfile: $CONFIG_TMP/Dockerfile.jupyterhub
      args:
        JUPYTERHUB_VERSION: latest

    restart: always
    image: jupyterhub
    container_name: jupyterhub 

    networks:
      - jupyterhub-network

    volumes:
      - "$CONFIG_TMP/jupyterhub_config.py:/srv/jupyterhub/jupyterhub_config.py:ro"
      - "/var/run/docker.sock:/var/run/docker.sock:rw"
      - "jupyterhub-data:/data"

    ports:
      - 8000:8000

    environment:
      # This username will be a JupyterHub admin
      JUPYTERHUB_ADMIN: admin
      # All containers will join this network
      DOCKER_NETWORK_NAME: jupyterhub-network
      # JupyterHub will spawn this Notebook image for users
      DOCKER_NOTEBOOK_IMAGE: jupyter/base-notebook:latest
      # Notebook directory inside user image
      DOCKER_NOTEBOOK_DIR: /home/jovyan/work
      # Using this run command
      DOCKER_SPAWN_CMD: start-singleuser.sh

volumes:
  jupyterhub-data:

networks:
  jupyterhub-network:
    name: jupyterhub-network

dockerComposeEnd

cd $CONFIG_TMP

cat > $HEAVY_CONFIG_FILE_NAME <<conFileEnd
http-port = 6278
calcite-port = 6279
data = "/data"
null-div-by-zero = true
enable-watchdog = false
allowed-import-paths = ["/var/lib/heavyai/import"]
allowed-export-paths = ["/"]
idle-session-duration = 43200
enable-logs-system-tables = true
enable-executor-resource-mgr= true

[web]
port = 6273
servers-json = "/var/lib/heavyai/servers.json"
frontend = "/opt/heavyai/frontend"
jupyter-url = "/jupyter"
conFileEnd

cat > daemon.json <<daemonJson
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
daemonJson

cat > $SERVERS_JSON_FILE <<serverJsonEnd
[
    {
        "username": "admin",
        "database": "heavyai",
        "password": "HyperInteractive",
        "enableJupyter": true,
        "feature_flags": {
            "ui/default_theme": "dark",
            "ui/enable_new_combo_chart": true,
            "ui/sticky_simple_filter_panel": false,
            "ui/enable_linked_zoom": true,
            "ui/dashboard_tabs": true,
            "ui/shift_to_zoom": false,
            "ui/enable_crosslink_panel": true,
            "ui/enable_dashboard_shared_custom_sql": true,
            "ui/enable_custom_source_manager": true,
            "ui/geojoined-bounding-boxes": true,
            "ui/hide_deprecated_chart_types": false,
            "ui/map_export_limit": 50000000,
            "ui/table_export_limit": 50000000,
            "performance/crossfilter_pause_chart_button": true,
            "ui/enable_crosslink_panel": true,
            "ui/enable_custom_source_manager": true,
            "ui/raster-chart-kebab-visibility-toggle":true,
            "ui/enable_dashboard_shared_custom_sql": true,
            "ui/enable_global_custom_sql": true,
            "ui/enable_map_exports": "true",
            "ui/enable_dashboard_shared_custom_sql": true,
            "ui/enable_unrestricted_percentage_view_pie_chart": "true",
            "ui/geojoined-bounding-boxes": true,
            "ui/sticky_simple_filter_panel": false,
            "ui/table_params_in_param_manager": true,
            "dev/omni_sql_plus_plus_parse_in_strings": true,
            "dev/parse_crossfilter_tokens": true,
   	    "ui/enable_crossfilter_replay": true,
	    "ui/enable_chart_addons": true,
	    "performance/query_cache_duration": 240000,
            "performance/query_cache_size": 50,
            "performance/vega_cache_duration" : 240000,
            "performance/vega_cache_size" : 40
       	 }
  }
]
serverJsonEnd

cat >$NGINX_CONF_FILE <<nginxEnd
events {}

http {
  client_max_body_size 10000M;
  map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
  }

  upstream upstream_jupyter {
    server hub:8000;
    keepalive 32;
  }

  upstream upstream_heavyaiserver {
    server heavyaiserver:6273;
    keepalive 32;
  }

  server {

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    listen 80;
    listen [::]:80;

    server_name _;

    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;

    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Scheme \$scheme;

    proxy_read_timeout    86400;

    location / {
      proxy_pass http://upstream_heavyaiserver;
    }

    location = /jupyter {
      rewrite ^/(.*)$ \$1/ permanent;
    }

    location /jupyter {
      proxy_pass http://upstream_jupyter;
    }

    location ~* /(user/[^/]*)/(api/kernels/[^/]+/(channels|iopub|shell|stdin)|terminals/websocket)/? {
      proxy_pass            http://upstream_jupyter;
    }
  }
}
nginxEnd

cat > $DOCKERFILE_FILE <<dockerEnd
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG JUPYTERHUB_VERSION
FROM jupyterhub/jupyterhub:\$JUPYTERHUB_VERSION

# Install dockerspawner, nativeauthenticator
# hadolint ignore=DL3013
RUN python3 -m pip install --no-cache-dir \
    dockerspawner \
    jupyterhub-dummyauthenticator

CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]

dockerEnd

cat > $JUPYTERHUB_CONF_FILE <<jupyterEnd
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os

c = get_config()  # noqa: F821

# We rely on environment variables to configure JupyterHub so that we
# avoid having to rebuild the JupyterHub container every time we change a
# configuration parameter.

# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

# Spawn containers from this image
c.DockerSpawner.image = os.environ["DOCKER_NOTEBOOK_IMAGE"]

# JupyterHub requires a single-user instance of the Notebook server, so we
# default to using the start-singleuser.sh script included in the
# jupyter/docker-stacks *-notebook images as the Docker run command when
# spawning containers.  Optionally, you can override the Docker run command
# using the DOCKER_SPAWN_CMD environment variable.
spawn_cmd = os.environ.get("DOCKER_SPAWN_CMD", "start-singleuser.sh")
c.DockerSpawner.cmd = spawn_cmd

# Connect containers to this Docker network
c.DockerSpawner.network_name = os.environ["DOCKER_NETWORK_NAME"]

# Explicitly set notebook directory because we'll be mounting a volume to it.
# Most jupyter/docker-stacks *-notebook images run the Notebook server as
# user jovyan, and set the notebook directory to /home/jovyan/work.
# We follow the same convention.
notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan/work")
c.DockerSpawner.notebook_dir = notebook_dir

# Mount the real user's Docker volume on the host to the notebook user's
# notebook directory in the container
c.DockerSpawner.volumes = {"jupyterhub-user-{username}": notebook_dir, 
                        "jupyterhub-shared": "/home/jovyan/work/shared",
                        "jupyterhub-data": "/home/jovyan/work/data"}

# Remove containers once they are stopped
c.DockerSpawner.remove = False

# For debugging arguments passed to spawned containers
c.DockerSpawner.debug = True

c.DockerSpawner.extra_create_kwargs = {'user': 'root'}
c.DockerSpawner.environment = {
          'GRANT_SUDO': '1',
          'UID': '0',
}

##NETWORKING
c.DockerSpawner.remove = False
c.Spawner.default_url = '/lab'
c.Spawner.args = ['--NotebookApp.allow_origin=*']

# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.base_url = '/jupyter/'

# Persist hub data on volume mounted inside container
c.JupyterHub.cookie_secret_file = "/data/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////data/jupyterhub.sqlite"

# Authenticate users with Dummy Authenticator
c.JupyterHub.authenticator_class = "dummyauthenticator.DummyAuthenticator"

jupyterEnd



installFiles(){

  
  sudo mkdir /var/lib/heavyai
  sudo chown ubuntu /var/lib/heavyai
  sudo mkdir /var/lib/heavyai/import
  sudo mkdir /var/lib/heavyai/import/jhub_heavai_dropbox
  sudo mkdir /var/lib/heavyai/jupyter
  sudo chown -R ubuntu /var/lib/heavyai
  sudo cp ./daemon.json /etc/docker/.
  sudo systemctl stop docker
  sudo systemctl start docker



  cp ./$HEAVY_CONFIG_FILE_NAME /var/lib/heavyai/.
  cp ./$SERVERS_JSON_FILE /var/lib/heavyai/.


}

}


selectBuildFile() {
  VERSIONS_FILE="./heavyVersions.json"
  index=0;

  if [ -e $VERSIONS_FILE ]; then
  # Script will be interactive and display list of choices from ./heavyVersions.json file

    while read name; do
      echo $index $name
      ((index++))
    done < <(jq -r '.versionOptions[] | .name' $VERSIONS_FILE)

    while :
    do
      echo "Select the package you would like to install"
      read -p "? " menuChoice

      # Check if the input is a valid integer
      if [[ $menuChoice =~ ^[0-9]+$ ]]; then
        # Check if the input is less than the length of the array
        if (( $menuChoice < $index )); then
          name=$(jq -r ".versionOptions[$menuChoice].name" $VERSIONS_FILE)
          type=$(jq -r ".versionOptions[$menuChoice].type" $VERSIONS_FILE)
          DOCKER_IMAGE=$(jq -r ".versionOptions[$menuChoice].imageName" $VERSIONS_FILE)
          filepath=$(jq -r ".versionOptions[$menuChoice].filepath" $VERSIONS_FILE)
          filename=$(jq -r ".versionOptions[$menuChoice].filename" $VERSIONS_FILE)

          echo "Would you like me to install the following:"
          echo "Package Name: " $name
          echo "Install type: " $type
          echo "Docker Image name: " $DOCKER_IMAGE
          echo "Download Path: " $filepath
          echo "Download Filename: " $filename

          read -p "(Y)es, (N)o ?" confirmation
          break
        else
          echo "Invalid input. Please enter a number between 0 and $(($index - 1))."
        fi
      else
        echo "Invalid input. Please enter a number."
      fi
    done

    # Error handling: Check if the jq commands had any errors
    if [ $? -ne 0 ]; then
      echo "Error: Failed to extract version information from file $VERSIONS_FILE"
      exit 1
    fi

    if [ $confirmation = "y" ]; then
      case "$type" in
      internal)
      echo "Downloading docker image from $filepath/$filename"
      sudo wget $filepath/$filename
      sudo docker load < $filename
      echo "Configuring docker-compose file for $DOCKER_IMAGE"
      ;;

      release)
      echo "Configuring docker-compose file for $DOCKER_IMAGE"    
      ;;

      esac
    fi
  else
  # Use default values for installing latest docker image
    echo "No $VERSIONS_FILE present.  Configuring for latest version."
    name="Latest Release"
    type="release"
    DOCKER_IMAGE="heavyai/heavyai-ee-cuda:latest"

    echo "Package Name: " $name
    echo "Install type: " $type
    echo "Docker Image name: " $DOCKER_IMAGE
  fi

}

selectBuildFile
createFiles
installFiles
