#!/bin/bash
JOBNAME=@option.JOBNAME@

get_podname () {
    PODNAME=`kubectl get pods -l "job-name=$JOBNAME" --sort-by="{.metadata.creationTimestamp}" | tail -1 | cut -f1 -d' '`
}
get_status () {
    STATUS=`kubectl get jobs -l "job-name=$JOBNAME" -o jsonpath="{.items[0].status.conditions[0].type}"`
}
get_full_status () {
    FULL_STATUS=`kubectl get jobs -l "job-name=$JOBNAME" -o jsonpath="{.items[0].status}"`
}

get_failures () {
    FAILURES=`kubectl get jobs -l "job-name=$JOBNAME" -o jsonpath="{.items[0].status.failed}"`
}


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
            kubectl logs $PODNAME
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
    kubectl logs job/$JOBNAME
    exit 1;
fi

echo -n "Success: $STATUS  "
get_full_status
echo "$FULL_STATUS"
kubectl logs job/$JOBNAME
