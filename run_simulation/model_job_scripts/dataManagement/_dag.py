"""Example script that shows how to connect to Yoda using python-irodsclient (iRODS's Python API) and perform a GenQuery"""

from getpass import getpass
import json
import ssl
import sys
from pathlib import Path
from tqdm import tqdm
import shutil

from irods.models import Collection
from irods.session import iRODSSession            

def setup_iRodsSession(env_config, password, ca_file, timeout):
    
    def get_irods_environment(irods_environment_file):
        """Reads the irods_environment.json file, which contains the environment
        configuration."""
        with open(irods_environment_file, 'r') as f:
            return json.load(f)

    def setup_session(irods_environment_config,  password, ca_file, timeout, require_ssl = True):
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
                timeout=timeout,
                **irods_environment_config,
                **ssl_settings
            )
        else:
            session = iRODSSession(
                password=password,
                **irods_environment_config,
            )

        return session

    session = setup_session(get_irods_environment(env_config), password, ca_file, timeout)
    if session is None:
        print("Error: unable to create session.")
        sys.exit(1)
    else:
        return session
    
# # Create a session
timeout = 300
env_config = '/home/barrygwt/.irods/irods_environment.json'
ca_file = '/home/barrygwt/.irods/cacert.pem'
password = sys.argv[1]
simPath=Path(sys.argv[2])
rootSavePath=Path(sys.argv[3])
print(rootSavePath)

print(simPath)
p = sorted(simPath.glob('**/*'))
files = [x for x in p if x.is_file()]
    
session = setup_iRodsSession(env_config, password, ca_file, timeout)
    
for file in tqdm(files):
    with session as s:
        home_collection = rootSavePath.parent.as_posix()
        collections = (s.query(Collection.name)
                    .filter(Collection.parent_name == home_collection)
                    .get_results())
        tqdm.write(f"Processing file: {file.name}")
        saveFile = (rootSavePath / file.relative_to(simPath.parent))
        saveDirectory = saveFile.parent
        s.collections.create(saveDirectory.as_posix())
        s.data_objects.put(file.as_posix(), saveFile.as_posix())