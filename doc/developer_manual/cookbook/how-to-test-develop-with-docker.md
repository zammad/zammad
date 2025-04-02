# How to test the development version of Zammad via Docker

Docker is a container-based software framework for automating deployment of applications.
Our Docker image is a **single container** based application designed to have Zammad **up and running fast for testing
purposes**.

Please note that this is a non persistent storage container and **all Zammad data is lost** when you're stopping the
container.

## Requirements

- Docker environment needs to be up and running
- at least 4 GB of RAM to run the container

## Docker container

Docker `run` will run a command in a new container, `-i` attaches stdin and stdout, `-t` allocates a tty.

### Step 1

Run the container:

```sh
docker container run -ti --rm --name zammad -p 80:80 zammad/zammad
```

### Step 2

Set `vm.max_map_count` for Elasticsearch:

```sh
sysctl -w vm.max_map_count=262144
```

> **_Tip for Mac OS:_** [zammad/zammad-docker/issues/27](https://github.com/zammad/zammad-docker/issues/27#issuecomment-455171752)

---

That's it! You're now using a bash shell inside of a Zammad docker container using the develop branch of our GitHub repo.

To disconnect or detach from the shell without exiting, use the escape sequence `Ctrl-p` + `Ctrl-q`.

### Open Zammad

Go to [http://localhost](http://localhost) and you'll see:

- "Welcome to Zammad!", there you need to create your admin user.
