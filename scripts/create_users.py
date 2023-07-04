#!/usr/bin/env python3

import json
import os
import subprocess
import stat
import sys


def set_sudo(name, sudo):
    sudoers_file = f"/etc/sudoers.d/{name}"
    if sudo:
        with open(sudoers_file, 'w') as f:
            f.write(f"{name} ALL = NOPASSWD: ALL")
        os.chown(sudoers_file, 0, 0)
        os.chmod(sudoers_file, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
    else:
        if os.path.isfile(sudoers_file):
            print(f"sudoers file for {name} exists but requested to revoke rights, removing file.")
            os.remove(sudoers_file)

def main(argv):
    if len(argv) != 2:
        print("Please supply a user database")
        exit(1)

    # Setup the SBO group first
    group_id = 2000
    group_name = "sbo"
    groupadd_cmd = f"sudo groupadd -g {group_id} {group_name}"
    ret = subprocess.run(groupadd_cmd.split(' '))
    if not ret.returncode:
        print(f"Group '{group_name}' successfully created")
    else:
        print(f"Group '{group_name}' creation failed: {ret.stderr}")

    # Create the users and assign them to the SBO group
    user_filename = argv[1]
    with open(user_filename, 'r') as f:
        users = json.load(f)
    for user in users:
        useradd_cmd = f"sudo useradd -d /compute-efs/home/{user['name']} -M -s {user['shell']} -u {user['uid']} -U {user['name']} -G {group_name}"
        ret = subprocess.run(useradd_cmd.split(' '))
        if not ret.returncode:
            print(f"user {user['name']} successfully created")
        else:
            print(f"user creation for {user['name']} failed: {ret.stderr}")
        set_sudo(user['name'], user['sudo'])



if __name__ == "__main__":
    main(sys.argv)
