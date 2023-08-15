#!/usr/bin/env python3

import json
import subprocess
import sys


# Helper method to run a command and exit after an error
def run_cmd(cmd, msg_prefix, output_file = subprocess.PIPE, exit_after_error = True):
    try:
        subprocess.run(cmd.split(' '), stdout=output_file, stderr=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as ret:
        error_msg = ret.stderr.decode().replace('\n','')
        print(f"{msg_prefix} failed:\n\t\"{error_msg}\"")
        if exit_after_error:
            exit(ret.returncode)
    print(f"{msg_prefix} succeeded.")


# Helper method to create a user and configure sudo permissions
def create_user(name, uid, group, shell, sudo):
    # Create the user with the provided group and shell
    run_cmd(f"useradd -d /sbo/home/{name} -M -s {shell} -u {uid} -U {name} -G {group}",
            f"User '{name}' creation")

    # Configure sudo permissions accordingly
    sudoers_file = f"/etc/sudoers.d/{name}"
    if sudo:
        run_cmd(f"echo -n {name} ALL = NOPASSWD: ALL",
                f"Enabling sudo configuration for '{name}'",
                open(sudoers_file, 'w'))
    else:
        run_cmd(f"rm -f {sudoers_file}",
                f"Disabling sudo configuration for '{name}'")

def main(argv):
    if len(argv) != 2:
        print("Please, supply a user database.")
        exit(1)

    user_filename = argv[1]
    group_id = 2000
    group_name = "sbo"

    # First, configure the SBO group for the users
    run_cmd(f"groupadd -g {group_id} {group_name}",
            f"Group '{group_name}' creation")

    # Create the users within the SBO group and configure sudo permissions
    with open(user_filename, 'r') as f:
        users = json.load(f)
    for user in users:
        create_user(user['name'], user['uid'], group_name, user['shell'], user['sudo'])


if __name__ == "__main__":
    main(sys.argv)
