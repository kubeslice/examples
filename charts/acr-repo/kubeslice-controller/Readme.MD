# Kubeslice Enterprise Controller Helm Charts


The KubeSlice Controller is installed in one of the clusters and provides a central configuration management system, for slices across multiple clusters. Please refer to the [documentation](https://docs.avesha.io/documentation/enterprise/1.6.0/architecture) for more details.

# Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add kubeslice https://kubeslice.aveshalabs.io/repository/kubeslice-helm-ent-prod/ 
```

You can then run `helm search repo kubeslice` to see the charts.

## Setting Up Kubeslice Controller

### Install Chart

For setting up Kubeslice Controller on cloud platforms, refer to the [Kubeslice Controller Installation on Cloud](https://docs.avesha.io/documentation/enterprise/1.6.0/install-kubeslice/yaml/yaml-controller-install).

### Uninstall Chart

Please refer the following Kubeslice Controller [uninstallation](https://docs.avesha.io/documentation/enterprise/1.6.0/uninstall-kubeslice/) steps.

### Upgrading Chart

```console
helm upgrade [RELEASE_NAME] kubeslice/kubeslice-controller [flags]
```

Guide
---
A full and comprehensive documentation is available on our enterprise [documentation](https://docs.avesha.io/documentation/enterprise/) website.
