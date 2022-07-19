# boutique.sh

This boutique script runs as an example of kubeslice showing how microservices can work and communicate with other across clusters due to them being on the same slice.

It sets the frontend service on one cluster (in this case kind-worker-1) as it acts as the driver of this example needing to communicate with all the microservices to work.
It sets all other microservices to get boutique running on the other cluster (kind-worker-2) and since all of these microservices across both clusters are on the same
namespace, boutique which is on a common slice called water, the microservices are able to communicate and function properly together.

To use:

```
bash boutique.sh
```

To uninstall:

```
./boutique.sh --delete
```
