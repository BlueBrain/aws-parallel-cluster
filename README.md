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

## Open questions

If the only change is a change in e.g. `slurm.taskprolog`, the validation job does not indicate that the cluster needs to be destroyed. However, it seems like an update does not trigger the OnNodeConfigured section of `commpute-cluster.yaml`?
