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

# Grafana
oc apply -f $DIR/monitoring/grafana.yaml -n $NAMESPACE
oc expose service/grafana -n $NAMESPACE

echo "Waiting for Grafana server to be ready..."
oc rollout status deployment/grafana -w -n $NAMESPACE
echo "...Grafana server ready"
sleep 2

# get Grafana route host for subsequent cURL calls for POSTing datasource and dashboards
GRAFANA_HOST_ROUTE=$(oc get routes grafana -o=jsonpath='{.status.ingress[0].host}{"\n"}' -n $NAMESPACE)

# POST Prometheus datasource configuration to Grafana
curl -X POST http://admin:admin@${GRAFANA_HOST_ROUTE}/api/datasources -d @$DIR/monitoring/dashboards/datasource.json --header "Content-Type: application/json"

# build and POST the Kafka dashboard to Grafana
$DIR/monitoring/dashboards/dashboard-template.sh $DIR/monitoring/dashboards/strimzi-kafka.json > $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json

curl -X POST http://admin:admin@${GRAFANA_HOST_ROUTE}/api/dashboards/db -d @$DIR/monitoring/dashboards/strimzi-kafka-dashboard.json --header "Content-Type: application/json"

# build and POST the Zookeeper dashboard to Grafana
$DIR//monitoring/dashboards/dashboard-template.sh $DIR/monitoring/dashboards/strimzi-zookeeper.json > $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

curl -X POST http://admin:admin@${GRAFANA_HOST_ROUTE}/api/dashboards/db -d @$DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json --header "Content-Type: application/json"

rm $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
rm $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json