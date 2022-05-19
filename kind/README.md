# kind.sh

This bash script (kind.sh and related files) will create several kind clusters on a server and interconnect them with KubeSlice.   This script has been tested on Ubuntu VMs with 8GB RAM.

By default, it will create 1 "controller" and 2 "worker" clusters, connect them, and install iperf client/server in the two worker clusters to demonstrate connectivity.    To use:

```
git clone git@github.com:kubeslice/examples.git
cd examples/kind
bash kind.sh
```

See supported options by doing...

```
bash kind.sh --help 
```

When done, cleanup your clusters with...
```
bash kind.sh --clean
```

# tutorial.sh

This bash script will walk through the clusters that were created by kind.sh and explain the various elements and how they connect.

```
bash tutorial.sh
```

See supported options by doing...

```
bash tutorial.sh --help 
```

## More Info
A description of how to configure kind clusters from scratch is available at [Getting Started with Kind Clusters](https://docs.avesha.io/opensource/getting-started-with-kind-clusters)
