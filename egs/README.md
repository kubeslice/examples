# bin/egs_make_cluster + egs-installer.sh

This script will deploy a kind cluster (named "egs") and will label the kind node such that it will apper as a GPU-capable node for EGS use.  (The assuption is that the host system actually has a GPU (NVIDIA) available as well as as least 2 available CPU and 8GB RAM.)   

To use:

```
git clone https://github.com/kubeslice/examples.git 
git clone https://github.com/kubeslice-ent/egs-installation.git
cd egs-installation
```
Follow the egs-installation README instructions to register for pull secrets and modify the egs-installer-config.yaml as specified.

To use with this kind demo, also make these changes (because the tool will copy the kubeconfig.yaml file locally, will make a cluster with context kind-egs and needs the default internal endpoint):

global_kubeconfig: "./kubeconfig.yaml"  
global_kubecontext: "kind-egs"

...and change the controller endpoint to be...
   inline_values:  # Inline Helm values for the controller chart
     kubeslice:  
         controller:   
         endpoint: "https://kubernetes.default.svc:443" 




Then run with...
```
../examples/egs/bin/egs_make_cluster
./egs-installer.sh --input-yaml ./egs-installer-config.yaml
```

The result should be a cluster with EGS installed and the UI endpoint exposed by metallb.  Find the UI address with:
kubectl get svc -A | grep kubeslice-ui-proxy

Bring up your browser and go to the external address for the UI proxy.   Copy the access token displayed by the end of the egs-installer script and paste it into the UI to log in.


When done, cleanup your clusters with...
```
../examples/egc/bin/egs-cleanup-cluster
```
