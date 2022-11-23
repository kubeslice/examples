import os
import kubernetes
from kubernetes import client, config
from pathlib import Path
import sys
import yaml

def validate_kubeconfig_file(kubeconfig_file):
    try:
        file = Path(kubeconfig_file)
    except:
        file = ""

    return file.is_file()

def get_kubeconfig_file():
    if "KUBECONFIG" in os.environ:
        config_file = os.environ.get("KUBECONFIG")
    else:
        config_file = input("Please provide full path to kubeconfig file: ")

    if validate_kubeconfig_file(config_file): 
        return config_file

    return None

def get_pods(client, namespace):
    ret = client.list_namespaced_pod(namespace)
    for i in ret.items:
        print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
        if "kubeslice-controller-manager" in i.metadata.name:
            pod_name = i.metadata.name
            break

def get_cluster_roles(clusters):    
    pass

def get_contexts(config_file):
    k8s_contexts = []
    for context in config_file:
        k8s_contexts.append(context["name"])

    

config_file = get_kubeconfig_file()
with open("/home/jhveras/github/examples/kind/config/kubeconfig", mode="rb") as file:
    k8s_config = yaml.safe_load(file)



if config_file is not None:
    # Configs can be set in Configuration class directly or using helper utility
    config.load_kube_config(
        config_file=os.environ.get(config_file),
        context=os.environ.get("KUBECONTEXT")
    )
else:
    print("Invalid config file")
    print("Terminating program")
    sys.exit(0)



# /home/jhveras/github/examples/kind/config/kubeconfig

controller_namespace = "kubeslice-controller"
worker_namespace = "kubeslice-system"
project_namespace = "kubeslice-demo"

client = client.CoreV1Api()

print("**** Getting controller info ****")
print("Listing pods:")
get_pods(client, controller_namespace)


# Print controller manager logs
print("Controller logs ****")
try:
    api_instance = client.CoreV1Api()
    api_response = api_instance.read_namespaced_pod_log(name=pod_name, namespace=controller_namespace, container='manager')
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

