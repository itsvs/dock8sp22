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