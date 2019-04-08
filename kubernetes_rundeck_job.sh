#!/bin/bash

usage () {
    echo "usage: kubernetes_rundeck_job [[-n namespace ] | [-h]]"
}

get_podname () {
    PODNAME=`kubectl get pods -n $namespace -l "job-name=$JOBNAME" --sort-by="{.metadata.creationTimestamp}" | tail -1 | cut -f1 -d' '`
}
get_status () {
    STATUS=`kubectl get jobs -n $namespace -l "job-name=$JOBNAME" -o jsonpath="{.items[0].status.conditions[0].type}"`
}
get_full_status () {
    FULL_STATUS=`kubectl get jobs -n $namespace -l "job-name=$JOBNAME" -o jsonpath="{.items[0].status}"`
}

get_failures () {
    FAILURES=`kubectl get jobs -n $namespace -l "job-name=$JOBNAME" -o jsonpath="{.items[0].status.failed}"`
}

namespace="default"
while [ "$1" != "" ]; do
    case $1 in
        -n | --namespace )      shift
                                namespace=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

sleep 1
get_podname
sleep 1
get_status
FAILURES_PREV=0

while [ -z "$STATUS" ];
do
    get_status
    get_failures
    if [ -z "$FAILURES" ]
    then
        if [ "$FAILURES" != "$FAILURES_PREV" ]
        then
            echo "Status - Waiting"
        fi
    else
        if [ "$FAILURES" != "$FAILURES_PREV" ]
        then
            echo "Status - Failed: $FAILURES"
            kubectl -n $namespace logs $PODNAME
            get_podname
        fi
    fi
    FAILURES_PREV=$FAILURES
    sleep .5
done
if [ "$STATUS" == "Failed" ]
then
    echo -n "Failed: "
    get_full_status
    echo "$FULL_STATUS"
    kubectl -n $namespace logs job/$JOBNAME
    exit 1;
fi

echo -n "Success: $STATUS  "
get_full_status
echo "$FULL_STATUS"
kubectl logs -n $namespace job/$JOBNAME
