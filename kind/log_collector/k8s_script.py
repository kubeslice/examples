import os
import kubernetes
from kubernetes import client, config

# Configs can be set in Configuration class directly or using helper utility
config.load_kube_config(
    # config_file=os.environ.get("KUBECONFIG", KUBE_CONFIG_PATH),
    config_file=os.environ.get("KUBECONFIG"),
    # context=os.environ.get("KUBECONTEXT"),
    context=os.environ.get("kind-controller"),
)

controller_namespace = "kubeslice-controller"
project_namespace = "kubeslice-demo"

v1 = client.CoreV1Api()
print("Listing pods with their IPs:")
ret = v1.list_pod_for_all_namespaces(watch=False)
for i in ret.items:
    # print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
    if "kubeslice-controller-manager" in i.metadata.name:
        pod_name = i.metadata.name
        break

# Print controller manager logs
print("Controller logs ****")
try:
    api_instance = client.CoreV1Api()
    api_response = api_instance.read_namespaced_pod_log(name=pod_name, namespace='kubeslice-controller', container='manager')
    print(api_response)
except ApiException as e:
    print('Found exception in reading the logs')

print("Controller Secrets ****")
k = v1.list_namespaced_secret(namespace=controller_namespace, pretty="true")
for i in k.items:
    # print(i.metadata.name)
    print(i)

k = v1.list_namespaced_secret(namespace=project_namespace, pretty="true")
for i in k.items:
    # print(i.metadata.name)
    print(i)

k = kubernetes.client.CustomObjectsApi().list_cluster_custom_object(namespace=project_namespace)
for i in k.items:
    print(i)

