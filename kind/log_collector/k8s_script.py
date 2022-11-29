import ast
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

def print_controller_logs(config_file, context, controller_namespace):
    print("***** Controller manager logs *****")
    config.load_kube_config(
                config_file=os.environ.get(config_file),
                context=context
            )
    
    try:
        v1 = client.CoreV1Api()
        pod_name = ""
    
        ret = v1.list_namespaced_pod(controller_namespace)
        for i in ret.items:
            print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
            if "kubeslice-controller-manager" in i.metadata.name:
                pod_name = i.metadata.name
                break

        api_response = v1.read_namespaced_pod_log(name=pod_name, namespace=controller_namespace, container='manager')
        print(api_response)

        print()
        print("**** Secrets ****")
        k = v1.list_namespaced_secret(namespace=controller_namespace, pretty="true")
        for i in k.items:
            print(i)

        print()
        # print("**** Controller deployments ****")
        # resp = v1.list_namespaced_deployment(namespace=controller_namespace)
        # for i in resp.items:
        #     print(i)

        print()
        print("**** Controller projects ****")
        api_instance = kubernetes.client.CustomObjectsApi(v1)
        # api_response = api_instance.get_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", namespace=controller_namespace, 
        # plural="projects", name="projects.controller.kubeslice.io")
        api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="projects", namespace=controller_namespace)
        # print("Project(s): %s" % api_response["name"])
        # print("Project(s): %s" % api_response['items'])
        for i in api_response['items']:
            metadata = ast.literal_eval(i['metadata']['annotations']['kubectl.kubernetes.io/last-applied-configuration'])
            # print("Project: %s" % ast.literal_eval(i['metadata']['annotations']['kubectl.kubernetes.io/last-applied-configuration']))
            print("Project: %s" % metadata['metadata']['name'])

    except config.ConfigException as e:
        print('Found exception in reading the logs')

def get_contexts(config_file):
    k8s_contexts = []
    for context in range((len(config_file["clusters"]))):
        k8s_contexts.append(config_file["clusters"][context]["name"])
        print(config_file["clusters"][context]["name"])

    return k8s_contexts

def get_cluster_roles(contexts, config_file):
    roles = {}
    workers = []

    try:
        for context in contexts:
            config.load_kube_config(
                config_file=os.environ.get(config_file),
                context=context
            )

            v1 = client.CoreV1Api()
            nameSpaceList = v1.list_namespace()
            items = nameSpaceList.items
            metadata = []

            for item in items:
                metadata.append(item.metadata)

            namespaces = []
            for i in metadata:
                namespaces.append(i.name)

            if "kubeslice-controller" in namespaces:
                roles["controller"] = context
            elif "kubeslice-system" in namespaces:
                if "worker" in roles:
                    workers = roles["worker"]
                workers.append(context)
                roles["worker"] = workers

    except config.ConfigException as ce:
        print("###### Could not parse kubeconfig file: ", config_file)
        print(ce)

    return roles


# /home/jhveras/github/examples/kind/config/kubeconfig
# /home/juan/.kube/config
controller_namespace = "kubeslice-controller"
worker_namespace = "kubeslice-system"
project_namespace = "kubeslice-demo"

if __name__ == "__main__":
    config_file = get_kubeconfig_file()
    with open(config_file, mode="rb") as file:
        k8s_config = yaml.safe_load(file)

    contexts = get_contexts(k8s_config)
    clusters = get_cluster_roles(contexts, config_file)

    print(clusters)

    print_controller_logs(config_file, clusters["controller"], controller_namespace)








#if k8s_config is not None:    
#        try:
#            config.load_kube_config(
#                config_file=os.environ.get(config_file),
#                context=os.environ.get("KUBECONTEXT")
#            )
#        except config.ConfigException as ce:
#            print("###### Could not parse kubeconfig file: ", k8s_config)
#            print(ce)
#    else:
#        print("Invalid config file")
#        print("Terminating program")
#        sys.exit(0)

    

# client = client.CoreV1Api()

# print("**** Getting controller info ****")
# print("Listing pods:")
# get_pods(client, controller_namespace)


# # Print controller manager logs
# print("Controller logs ****")
# try:
#     api_instance = client.CoreV1Api()
#     api_response = api_instance.read_namespaced_pod_log(name=pod_name, namespace=controller_namespace, container='manager')
#     print(api_response)
# except ApiException as e:
#     print('Found exception in reading the logs')

# print("Controller Secrets ****")
# k = v1.list_namespaced_secret(namespace=controller_namespace, pretty="true")
# for i in k.items:
#     # print(i.metadata.name)
#     print(i)

# k = v1.list_namespaced_secret(namespace=project_namespace, pretty="true")
# for i in k.items:
#     # print(i.metadata.name)
#     print(i)

# k = kubernetes.client.CustomObjectsApi().list_cluster_custom_object(namespace=project_namespace)
# for i in k.items:
#     print(i)

