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

def get_project_name(config_file, context):
    project_name = ""

    config.load_kube_config(
                config_file=os.environ.get(config_file),
                context=context
            )

    try:
        v1 = client.CoreV1Api()
        api_instance = kubernetes.client.CustomObjectsApi(v1)
        api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="projects", namespace=controller_namespace)

        for i in api_response['items']:
            metadata = ast.literal_eval(i['metadata']['annotations']['kubectl.kubernetes.io/last-applied-configuration'])
            project_name = metadata['metadata']['name']
    except:
        print('Found exception while getting project name')

    return project_name


def print_controller_logs(config_file, context, controller_namespace):
    print("***** [%s]: Logs from container 'manager' *****" % context)
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
        print("**** [%s]: Secrets ****" % context)
        print("**** [%s]: kubectl -n kubeslice-controller get secrets -oyaml ****" % context)
        k = v1.list_namespaced_secret(namespace=controller_namespace, pretty="true")
        for i in k.items:
            print(i)

        print()
        print("**** [%s]: Projects ****" % context)
        print("**** [%s]: kubectl -n kubeslice-controller get projects.controller.kubeslice.io -oyaml ****" % context)
        api_instance = kubernetes.client.CustomObjectsApi(v1)
        api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="projects", namespace=controller_namespace, pretty="true")

        for i in api_response['items']:
            metadata = ast.literal_eval(i['metadata']['annotations']['kubectl.kubernetes.io/last-applied-configuration'])
            print("Project Name: %s" % metadata['metadata']['name'])
            print("Project Details: ")
            print(i['metadata']['annotations']['kubectl.kubernetes.io/last-applied-configuration'])
            project_namespace = "kubeslice-" + metadata['metadata']['name']

        print()
        print("**** [%s]: Cluster Details ****" % context)
        print("**** [%s]: kubectl -n %s get clusters.controller.kubeslice.io -oyaml ****" % (context, project_namespace))
        api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="clusters", namespace=project_namespace, pretty="true")
        print(api_response)

        print()
        print("**** [%s]: Slice Details ****" % context)
        print("**** [%s]: kubectl -n %s get sliceconfigs.controller.kubeslice.io -oyaml ****" % (context, project_namespace))
        api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="sliceconfigs", namespace=project_namespace, pretty="true")
        print(api_response)

        print()
        print("**** [%s]: Slice QoS Details ****" % context)
        print("**** [%s]: kubectl -n %s get sliceqosconfig.controller.kubeslice.io -oyaml ****" % (context, project_namespace))
        try:
            api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="sliceqosconfigs", namespace=project_namespace, pretty="true")
            print(api_response)
        except kubernetes.client.exceptions.ApiException:
            print("Couldn't find SliceQoS object")

        print()
        print("**** [%s]: SliceResourceQuotaConfig Details ****" % context)
        print("**** [%s]: kubectl -n %s get sliceresourcequotaconfig.controller.kubeslice.io -oyaml ****" % (context, project_namespace))
        try: 
            api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="sliceresourcequotaconfigs", namespace=project_namespace, pretty="true")
            print(api_response)
        except kubernetes.client.exceptions.ApiException:
            print("Couldn't find SliceResourceQuotaConfig object")

        print()
        print("**** [%s]: ServiceExportConfig Details ****" % context)
        print("**** [%s]: kubectl -n %s get serviceexportconfig.controller.kubeslice.io -oyaml ****" % (context, project_namespace))
        try:
            api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="controller.kubeslice.io", version="v1alpha1", plural="serviceexportconfigs", namespace=project_namespace, pretty="true")
            print(api_response)
        except kubernetes.client.exceptions.ApiException:
            print("Couldn't find ServiceExportConfig object")

    except config.ConfigException as e:
        print('Found exception in reading the logs')

def print_worker_logs(config_file, context, project_namespace):
    print("Worker cluster info: ")
    print("config_file = %s, context = %s, project_name = %s" % (config_file, context, project_namespace))
    print()
    print("**** [%s]: Worker Details ****" % context)
    config.load_kube_config(
                config_file=os.environ.get(config_file),
                context=context
            )

    try:
        v1 = client.CoreV1Api()
        api_instance = kubernetes.client.CustomObjectsApi(v1)

        print()
        print("**** [%s]: WorkerSliceConfig Details ****" % context)
        print("**** [%s]: Command: kubectl -n %s get workersliceconfig.worker.kubeslice.io -oyaml ****" % (context, project_namespace))
        try:
            api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="worker.kubeslice.io", version="v1alpha1", plural="workersliceconfigs", namespace=project_namespace, pretty="true")
            print(api_response)
        except kubernetes.client.exceptions.ApiException:
            print("Couldn't find WorkerSliceConfig object")

        print()
        print("**** [%s]: WorkerSliceGateway Details ****" % context)
        print("**** [%s]: Command: kubectl -n %s get workerslicegateway.worker.kubeslice.io -oyaml ****" % (context, project_namespace))
        try:
            api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="worker.kubeslice.io", version="v1alpha1", plural="workerslicegateways", namespace=project_namespace, pretty="true")
            print(api_response)
        except kubernetes.client.exceptions.ApiException:
            print("Couldn't find WorkerSliceGateway object")


        print()
        print("**** [%s]: WorkerServiceImport Details ****" % context)
        print("**** [%s]: Command: kubectl -n %s get workerserviceimport.worker.kubeslice.io -oyaml ****" % (context, project_namespace))
        try:
            api_response = kubernetes.client.CustomObjectsApi().list_namespaced_custom_object(group="worker.kubeslice.io", version="v1alpha1", plural="workerserviceimports", namespace=project_namespace, pretty="true")
            print(api_response)
        except kubernetes.client.exceptions.ApiException:
            print("Couldn't find WorkerServiceImport object")
    except:
        pass

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

    project_name = get_project_name(config_file, clusters["controller"])
    print("Project Name: %s" %project_name)

    print_controller_logs(config_file, clusters["controller"], controller_namespace)

    print()
    for cluster in clusters["worker"]:
        print_worker_logs(config_file, cluster, project_namespace)


