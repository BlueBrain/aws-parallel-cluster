# parallel-cluster

## Branching strategy

For your development, you'll want to branch off from the `staging` branch. This is where we collect everything before it gets merged into `main` to avoid having to redeploy the cluster for every merge request.

### Merging

When merging into `staging`, make sure to squash your commits to keep the commit history clean.
When merging `staging` into `main`, _don't_ squash the commits: every commit is already one distinct item (ie. a "feature branch") and can stand on its own in the commit history.


## Deployment

Once your merge request got merged into `staging`, it will not be deployed yet, that only happens upon merging into `main`. The merge request from `staging` into `main` needs to be approved by someone with the correct permissions (Omar, Pramod or CS).

Don't forget to check whether the cluster is idle!

If you need the cluster to be redeployed, make sure to destroy it before merging into `main`. The merge request pipeline will have a `destroy` job that needs to be triggered manually to avoid accidents. Once it has completed, you can merge and the cluster will be completely redeployed.

If all you need is an update, you can go ahead and have your merge request merged. The pipeline that runs after merging will update the cluster.

## How to update the custom AMI

We use a custom AMI based on the stock AL2 AMI of parallel-cluster. Sometimes this AMI needs to be
updated:
- When we update parallel-cluster and it relies on a new AL2 image, then we need to also update our
  custom image
- When one of our components needs updating or we want to add a new component or functionality into
  the image

### Update or create your components. 


They are all in `./config/ami_components`. To create a new component
it's best to start with an existing component and modify it. While there is quite some 
[documentation](https://docs.aws.amazon.com/imagebuilder/latest/userguide/toe-component-manager.html)
on how to write component documents, it is quite hard to understand and apply for our use-case and took quite some trial and error.

Once the component documents are up-to-date they can be pushed to s3 and the componets updated (or
created). Use the `update_components` step in the CI:

- Open the `.gitlab-ci.yml` file and check `update_components` step.
- There is an s3 sync command that makes sure changed components are pushed to s3.
- You need to add/update `aws imagebuilder` commands for each component to invoke the creation of
  the image components. Make sure you update the version number and add a sensible commit message.
- Once the componets have finished building (which is quick) the `imagebuild` tool will output the
  latest ARNs of the new componets, the follow a predictable pattern, where only the version part at
  the end is incremented according to the new version you defined in your command. Write down those
  ARNs.
### Update the image

**Note:** Make sure to update the parallel-cluster version **before** you update the image. The
latter depends on the former being on the desired version!

- Edit `./config/custom_al2_x86_ami_config.yaml` updating/adding the component ARNs. Add, commit and
  push the changes.
- Use the `build_image` CI step. It takes an `IMAGE_ID` argument where you need to define the ID of
  your new image. it follows the pattern `alinux2-x86-sbo-pcluster-v[0-9]+` where you increment the
  version number. You can use the `print_info` CI step to find out what images currently exist.
- You can use `delete_image` to get rid of outdated images too (which is good practice).
- Once the image has been built you should note down its AMI. This ID will then be used for the new
  cluster deployment.

### Redeploying the cluster

- update the AMI in `./config/compute-cluster.yaml` add, commit and push the change.
- Once the verifiction succeeds, merge the MR to staging and create a new MR from staging to main. Destroy
  the cluster and merge that MR to redeploy.

## Open questions

If the only change is a change in e.g. `slurm.taskprolog`, the validation job does not indicate that the cluster needs to be destroyed. However, it seems like an update does not trigger the OnNodeConfigured section of `commpute-cluster.yaml`?
