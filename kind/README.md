First clone this repo and switch to kind folder 

3 clusters deployment upto iperf connectivity(one cluster as hub and other two are spoke clusters)

Provision hub and two spoke clusters by using shell script and also (it will Install cert-manager, hub-system, project, clusters-registration, kubeslice-operator, slice and iperf deployments)

```shell
chmod 777 kind.sh
sh kind.sh
```

Provision hub and two spoke clusters only by using shell script

```shell
chmod 777 kind-clusters.sh
sh kind-clusters.sh
```

CleanUP hub and spoke clusters by using shell script

```shell
sh kind.sh clean
```

Note: ``` helm repo add kubeslice https://kubeslice.aveshalabs.io/repository/kubeslice-helm/ --username <USERNAME> --password '<PASSWORD>' ```


Reference for hub-system, kubeslice-operator, slice and iperf installations
https://avesha.atlassian.net/wiki/spaces/DEVOPS/pages/2280390676/Kind-Clusters%3A+deploy+hub-sytem%2C+kubeslice-operator%2C+slice+and+iperf