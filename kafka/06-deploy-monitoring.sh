#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Prometheus
cat $DIR/monitoring/prometheus.yaml | sed -e "s/namespace: .*/namespace: $NAMESPACE/;s/regex: myproject/regex: $NAMESPACE/" > $DIR/monitoring/prometheus-deploy.yaml

oc apply -f $DIR/monitoring/alerting-rules.yaml -n $NAMESPACE
oc apply -f $DIR/monitoring/prometheus-deploy.yaml -n $NAMESPACE
rm $DIR/monitoring/prometheus-deploy.yaml
oc apply -f $DIR/monitoring/alertmanager.yaml -n $NAMESPACE
oc expose service/prometheus -n $NAMESPACE

echo "Waiting for Prometheus server to be ready..."
oc rollout status deployment/prometheus -w -n $NAMESPACE
oc rollout status deployment/alertmanager -w -n $NAMESPACE
echo "...Prometheus server ready"

# Preparing Grafana datasource and dashboards

# build the Kafka dashboard
cp $DIR/monitoring/dashboards/strimzi-kafka.json $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json

# build and POST the Zookeeper dashboard to Grafana
cp $DIR/monitoring/dashboards/strimzi-zookeeper.json $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

oc create configmap grafana-config \
    --from-file=datasource.yaml=$DIR/monitoring/dashboards/datasource.yaml \
    --from-file=grafana-dashboard-provider.yaml=$DIR/monitoring/grafana-dashboard-provider.yaml \
    --from-file=strimzi-kafka-dashboard.json=$DIR/monitoring/dashboards/strimzi-kafka-dashboard.json \
    --from-file=strimzi-zookeeper-dashboard.json=$DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json \
    -n $NAMESPACE

rm $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
rm $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

# Grafana
oc apply -f $DIR/monitoring/grafana.yaml -n $NAMESPACE
oc expose service/grafana -n $NAMESPACE

#echo "Waiting for Grafana server to be ready..."
oc rollout status deployment/grafana -w -n $NAMESPACE
echo "...Grafana server ready"