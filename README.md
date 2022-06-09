# Sample Mojo App

This repo is to show the sample codes of Mojo App development, and using VS Code
remote container as development environment.

## Install dependencies

Using carton with local 'darkpan' server:

    PERL_CARTON_MIRROR=http:///u1710.lan:8302/ carton install

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
    git remote add live apps-repo@openhab:moj-full-sample.git

Push the **main** branch to production server by:

    git push live main

After that, the hook script will update the deployment folder automatically.




