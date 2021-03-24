# Deploy jupyterhub !

https://zero-to-jupyterhub.readthedocs.io/en/stable/

You need [helm](https://helm.sh/docs/intro/install/) to install everything onto the EKS cluster:
```
brew install helm
helm plugin install https://github.com/jkroepke/helm-secrets --version v3.5.0
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
```

## Dealing with senstive information in version control

With terraform and helm configurations it's common to have sensative information or "secrets" that should not be publically viewable. In order to store these configurations in a version control system like GitHub it is therefore critical to use an encryption tool. Helm has a plugin for the sops tool for secrets management that we will use https://github.com/jkroepke/helm-secrets

So following this guide we create a file called `secrets.yaml`
https://zero-to-jupyterhub.readthedocs.io/en/stable/jupyterhub/installation.html

that we encrypt with sops:
```
sops -e -i secrets.yml
```

Now it is safe to commit and push to GitHub!

sops needs a master key for encryption with is something that we created via terraform when we setup our `github-actions-user`. If you look at the `../.sops.yaml` configuration file we are pointing to the master key and AWS Role with permissions to use that key for encryption and decryption.

We can use the helm secrets plugin to see the decrypted content of our file
```
helm secrets -a "--verbose" view hub/secrets.yaml
```

And when we run helm commands to install jupyterhub, the helm-secrets plugin will decrypt our data using SOPS behind the scenes:

```
helm upgrade --cleanup-on-fail \
  --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE \
  --create-namespace \
  --version=0.11.1 \
  --values hub/config.yaml \
  --values secrets://hub/secrets.yaml
```

Note this will install JupyerHub Helm Chart Version 0.11.1 (https://github.com/jupyterhub/helm-chart#release-notes).




### Configuration changes

Just edit the .yaml or .tf files, push to github and GitHub Actions will deploy changes. If you are adding to our encrypted secrets.yaml, edit with `sops secrets.yaml``

To associate an iam role the default jupyterhub service account you need to add an annotation to the service account that the first jhub deploy creates (or create a yaml to do this). The role permission are defined in [terraform](../terraform/s3-data-bucket.tf)
```
kubectl create sa -n jhub jovyan
kubectl annotate serviceaccount -n jhub jovyan eks.amazonaws.com/role-arn=arn:aws:iam::XXXXXXX:role/jovyan-serviceaccount
```
