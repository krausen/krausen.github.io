---
title: "How to setup Nginx as a reverse proxy in GKE"
date: 2021-09-10T15:54:04+02:00
draft: false
---
Before diving in to the specifics of how to set it up in GKE, let's understand what it is we want to achieve and what a reverse proxy is. Put simply, a reverse proxy is a server that redirects clients to the appropriate back end server. The reason for using such an approach are many and here are some:

- **Obscure** the internal architecture of your back end
- **One DNS record**, access all you services from a common URL
- **Load balance** by distributing requests to you back end servers
- **Protect** against denial of service attacks by enforcing rate limits to your clients
- **SSL** encryption can be handled here and ease the load of the application servers

## Configure the Nginx

First of all we need a configuration for the Nginx that we want to deploy. This is done with the ConfigMap resource, this will allow you to mount the content as a file in the container. Since the proxy will be reachable on the internet we want to encrypt the traffic and only allow HTTPS. In this example we have two services, A and B that are running as separate service in our Kubernetes cluster.  To enable the Nginx to resolve host names inside the cluster we need to point it towards the internal DNS `kube-dns.kube-system.svc.cluster.local` .

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configmap
  namespace: default
data:
  nginx.conf: |
    events {
      # This is a required block that is not used
		}

    http {
      server {
        server_name         <DOMAIN NAME>;
        ssl_certificate     /etc/ssl/tls.crt;
        ssl_certificate_key /etc/ssl/tls.key;
        ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers         HIGH:!aNULL:!MD5;
        resolver            kube-dns.kube-system.svc.cluster.local valid=10s;
        listen              8443 ssl;
        error_log           /var/log/nginx/error.log;
        access_log          /var/log/nginx/access.log;

        location ^~ /service_a  {
          set $internal_service_a <SERVICE NAME A>.<NAMESPACE>.svc.cluster.local:<SERVICE A PORT>;
          proxy_set_header Host $host;
          proxy_pass http://${internal_service_a};
        }

        location ^~ /service_b  {
          set $internal_service_b <SERVICE NAME B>.<NAMESPACE>.svc.cluster.local:<SERVICE B PORT>;
          proxy_set_header Host $host;
          proxy_pass http://${internal_service_b};
        }

        location ^~ /health {
          access_log off;
          return 200 "I am well, thank you very much!\n";
          add_header Content-Type text/plain;
        }
      }
    }
```

## Deploy the Nginx

Next we need to create the deployment of the Nginx, notice here that we mount the ConfigMap and secrets to the container. We have not created a secret yet, but we will get to that in a bit. We are exposing port **8443** of the container internally. 

```yaml
---
apiVersion: "apps/v1"
kind: "Deployment"
metadata:
  name: "reverse-proxy"
  namespace: default
  labels:
    app: "reverse-proxy"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: "reverse-proxy"
  template:
    metadata:
      labels:
        app: "reverse-proxy"
    spec:
      containers:
        - name: "reverse-proxy"
          image: "nginx:latest"
          volumeMounts:
            - name: nginx-volume
              mountPath: "/etc/nginx"
              readOnly: true
            - name: nginx-cert
              mountPath: "/etc/ssl"
              readOnly: true
          ports:
            - containerPort: 8443
          livenessProbe:
             httpGet:
               path: /health
               port: 8443
      volumes:
        - name: nginx-volume
          configMap:
            name: nginx-configmap
        - name: nginx-cert
          secret:
            secretName: reverse-proxy-cert
```

## Create the secret

Before we can actually deploy the service we need the certificate and the private key. Creating the actual files is beyond the scope of this post. But given that you have them the command to upload them to k8s is:

```bash
kubectl apply -f nginx.yml
```

## Expose it!

Next we need to expose the service on the internet, this is achieved by creating a LoadBalancer service. This will implicitly create a TCP Network LoadBalancer that forwards the TCP traffic to your Nginx service in k8s. 

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: reverse-proxy-svc
  namespace: deafult
spec:
  type: LoadBalancer
  selector:
    app: reverse-proxy
  ports:
  - protocol: TCP
    port: 443
    targetPort: 8443
```

The IP address of the LoadBalancer is created automatically as an ephemeral address. To make sure that it stays static we need to navigate in the console to **VPC Networks > External IP addresses.** To the far right of the IP address row you will find the button **Reserve** that will make the address static. Take note of the IP address and update your DNS records.

```bash
kubectl create secret tls reverse-proxy-cert --cert=./<DOMAIN NAME>.crt --key=./<DOMAIN NAME>.key --namespace=default
```