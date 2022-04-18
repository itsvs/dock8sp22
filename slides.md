---
title: Docker/Kubernetes (CS 198)
author: Vanshaj Singhania
date: 2022-04-20
styles: {style: solarized-dark}
extensions: [terminal, file_loader]
---

# Introduction to Docker: Motivation

> Docker is a set of the platform-as-a-service products that use OS-level
> virtualization to deliver software in packages called containers.
>
> -- Wikipedia

In English: Docker is a tool that allows you to "containerize" your code and
run it in reproducible environments across multiple devices/OSes/hardwares. This
helps eliminate the problem of "it works on my computer," by allowing developers
to emulate the production environment on their systems (in fact, you can even
ship your production environment as a Docker container -- more on this later).

Take the following Python program:

```file
path: docker_demo/server.py
lang: python
```

If I run this locally, I get different results than someone running, say,
Windows:

```terminal-ex
command: zsh -f
rows: 7
init_text: python docker_demo/server.py
init_wait: '(env) $(build_prompt) '
init_codeblock: false
```

```terminal-ex
command: zsh -f
rows: 3
init_text: curl http://localhost:3000
init_wait: '(env) $(build_prompt) '
init_codeblock: false
```

---

# Introduction to Docker: Container Daemon

That example is not particularly catastrophic, but what happens when you have to
deal with differing filesystems or OS-level functionality?

Your computer is capable of virtualizing other operating systems (think: VMware,
Virtualbox, QEMU, etc.). `containerd`, the industry-standard container runtime,
leverages this capability to manage "containers."
![https://containerd.io/img/architecture.png](https://containerd.io/img/architecture.png)

`containerd` manages the _entire_ container lifecycle, serving as the middleware
between the host system itself and the platform that hosts your applications
(like Docker)! Specifically, it handles the creation/transfer/storage of
"images," execution/supervision of containers, low-level storage, network and
device attachments, etc.

---

# Introduction to Docker: Images

To containerize our applications, we first pick a base operating system, such as
Debian.

On top of that base, we build an **image**: a snapshot containing everything in
addition to the base OS that we need in order to run our application. This
includes installing any dependencies (such as `flask`, or even Python itself),
copying any code files (such as `server.py`), and specifying the command to run
when the image is executed.

```file
path: docker_demo/deb.Dockerfile
lang: Dockerfile
```

To build an image, we use `docker build [OPTIONS] PATH | URL | -`:
- `-t image-name` will name our built image `image-name`
- `-f dockerfile-name` will point out the Dockerfile with the build instructions
  - You only need this argument if the file is not named `Dockerfile`
- `PATH` specifies the "build context," which files can be accessed during build

```terminal-ex
command: zsh -f
rows: 10
init_text: docker build -t server/debian -f docker_demo/deb.Dockerfile docker_demo
init_wait: '(env) $(build_prompt) '
init_codeblock: false
```

---

# Introduction to Docker: Pre-Built Images

Often, pre-built images help us avoid installing things like Python (which
sometimes takes a while). You can find these on
[Docker Hub](https://hub.docker.com/).

```file
path: docker_demo/py.Dockerfile
lang: Dockerfile
```

The command to build remains unchanged, expect the Dockerfile name:

```terminal-ex
command: zsh -f
rows: 10
init_text: docker build -t server/python -f docker_demo/py.Dockerfile docker_demo
init_wait: '(env) $(build_prompt) '
init_codeblock: false
```

---

# Introduction to Docker: Containers

When we execute an image, it becomes a **container**: the container runs the
command we specified before, and allows to attach various things to it as
needed (**volumes** to link local files/folders to the container, **environment
variables**, **ports** to access the application running in the container from
the host machine, etc.).

To run a container, we use `docker run [OPTIONS] IMAGE [COMMAND] [ARG...]`:
- `-it` will make the container interactive and give us a pseudo-TTY
  - the "opposite" is `-d`, which will run the container in the background
- `-p des:src` will forward the container's `src` port to the host's `des` port
- `IMAGE` should be the name of the image we want to run

```terminal-ex
command: zsh -f
rows: 10
init_text: docker run -it -p 8000:3000 server/debian
init_wait: '(env) $(build_prompt) '
init_codeblock: false
```

Now, we can access the Flask app inside the container just as before!

```terminal-ex
command: zsh -f
rows: 3
init_text: curl http://localhost:8000
init_wait: '(env) $(build_prompt) '
init_codeblock: false
```

---

# Introduction to Docker: 61A Development

On 61A staff, in an effort to avoid platform-specific build issues, we use
containers to develop on the website and on software. This doesn't solve _all_
issues, but it helps solve random one-off versioning issues. Our Dockerfile:

```file
path: docker_demo/61a.Dockerfile
lang: Dockerfile
```

---

# Bridge: Microservices

## The Idea

Historically, organizations have had servers that would run _everything_: the
application database, the backend framework/API for the application, and the
frontend/UI server for the application... for every application. Often, they
would have multiple instances of the backend/frontend running in order to cater
to scaling demand.

Lately, this model has shifted towards the idea of **microservices**: each
component (database, backend, frontend) is such a service, and is managed/run
independently. Generally, each component would run in its own Docker container,
and would use the exact amount of resources that it would need to complete any
action.

## Pros

One upside here is that your components can be updated independently (say you
want to update your backend service -- your frontend can remain completely
unaffected). Another (major!) upside is that each component can only interact
with other components in ways that you define -- essentially, this leads to a
secure infrastructure setup, as exploiting a vulnerability in the frontend is
less likely to give you uncontrolled access to the backend.

## Cons

Importantly, a single Docker container only contains one microservice and with
enough bandwidth to handle one request at a time. This means that you need N
containers if you split your application into N microservices, and even that
will only allow you to serve one request at a time. If you wish to scale up to,
say, 1000 concurrent requests, you need N*1000 containers.

This is not impossible, but is hard to manage. The most obvious solution is to
write a series of scripts to manage this for you, but then these scripts can end
up lacking features or needing continual maintenance. What if you add a new
microservice? What if your backend needs twice as much bandwidth as the frontend
(alternatively, what if this relative demand changes)?

## Solution

This is where Kubernetes comes in.

---

# Introduction to Kubernetes

> Kubernetes is an open-source container orchestration system for automating
> software deployment, scaling, and management.
>
> -- Wikipedia

In English: Kubernetes is a system that helps _orchestrate_ large numbers of
containers that make up some scalable cloud application.

## Architecture

Every Kubernetes system is called a **cluster**. Each cluster consists of many
machines, called **nodes**. These nodes are managed by the **control plane**.

### Control Plane
The control plane is the orchestrator that cluster maintainers interact with in
order to deploy and manage services.

The control plane contains various important components:
- `etcd`, a persistent key-value store of important control-related information
- `c-m` (controller manager), the (set of) process(es) that responds to requests and state changes (such as crashes)
- `sched` (scheduler), watches for differences between the current state of the server and the desired state, and resolves these differences
- `api` (API server), the frontend for the control plane, scaled horizontally

### Nodes
These are the machines that actually host the deployed applications.

Each node contains components to interact with the control plane:
- `kubelet`, which ensures that containers are running as expected (this is what the control plane interfaces with)
- `kube-proxy`, which connects running containers to networks within and outside of the cluster as desired

Each node also has a **container runtime**, such as `containerd`, which actually
runs containers.

If you want to scale up an entire cluster, you can do so by adding or removing
nodes.

---

# Introduction to Kubernetes: What's in a Node?

Stepping back from individual nodes, let's discuss the framework of a Kubernetes
cluster.

## Workloads

An application running on Kubernetes is known as a workload. This consists of
all the components of a single application (think: frontend, backend, database,
etc.).

## Pods

A pod represents a set of running containers on your cluster. Each workload is
run inside of a set of pods. Pods are the smallest deployable units of computing
that you can create and manage in Kubernetes.

Specifically, a pod can represent a single container, or multiple. All of the
containers in a pod are run together ("co-located"), so this is the smallest
unit of isolation. Most commonly, a pod will only consist of one container for
this reason.

Whenever a pod is created, it is scheduled to run on a node. The pod remains on
this node until one of the following conditions is met:
- the pod finishes execution
- the pod is deleted
- the pod is evicted (i.e. the node doesn't have the resources to run it)
- the node on which the pod is running fails

## Deployments

So far, we've solved the problem of orchestrating many microservices for an
application, but not the problem of ensuring concurrent availability. If a pod
or a node fails, the pod or node must be restarted, which means that your server
would face downtime while this happens. We generally expect Kubernetes to
provide **high availability** (i.e. zero downtime), so we need a solution.

Workloads provide resources, one of which is a Deployment: a declarative system
in which we describe a desired state and the deployment controller (one of the
control plane's `c-m` controllers) changes the actual state to match this.

How does this help?

## ReplicaSets

A ReplicaSet is designed to maintain a stable set of replica pods -- that is, if
we define what we want our ReplicaSet to look like (such as with a **pod
template**), the ReplicaSet will be replicated a specified number of times at
any given time. If any of the replicas fail, traffic will be routed to a healthy
replica, and the failed replica will be asynchronously replaced. No downtime!

---

# Introduction to Kubernetes: Okpy Backend

Here's a truncated version of the Okpy backend (worker) deployment rules:

```file
path: k8s_demo/ok-worker.yaml
lang: yaml
```

> Full version: https://github.com/okpy/ok/blob/master/kubernetes/ok-worker.yaml

---

# Introduction to Kubernetes: Okpy Frontend

Here's a truncated version of the Okpy frontend (web) deployment rules:

```file
path: k8s_demo/ok-web.yaml
lang: yaml
```

> Full version: https://github.com/okpy/ok/blob/master/kubernetes/ok-web-deployment.yaml

---

# Introduction to Kubernetes: Deploying Okpy

Okpy is run on Google Kubernetes Engine. The way that we build and deploy this
is as follows:

```bash
$ git clone git@github.com:okpy/ok && cd ok
$ docker build -t cs61a/ok-server:latest .
$ docker push cs61a/ok-server:latest
$ kubectl set image deployment/ok-web-deployment ok-v3-deploy=cs61a/ok-server:latest
$ kubectl rollout status deployment/ok-web-deployment
$ kubectl set image deployment/ok-worker-deployment ok-v3-worker=cs61a/ok-server:latest
$ kubectl rollout status deployment/ok-worker-deployment
```

And here's what the resulting cluster looks like:

```bash
$ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
ok-web-deployment-675df678d5-jfrzr       1/1     Running   20         76d
ok-web-deployment-675df678d5-q9hn2       1/1     Running   15         76d
ok-worker-deployment-5bc58f8b98-4ftqk    1/1     Running   0          76d
ok-worker-deployment-5bc58f8b98-k89bt    1/1     Running   0          76d
ok-worker-deployment-5bc58f8b98-wcl6z    1/1     Running   0          76d
```

What does this tell us?
- the last deploy was 76 days ago
- the worker replicas have never crashed since then
- one web replica has crashed 20 times and the other has crashed 15 times
- all replicas are running and ready.

> Full deploy script: https://github.com/okpy/ok/blob/master/kubernetes/deploy.sh

Let's see what the Okpy deployment looks like on Google Kubernetes Engine.

---

# Introduction to Kubernetes: Recap

Layers of Abstraction:
- Deployment: manages ReplicaSets
- ReplicaSet: creates and manages Pods
- Pod: the basic unit of Kubernetes
- Node Cluster:
  - Control Plane: directs Worker Nodes
  - Worker Nodes: machines that host Pods
- Node Processes:
  - Control Plane:
    - API server: the hub
    - `etcd`: key-value store for cluster information
    - Scheduler: self-explanatory
    - Controller Manager: controls the cluster
  - Worker Nodes:
    - `kubelet`: the brain of the node
    - `kube-proxy`: the "traffic cop"
    - Container Runtime: runs containers (Docker, `containerd`)
- Container: where the code runs

Source: https://towardsdatascience.com/key-kubernetes-concepts-62939f4bc08e

# Google's K8s Comic

https://cloud.google.com/kubernetes-engine/kubernetes-comic/

# Things We Didn't Discuss

An incomprehensive list of concepts that we glazed over or didn't discuss:

- Docker
  - Compose
  - Stacks/Swarm
  - Networks/Secrets
  - Services
  - Volumes
- Kubernetes
  - `kubectl`
  - DNS Management
  - Networks/Secrets
  - Services: access points for Pods
  - Volumes: data storage/disk access
  - DaemonSet: a monitoring pod deployed to each node
  - StatefulSet: ReplicaSet but for stateful processes, like databases
  - Jobs: a batch that requires a container to run to completion
  - CronJobs: scheduled/repeating Jobs

---

# Questions? Comments?

That's all I've got! Thanks for stopping by :)

Feel free to submit anonymous feedback at https://imvs.me/t/anon, or
non-anonymous feedback via email.
