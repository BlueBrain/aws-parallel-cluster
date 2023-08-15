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


# Helper method to create a directory for a given user
def create_directory(prefix, user, group):
    path = f"{prefix}/scratch/{user}"

    # Create folder with correct permissions and set ownership
    run_cmd(f"mkdir -m 755 -p {path}",
            f"Creation of Lustre path for '{user}'")
    run_cmd(f"chown {user}:{group} {path}",
            f"Setting Lustre path permissions for '{user}' at '{path}'")


def main(argv):
    if len(argv) != 3:
        print("Please, supply a user database and Lustre FSx mount point.")
        exit(1)

    user_filename = argv[1]
    fsx_path = argv[2]
    group_name = "sbo"

    # Load the user database and configure a dedicated directory per user
    with open(user_filename, 'r') as f:
        users = json.load(f)
    for user in users:
        create_directory(fsx_path, user['name'], group_name)

    # Configure the SLURM directory (i.e., for job allocations and logs)
    create_directory(fsx_path, "slurm", "slurm")

    # Setup the global permissions
    run_cmd(f"chmod 755 {fsx_path} {fsx_path}/scratch",
            f"Setting Lustre path permissions for '{fsx_path}'")


if __name__ == "__main__":
    main(sys.argv)
