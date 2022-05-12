# kind.sh

This script (kind.sh and related files) will create several kind clusters on a server and interconnect them with KubeSlice.

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
