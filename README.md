# Sample Mojo App

This repo is to show the sample codes of Mojo App development, and using VS Code
remote container as development environment.

## Install dependencies

Using carton with local 'darkpan' server:

```
# cd $app_folder
docker run --rm -it -v `pwd`:/app -w /app \
    -e PERL_CARTON_MIRROR=http:///u1710.lan:8302 \
    perl-devel:5.32.1 carton install
```
## GIT automated deployment setup

Assume deploy to local Pi4 box as production host.

### Production host setup

At production host, create a bare git repository:

    git init --bare /home/apps-repo/mojo-full-sample.git

Create deployment folder structure:

    mkdir -p /opt/apps/mojo-full-sample
    chown -R apps-repo /opt/apps/mojo-full-sample

Add the **post-receive** hook script by copying the `post-receive` file to `/home/apps-repo/mojo-full-sample.git/hooks`
This file will update the production app folder with up to date files. Make it executable:

    chmod u+x /home/apps-repo/mojo-full-sample.git/hooks/post-receive

### Developer workstation side

Assume production code is in **main** branch.

Add a **live** upstream to the working tree:

    cd ~/mojo-full-sample
    git remote add live apps-repo@openhab:mojo-full-sample.git

Push the **main** branch to production server by:

    git push live main

After that, the hook script will update the deployment folder automatically.


### Create the production container:

```
docker stop mojo-app
docker rm mojo-app

docker run -d --name mojo-app \
  -e APP_PORT=3000 \
  --network=host \
  -v /opt/apps/mojo-full-sample:/app \
  --log-driver=loki:latest \
  --log-opt loki-url="http://10.1.99.16:3100/loki/api/v1/push" \
  --log-opt loki-retries=5 \
  --log-opt loki-batch-size=400 \
  --log-opt loki-external-labels="container_name=mojo-app" \
  --restart=unless-stopped \
  perl-devel:5.32.1 /app/start

```

## Standalone Docker image deployment

This method will bundle the App code and all dependencies in a single image for deployment.

### Build

Use the `Dockerfile.runtime`:

    docker build -f Dockerfile.runtime -t mojo-app:latest .
    docker image tag mojo-app:latest michaelfung/mojo-app:0.1
    docker image push michaelfung/mojo-app:0.1

### Deploy

At the production server:

```
docker run -d --name mojo-app \
  -e APP_PORT=3000 \
  --network=host \
  --restart=unless-stopped \
  michaelfung/mojo-app:0.2

```

With loki support:

```
docker run -d --name mojo-app \
  -e APP_PORT=3000 \
  --network=host \
  --log-driver=loki:latest \
  --log-opt loki-url="http://10.1.99.16:3100/loki/api/v1/push" \
  --log-opt loki-retries=5 \
  --log-opt loki-batch-size=400 \
  --log-opt loki-external-labels="container_name=mojo-app" \
  --restart=unless-stopped \
  michaelfung/mojo-app:0.2

```

