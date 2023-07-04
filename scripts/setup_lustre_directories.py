#!/usr/bin/env python3

import json
import subprocess
import sys


def main(argv):
    if len(argv) != 3:
        print("Please supply a user database and Lustre FSx mount point")
        exit(1)
    user_filename = argv[1]
    fsx_path = argv[2]
    group_name = "sbo"
    with open(user_filename, 'r') as f:
        users = json.load(f)
    for user in users:
        path = f"{fsx_path}/scratch/{user['name']}"

        # Create the folder with the correct permissions
        userdir_cmd = f"sudo mkdir -m 755 -p {path}"
        ret = subprocess.run(userdir_cmd.split(' '))
        if not ret.returncode:
            print(f"Lustre path for {user['name']} successfully created")
        else:
            print(f"Lustre path for {user['name']} failed: {ret.stderr}")

        # Change the ownership to the user
        ownership_cmd = f"sudo chown {user['name']}:{group_name} {path}"
        ret = subprocess.run(ownership_cmd.split(' '))
        if not ret.returncode:
            print(f"Lustre path permissions for {user['name']} at {path} successfully setup")
        else:
            print(f"Lustre path permissions for {user['name']} at {path} failed: {ret.stderr}")
    
    # Setup the global permissions
    permissions_cmd = f"sudo chmod 755 {fsx_path} {fsx_path}/scratch"
    ret = subprocess.run(permissions_cmd.split(' '))
    if not ret.returncode:
        print(f"Lustre path permissions for {fsx_path} successfully setup")
    else:
        print(f"Lustre path permissions for {fsx_path} failed: {ret.stderr}")



if __name__ == "__main__":
    main(sys.argv)
