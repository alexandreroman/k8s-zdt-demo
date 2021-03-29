# Deploy apps to Kubernetes with zero downtime

This project shows how to deploy an app to a Kubernetes cluster with no
downtime.

Using this project, you will deploy a Spring Boot app exposing this
REST endpoint:
```java
@RestController
class ZDT {
    @GetMapping("/")
    String zeroDowntime() {
        return "V1";
    }
}
```

There are two versions of this app:
 - `alexandreroman/k8s-zdt-demo:v1` returning `"V1"`
 - `alexandreroman/k8s-zdt-demo:v2` returning `"V2"`

## Deploy this app to Kubernetes

Use these [Kubernetes descriptors](k8s) to deploy app `V1`:
```bash
$ kubectl apply -f k8s
namespace/zdt created
deployment.apps/zdt created
service/app-lb created
```

Monitor app deployment using this command:
```bash
$ kubectl -n zdt rollout status deployment/zdt
Waiting for deployment "zdt" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "zdt" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "zdt" rollout to finish: 2 of 3 updated replicas are available...
deployment "zdt" successfully rolled out
```

Check that all pods/services are up and running:
```bash
NAME                       READY   STATUS    RESTARTS   AGE
pod/zdt-594f4794f5-8s5cg   1/1     Running   0          90s
pod/zdt-594f4794f5-ns24b   1/1     Running   0          90s
pod/zdt-594f4794f5-q996p   1/1     Running   0          90s

NAME             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/app-lb   LoadBalancer   10.98.101.201   localhost     80:32045/TCP   90s

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/zdt   3/3     3            3           90s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/zdt-594f4794f5   3         3         3       90s
```

This app is now available:

```bash
$ curl localhost
V1%
```

Kubernetes is using healthcheck endpoints to monitor app readiness:
```bash
$ curl localhost/actuator/health
{"status":"UP"}%
```

This healthcheck is defined in the deployment descriptor:
```yaml
containers:
  - name: app
    image: alexandreroman/k8s-zdt-demo:v1
    ports:
    - containerPort: 8080
    livenessProbe:
    httpGet:
        port: 8080
        path: /actuator/health
    initialDelaySeconds: 30
    readinessProbe:
    httpGet:
        port: 8080
        path: /actuator/health
    initialDelaySeconds: 10
```

When this endpoint is not available from an app instance, Kubernetes
will not expose this pod to the load balancer. Kubernetes
makes sure there are enough running pods at any time.

## Roll out new app version

Run this command to edit app deployment descriptor:
```bash
$ kubectl -n zdt edit deployment zdt
deployment.extensions/zdt edited
```

Find the Docker image reference `alexandreroman/k8s-zdt-demo:v1`, and
change it to `alexandreroman/k8s-zdt-demo:v2`:
```yaml
image: alexandreroman/k8s-zdt-demo:v1
# change to V2
image: alexandreroman/k8s-zdt-demo:v2
```

Monitor app `V2` deployment:
```bash
$ kubectl -n zdt rollout status deployment/zdt
Waiting for deployment "zdt" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "zdt" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "zdt" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "zdt" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "zdt" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "zdt" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "zdt" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "zdt" rollout to finish: 1 old replicas are pending termination...
deployment "zdt" successfully rolled out
```

While the new app version is being deployed, the old version is still
available. If you hit the app endpoint while the new version is being
deployed, you may see two versions running at the same time: `V1` and
`V2`. Kubernetes is gradually stopping old pods as new pods are seen
as ready.

You may also edit the Kubernetes descriptor to point at the new app
version, in [zdt-02-deployment.yml](k8s/zdt-02-deployment.yml):
```yaml
containers:
  - name: app
    image: alexandreroman/k8s-zdt-demo:v2
```

Then, you need to update your Kubernetes deployment:
```bash
$ kubectl apply -f k8s
namespace/zdt unchanged
deployment.apps/zdt configured
service/app-lb unchanged
```

## Roll back to previous version

Using this command, you can rollback to the previously deployed app
version:
```bash
$ kubectl -n zdt rollout undo deployment/zdt
deployment.extensions/zdt rolled back
```

## Contribute

Contributions are always welcome!

Feel free to open issues & send PR.

## License

Copyright &copy; 2021 [VMware, Inc. or its affiliates](https://vmware.com).

This project is licensed under the [Apache Software License version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
