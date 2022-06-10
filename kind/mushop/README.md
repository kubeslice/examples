# Mushop on kubeslice

`Mushop` is a cloud native microservices application by oracle <https://oracle-quickstart.github.io/oci-cloudnative/introduction/> . It contains various microservices written in different languages and showcases the use of different cloud services by oracle.
This guide shows how to install mushop app on kubeslice across multiple clusters.

This diagram shows the overall architecture of the app : https://oracle-quickstart.github.io/oci-cloudnative/cloud/ 

To install the bare minimum setup to make it work across clusters, we need an ATP Database from oracle cloud. This link https://oracle-quickstart.github.io/oci-cloudnative/cloud/deployment/  has the instructions to create the ATP Database and create a kubernetes secret on the clusters using those credentials.

The following are required to create the kubernetes secret

* Admin password (given at the time of creating the db)
* A folder which contains the wallet to connect to the db (can be downloaded as a zip file from oracle cloud UI)
* Wallet password (given at the time of creating wallet)
* OADB Service (can be found from UI, eg: mushopatp-tp)


```
kubectl create secret generic oadb-admin \
  --namespace mushop \
  --from-literal=oadb_admin_pw='<DB_ADMIN_PASSWORD>'
```

```
kubectl create secret generic oadb-wallet \
  --namespace mushop \
  --from-file=<PATH_TO_EXTRACTED_WALLET_FOLDER>
```

```
kubectl create secret generic oadb-connection \
  --namespace mushop \
  --from-literal=oadb_wallet_pw='<DB_WALLET_PASSWORD>' \
  --from-literal=oadb_service='<DB_TNS_NAME>'
```

The above step should be done in all the clusters where we want to distribute the services. Other cloud services like streaming service, email service etc. are optional.

## Helm chart changes

The official helm chart for mushop can be found here https://oracle-quickstart.github.io/oci-cloudnative/quickstart/kubernetes/ 

It needed the following changes to make it work with kubeslice

* Add the following annotations to make the app pods as part of slice (not required if we are using namespace onboarding)

```
annotations:
    avesha.io/slice: mu
```

* Modify `requirements.yaml` to make all components conditional. This will allow us to split the services and install only few components per cluster
* In the api service deployment, modify the environment values to use the DNS names of serviceexport instead of service names to communicate with dependent services across the clusters.
* Add serviceexports for all the microservices
* Create separate values file per cluster. We can choose what components are installed in each cluster using the conditions in values file (example given below)
* Disable mocking and specify the name of the secrets where we configured database credentials in values files. x

Example values file for cluster1:


```
global:
  mock:
    service: "false"
  oadbAdminSecret: oadb-admin           # Name of DB Admin secret
  oadbWalletSecret: oadb-wallet         # Name of Wallet secret
  oadbConnectionSecret: oadb-connection # Name of DB Connection secret

ingress:
  enabled: true

api:
  enabled: true

assets:
  enabled: true

carts:
  enabled: false

catalogue:
  enabled: false

edge:
  enabled: true

events:
  enabled: false

orders:
  enabled: false

payment:
  enabled: false

session:
  enabled: true
  securityContext:
    readOnlyRootFilesystem: false

storefront:
  enabled: true

fulfillment:
  enabled: false

nats:
  enabled: false

user:
  enabled: false
```




For cluster2:

```
global:
  mock:
    service: "false"
  oadbAdminSecret: oadb-admin           # Name of DB Admin secret
  oadbWalletSecret: oadb-wallet         # Name of Wallet secret
  oadbConnectionSecret: oadb-connection # Name of DB Connection secret

ingress:
  enabled: false

api:
  enabled: false

assets:
  enabled: false

carts:
  enabled: true

catalogue:
  enabled: true

edge:
  enabled: true

events:
  enabled: false

orders:
  enabled: true

payment:
  enabled: true

session:
  enabled: false

storefront:
  enabled: false

fulfillment:
  enabled: true

nats:
  enabled: true

user:
  enabled: true
```

Once the charts are deployed, we can browse the edge service using port-forwarding and make sure everything works fine in the UI


```
kubectl port-forward svc/edge 8080:80
```
