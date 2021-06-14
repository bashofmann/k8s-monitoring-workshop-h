## Install local tools

* kubectl
* helm
* k3sup
* linkerd

## SSH into VM

Get private and public key and test connection

```
ssh -i id_rsa root@ip
```

## Install K3S Kubernetes cluster

```
k3sup install \
  --ip <IP> \
  --user root \
  --k3s-channel v1.20 --ssh-key ./id_rsa
export KUBECONFIG=$(pwd)/kubeconfig  
```

Check if cluster works and wait until all Pods are started

```
kubectl get nodes
watch kubectl get pods --all-namespaces
```

## Add the helm repos that we need

```
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io
helm repo add rancher-charts https://charts.rancher.io
helm repo add presslabs https://presslabs.github.io/charts
helm repo add loki https://grafana.github.io/loki/charts
```

## Install Rancher Management Server

First install cert-manager

```
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true \
  --version v1.0.4 --create-namespace
```

Wait until everything is ready

```
kubectl rollout status deployment -n cert-manager cert-manager
kubectl rollout status deployment -n cert-manager cert-manager-webhook
```

Change hostname and install Rancher

```
helm upgrade --install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --version 2.5.8 \
  --set replicas=1 \
  --set hostname=rancher.IP.nip.io  --create-namespace 
```

Wait until everything is ready

```
kubectl rollout status deployment -n cattle-system rancher
```

Go to Settings and change `ingress-ip-domain` to `nip.io`.

## Install Monitoring

```
helm upgrade --install --namespace cattle-monitoring-system rancher-monitoring-crd rancher-charts/rancher-monitoring-crd --create-namespace --wait
helm upgrade --install --namespace cattle-monitoring-system rancher-monitoring rancher-charts/rancher-monitoring --create-namespace \
    --set alertmanager.alertmanagerSpec.resources.requests.memory=50Mi \
    --set alertmanager.alertmanagerSpec.resources.requests.cpu=50m \
    --set prometheus.prometheusSpec.resources.requests.memory=250Mi \
    --set prometheus.prometheusSpec.resources.requests.cpu=300m \
    --set prometheus.prometheusSpec.resources.limits.memory=2500Mi \
    --set k3sServer.enabled=true
```

Deploy Shop

```
kubectl apply -f scrape-custom-service/01-demo-shop.yaml
```

Update redis to add exporter

```
kubectl apply -f scrape-custom-service/02-redis-prometheus-exporter.yaml
```

Add ServiceMonitor

```
kubectl apply -f scrape-custom-service/03-redis-servicemonitor.yaml
```

Add Grafana Dashboard

```
kubectl apply -f scrape-custom-service/04-redis-grafana-dashboard.yaml
```

Add Prometheus Rule

```
kubectl apply -f scrape-custom-service/05-redis-prometheus-rules.yaml
```

## MySQL Operator

```
helm upgrade --install mysql-operator presslabs/mysql-operator --namespace mysql-operator \
    --set serviceMonitor.enabled=true --create-namespace \
    --set orchestrator.persistence.enabled=false
```

Add cluster

```
kubectl apply -f scrape-custom-service/06-mysql-cluster.yaml
```

Add Grafana Dashboard

```
kubectl apply -f scrape-custom-service/07-mysql-rules.yaml
```

Add Prometheus Rule

```
kubectl apply -f scrape-custom-service/08-mysql-grafana-dashboard.yaml
```

## Install logging

```
helm upgrade --install --namespace cattle-logging-system rancher-logging-crd rancher-charts/rancher-logging-crd --create-namespace --wait
helm upgrade --install --namespace cattle-logging-system rancher-logging rancher-charts/rancher-logging --create-namespace
```

## Install Loki

```
helm upgrade --install loki loki/loki --namespace loki --version 2.1.1 --create-namespace
```

Setup logging flow and output

```
kubectl apply -f logging/logging-cluster-flow.yaml
```

Setup Grafana datasource

```
kubectl apply -f logging/datasource.yaml
kubectl rollout restart deployment -n cattle-monitoring-system rancher-monitoring-grafana
```

Log into Grafana with admin/prom-operator

## Install Istio

```
helm upgrade --install --namespace istio-system rancher-kiali-server-crd rancher-charts/rancher-kiali-server-crd --create-namespace --wait
helm upgrade --install --namespace istio-system rancher-istio rancher-charts/rancher-istio --create-namespace --set tracing.enabled=true
```

## Inject istio proxies into pods

```
kubectl label namespace default istio-injection=enabled
kubectl delete pod -n default --all
```