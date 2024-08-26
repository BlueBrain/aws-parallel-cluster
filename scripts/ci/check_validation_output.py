#!/usr/bin/env python

import json
import os

import requests
from furl import furl


def collect_merge_request_discussions(session, gitlab_url):
    response = session.get(gitlab_url.tostr())
    response.raise_for_status()
    discussions = response.json()
    current_page = int(response.headers.get("X-Page", 1))
    total_pages = int(response.headers.get("X-Total-Pages", 1))
    while current_page < total_pages:
        print(f"Page {current_page + 1} of {total_pages}")
        try:
            next_link = (
                next(
                    link
                    for link in response.headers["Link"].split(",")
                    if 'rel="next"' in link
                )
                .split(";")[0]
                .strip()
                .lstrip("<")
                .rstrip(">")
            )
            print(f"Next link: {next_link}")
        except StopIteration:
            print("No next link found, end of comments reached.")
            break
        response = session.get(next_link)
        response.raise_for_status()
        current_page = int(response.headers.get("X-Page", 1))
        total_pages = int(response.headers.get("X-Total-Pages", 1))
        discussions.extend(response.json())

    return discussions


def comment_if_necessary(cannot_update_messages):
    session = requests.Session()
    session.headers = {
        "PRIVATE-TOKEN": os.environ["VALIDATION_COMMENTER_TOKEN"],
        "Content-Type": "application/json",
    }
    gitlab_api_url = os.environ["CI_API_V4_URL"]
    gitlab_project_id = os.environ["CI_PROJECT_ID"]
    gitlab_merge_request_iid = os.environ.get("CI_MERGE_REQUEST_IID")
    gitlab_job_url = os.environ["CI_JOB_URL"]

    if gitlab_merge_request_iid:
        print(
            f"Merge request {gitlab_merge_request_iid} found. Checking whether we need to comment"
        )

        gitlab_url = furl(gitlab_api_url)
        gitlab_url.path.segments.extend(
            [
                "projects",
                gitlab_project_id,
                "merge_requests",
                gitlab_merge_request_iid,
                "discussions",
            ]
        )
        discussions = collect_merge_request_discussions(session, gitlab_url)

        our_unresolved_comments = [
            comment
            for comment in [
                note.get("body", "")
                if (note.get("resolved", True) is False)
                and (
                    "has determined that the only issue with your merge request"
                    in note.get("body", "")
                )
                and (note.get("author", {}).get("id") == 609)
                else ""
                for discussion in discussions
                for note in discussion.get("notes", [])
            ]
            if comment
        ]

        if our_unresolved_comments:
            print(f"Our unresolved comments: {our_unresolved_comments}")
            print(
                "Already commented and the comment is not resolved. Skipping this step."
            )
        else:
            print("No unresolved comment found yet. Commenting.")
            body = (
                f"{gitlab_job_url} has determined that the only issue with your merge request "
                "is that the cluster's compute fleet is not stopped or that "
                "the cluster is not destroyed. Please stop the cluster and re-run validation "
                "before merging.<br>"
                "Complaints raised by the pcluster:<br>"
                f"<ul><li>{'<li>'.join(cannot_update_messages)}</ul>"
            )
            print(f"Posting {body} to {gitlab_url.tostr()}")
            response = session.post(gitlab_url.tostr(), json={"body": body})
            print(response.content)
            response.raise_for_status()


def main():
    with open("pcluster-output.log", "r") as fp:
        pcluster_output = json.load(fp)

    real_error_messages = [
        x["message"]
        for x in pcluster_output.get("updateValidationErrors", [])
        if "All compute nodes must be stopped" not in x["message"]
        and "Update actions are not currently supported" not in x["message"]
    ]

    if "configurationValidationErrors" in pcluster_output:
        real_error_messages.extend(pcluster_output["configurationValidationErrors"])

    cannot_update_messages = [
        x["message"]
        for x in pcluster_output.get("updateValidationErrors", [])
        if "All compute nodes must be stopped" in x["message"]
        or "Update actions are not currently supported" in x["message"]
    ]

    if real_error_messages:
        raise RuntimeError(
            "There were issues with your pcluster config - "
            "please see above output for details and fix them"
        )

    elif cannot_update_messages and (
        len(cannot_update_messages)
        == len(pcluster_output.get("updateValidationErrors", []))
    ):
        print(
            "The only complaints are about running compute nodes - "
            "we'll comment on the merge request (if there is one) and let the job succeed."
        )
        comment_if_necessary(cannot_update_messages)
    elif (
        "the update can be performed only with the same ParallelCluster version"
        in pcluster_output.get("message")
    ):
        print(
            "parallel-cluster update is happening."
            "Since otherwise no errors were raised, we carry on."
        )
    else:
        print(
            "If we get here, there were probably no issues, but we'll check to make sure. "
            "If this raises an error, some debugging is in order."
        )
        if "No changes found" not in pcluster_output.get(
            "message"
        ) and "Request would have succeeded, but DryRun flag is set" not in pcluster_output.get(
            "message"
        ):
            raise ValueError(
                "Unexpected output - please check the output and fix this script"
            )


if __name__ == "__main__":
    main()
