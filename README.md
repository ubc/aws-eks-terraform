## Requirements

1. LThub UBC AWS account access.

2. saml2aws (https://github.com/Versent/saml2aws)

3. AWS Cli (https://github.com/aws/aws-cli)

4. kubectl (https://kubernetes.io/docs/tasks/tools/)

5. helm (https://helm.sh/docs/intro/install/)

6. terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)








```bash
$ terraform init
$ terraform apply
```

If the cluster deploys OK, add the config to your `~/.kube/config`

```bash
$ aws --profile=urn:amazon:webservices --region=us-west-2 eks list-clusters
...
{
    "clusters": [
        "syzygy-eks-tJSxgQlx"
    ]
}

$ aws --profile=urn:amazon:webservices --region=us-west-2 eks update-kubeconfig \
  --name=syzygy-eks-tJSxgQlx
```

And check that you can interact with the cluster
```bash
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.3", GitCommit:"5e53fd6bc17c0dec8434817e69b04a25d8ae0ff0", GitTreeState:"clean", BuildDate:"2019-06-06T01:44:30Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"13+", GitVersion:"v1.13.8-eks-a977ba", GitCommit:"a977bab148535ec195f12edc8720913c7b943f9c", GitTreeState:"clean", BuildDate:"2019-07-29T20:47:04Z", GoVersion:"go1.11.5", Compiler:"gc", Platform:"linux/amd64"}

$ kubectl get nodes
NAME                                       STATUS   ROLES    AGE     VERSION
ip-10-1-1-224.us-west-2.compute.internal   Ready    <none>   8m29s   v1.13.7-eks-c57ff8
ip-10-1-2-85.us-west-2.compute.internal    Ready    <none>   8m48s   v1.13.7-eks-c57ff8
ip-10-1-3-122.us-west-2.compute.internal   Ready    <none>   8m30s   v1.13.7-eks-c57ff8
```

If you don't see any worker nodes, check the AWS IAM role configuration.

## Helm
We will be using RBAC (see the [helm RBAC
documentation](https://helm.sh/docs/using_helm/#role-based-access-control), so
we need to configure a role for tiller and initialize tiller.
```
$ kubectl create -f docs/rbac-config.yaml
$ helm init --service-account tiller --history-max 200
```
