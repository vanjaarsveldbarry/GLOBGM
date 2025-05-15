"""Example script that shows how to connect to Yoda using python-irodsclient (iRODS's Python API) and perform a GenQuery"""

from getpass import getpass
import json
import ssl
import sys
from pathlib import Path
from tqdm import tqdm
import shutil
from irods.column import Like
import os
import time
from irods.models import Collection, DataObject
from irods.session import iRODSSession            

def setup_iRodsSession(env_config, password, ca_file):
    
    def get_irods_environment(irods_environment_file="irods_environment.json"):
        """Reads the irods_environment.json file, which contains the environment
        configuration."""
        with open(irods_environment_file, 'r') as f:
            return json.load(f)

    def setup_session(irods_environment_config,  password, ca_file, require_ssl = True):
        """Use irods environment files to configure a iRODSSession"""

        if require_ssl:
            ssl_context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH, cafile=ca_file, capath=None, cadata=None)
            ssl_settings = {'client_server_negotiation': 'request_server_negotiation',
                            'client_server_policy': 'CS_NEG_REQUIRE',
                            'encryption_algorithm': 'AES-256-CBC',
                            'encryption_key_size': 32,
                            'encryption_num_hash_rounds': 16,
                            'encryption_salt_size': 8,
                            'ssl_context': ssl_context}
            session = iRODSSession(
                irods_password=password,
                **irods_environment_config,
                **ssl_settings
            )
        else:
            session = iRODSSession(
                password=password,
                **irods_environment_config,
            )

        return session

    session = setup_session(get_irods_environment(env_config), password, ca_file)
    if session is None:
        print("Error: unable to create session.")
        sys.exit(1)
    else:
        return session
def put_directory(session, local_path, irods_path, session_refresh_interval=30):
    # Get the total number of files and directories for the progress bar
    total_entries = sum([len(files) for _, _, files in os.walk(local_path)])
    progress_bar = tqdm(total=total_entries, desc="Uploading", unit="file", miniters=100, mininterval=60)

    def recursive_put(session, local_path, irods_path):
        # Create collection in iRODS
        coll = session.collections.create(irods_path)
        for entry in os.scandir(local_path):
            # Check if it's time to refresh the session
            if entry.is_file():
                # Upload file to collection
                session.data_objects.put(entry.path, irods_path, force=True)
                progress_bar.update(1)
            elif entry.is_dir():
                # Recursively create subcollection and upload contents
                recursive_put(session, entry.path, irods_path + '/' + entry.name)

    recursive_put(session, local_path, irods_path)
    progress_bar.close()

# Create a session
env_config = '/home/barrygwt/.irods/irods_environment.json'
password = 'YOPxqAHD38IAynf9BbqZe_mksPRGWQCO'
ca_file = '/home/barrygwt/.irods/cacert.pem'

root_target=Path('/nluu11p/home/research-geowat-simulations/globgm_cmip6')
root_source = Path('/projects/prjs1222/scratch_backup/globgm_scratch/archive')
simulation = 'reference_gswp3-w5e5'

sim = str(sys.argv[1])

sub_target_parent = root_target / simulation
session = setup_iRodsSession(env_config, password, ca_file)
session.collections.create(sub_target_parent.as_posix())
session.connection_timeout = 2592000 

sub_source = root_source / simulation / sim
sub_target_parent = root_target / simulation / sim
    
put_directory(session, sub_source.as_posix(), sub_target_parent.as_posix())
