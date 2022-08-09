# Iperf setup
echo Setup Iperf
# Switch to kind-worker-1 context
kubectx controller
kubectx

kubectl apply -f iperf-sleep.yaml -n iperf
echo "Wait for iperf to be Running"
sleep 60
kubectl get pods -n iperf

# Switch to kind-worker-2 context
for WORKER in worker1 worker2; do
    if [[ $WORKER -ne "controller" ]]; then 
        kubectx $WORKER
        kubectx
        kubectl apply -f iperf-server.yaml -n iperf
        echo "Wait for iperf to be Running"
        sleep 60
        kubectl get pods -n iperf
    fi
done

# Switch to worker context
kubectx worker1
kubectx

sleep 90
# Check Iperf connectity from iperf sleep to iperf server
IPERF_CLIENT_POD=$(kubectl get pods -n iperf | grep iperf-sleep | awk '{ print$1 }')

kubectl exec -it $IPERF_CLIENT_POD -c iperf -n iperf -- iperf -c iperf-server.iperf.svc.slice.local -p 5201 -i 1 -b 10Mb;
if [ $? -ne 0 ]; then
    echo '***Error: Connectivity between clusters not succesful!'
    ERR=$((ERR+1))
fi

# Return status
exit $ERR