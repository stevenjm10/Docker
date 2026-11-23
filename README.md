# Docker – Simple Exercise

A minimal exercise that shows how to **package an application in a Docker image** and **run it as isolated containers**.

The application is a tiny HTTP server written in Go. It answers with a greeting, the container's hostname and the current time, and has a `/health` endpoint.

## What is Docker?

Docker is an open-source platform to build, ship and run applications inside **containers**. A container bundles the application with everything it needs (runtime, libraries, configuration), so it runs the same way on any machine with Docker. Containers share the host's kernel and isolate processes using Linux **namespaces** and **cgroups**, which makes them much lighter and faster to start than virtual machines.

Key concepts used in this exercise:

| Concept | Meaning |
|---------|---------|
| **Dockerfile** | Text file with the steps to build an image |
| **Image** | Read-only template made of layers (`hello-docker:1.0`) |
| **Container** | A running instance of an image |
| **Port mapping** | `-p HOST:CONTAINER` publishes a container port on the host |
| **Environment variable** | `-e PORT=9000` configures the container without rebuilding |
| **Multi-stage build** | Compile in one image, ship only the result in a smaller one |

## Project structure

```
Docker/
├── main.go        # HTTP server (routes "/" and "/health")
├── go.mod
├── Dockerfile     # Multi-stage build: golang:1.22-alpine -> scratch
├── .dockerignore  # Files excluded from the build context
└── README.md
```

## The Dockerfile

```dockerfile
# ---------- Stage 1: build ----------
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -o /app main.go

# ---------- Stage 2: run ----------
FROM scratch
COPY --from=build /app /app
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app"]
```

- **Stage 1** uses an image that has the Go compiler and builds a static binary.
- **Stage 2** starts from `scratch` (an empty image) and copies only the binary. The final image is about **4.6 MB**, with no shell or extra packages, which also reduces the attack surface.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) (Docker Desktop on Windows/macOS or Docker Engine on Linux)
- Go is **not** required on your machine: it is only used inside the build stage.

## Step by step

```bash
# 1. Clone the repository
git clone https://github.com/stevenjm10/Docker.git
cd Docker

# 2. Build the image
docker build -t hello-docker:1.0 .

# 3. Run two containers from the same image on different host ports
docker run -d --name web1 -p 8080:8080 hello-docker:1.0
docker run -d --name web2 -p 8081:8080 hello-docker:1.0

# 4. Run a third one listening on another port via an environment variable
docker run -d --name web3 -p 9000:9000 -e PORT=9000 hello-docker:1.0

# 5. Test them
curl http://localhost:8080
curl http://localhost:8081
curl http://localhost:8080/health
curl http://localhost:9000/health

# 6. Inspect
docker ps
docker images hello-docker
docker logs web1

# 7. Clean up
docker rm -f web1 web2 web3
```

On Windows you can open the URLs in the browser instead of using `curl`.

## Expected output

```
$ curl http://localhost:8080
Hello from a Docker container
Container (hostname): 12d38794d35e
Time: 2026-11-23T22:25:05Z

$ curl http://localhost:8081
Hello from a Docker container
Container (hostname): 0ffeab6c50e4
Time: 2026-11-23T22:25:05Z

$ curl http://localhost:8080/health
OK

$ docker ps
NAMES   IMAGE              PORTS                              STATUS
web3    hello-docker:1.0   8080/tcp, 0.0.0.0:9000->9000/tcp   Up 2 seconds
web2    hello-docker:1.0   0.0.0.0:8081->8080/tcp             Up 2 seconds
web1    hello-docker:1.0   0.0.0.0:8080->8080/tcp             Up 2 seconds

$ docker images hello-docker
IMAGE              ID             DISK USAGE   CONTENT SIZE
hello-docker:1.0   866506dfc3a6   12.8MB       4.62MB

$ docker logs web1
2026/11/23 22:25:03 Server listening on :8080
```

Hostnames (container IDs) and times will be different on your machine.

## What this exercise demonstrates

- **Portability:** the same image runs on any host with Docker, without installing Go.
- **Isolation:** each container has its own hostname and network; all of them listen on port 8080 internally without conflicts.
- **Port mapping:** `-p 8081:8080` exposes the container's port 8080 on host port 8081.
- **Configuration:** `-e PORT=9000` changes the listening port without rebuilding the image.
- **Small images:** the multi-stage build produces an image of about 4.6 MB of content.
- **Fast startup:** containers start in under a second.

## Useful commands

| Command | Purpose |
|---------|---------|
| `docker build -t name:tag .` | Build an image from the Dockerfile |
| `docker images` | List local images |
| `docker run -d -p 8080:8080 image` | Start a container in the background |
| `docker ps` / `docker ps -a` | List running / all containers |
| `docker logs <container>` | Show a container's output |
| `docker stop <container>` | Stop a container |
| `docker rm -f <container>` | Remove a container |
| `docker rmi <image>` | Remove an image |

## Author

Steven Morales
