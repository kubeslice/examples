# Kubeslice Manager Helm Charts


KubeSlice Manager is a UI application to register clusters and manage application slices. It connects to the KubeSlice Controller API gateway to access data. Users can log in using a service account to manage the slices. Please refer to the [documentation](https://docs.avesha.io/documentation/enterprise/1.6.0/architecture) for more details.

# Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add kubeslice https://kubeslice.aveshalabs.io/repository/kubeslice-helm-ent-prod/ 
```

You can then run `helm search repo kubeslice` to see the charts.

## Setting Up Kubeslice Manager

### Install Chart
You must install the KubeSlice Controller chart before installing the KubeSlice Manager chart. 

For setting up Kubeslice Manager on cloud platforms, refer to the [Kubeslice Manager Installation on Cloud](https://docs.avesha.io/documentation/enterprise/1.6.0/install-kubeslice/yaml/yaml-controller-install#install-the-kubeslice-manager).

### Uninstall Chart

Please refer the following Kubeslice Manager [uninstallation](https://docs.avesha.io/documentation/enterprise/1.6.0/uninstall-kubeslice/) steps.

### Upgrading Chart

```console
helm upgrade [RELEASE_NAME] kubeslice/kubeslice-ui [flags]
```

Guide
---
A full and comprehensive documentation is available on our enterprise [documentation](https://docs.avesha.io/documentation/enterprise/) website.
