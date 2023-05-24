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

