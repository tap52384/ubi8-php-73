# ubi8-php-73

## Docker

### Install Prerequisites (macOS)

> You do not need openshift-cli if you are not hosting your code via OpenShift.

```bash
# 0. Get Homebrew (https://brew.sh) if you don't have it already and install
# what's needed for this to work
cd ~
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install openshift-cli
brew install source-to-image

# 0a. If you get an error that your version of macOS is too old for Homebrew to
# work properly, you can download the required binaries (openshift-cli,
# source-to-image) from here:
# https://docs.openshift.com/container-platform/3.11/cli_reference/get_started_cli.html#cli-mac
# https://github.com/openshift/source-to-image/releases
cd ~
curl -L -o ./s2i.tar.gz -k https://github.com/openshift/source-to-image/releases/download/v1.2.0/source-to-image-v1.2.0-2a579ecd-darwin-amd64.tar.gz
tar -xvf ~/s2i.tar.gz
cp -fv ~/s2i /usr/local/bin/
rm -f ~/s2i ~/sti ~/s2i.tar.gz
chmod u+x /usr/local/bin/s2i
```

### Build the Docker Image (macOS)

```bash
# You can build the image without having to clone the repository locally
# Uses the "master" branch for building the image
mkdir -p ~/code
cd ~/code
docker build --pull https://github.com/tap52384/ubi8-php-73.git -t tap52384:ubi8-php-73

# Next, "re-build" the app using s2i (source-to-image)
git clone -q https://github.com/tap52384/c-and-j-towing.git
s2i build -e DOCUMENTROOT=/public/ ~/code/c-and-j-towing/ tap52384:ubi8-php-73 tap52384:c-and-j-towing

# Stop and delete any containers based on the RedHat image
docker rm -f $(docker ps -aq --filter ancestor=registry.access.redhat.com/ubi8/php-73 --format="{{.ID}}") || true

# Create the container "towing" with the code folder mounted
docker run \
--name towing \
-e USER=$(whoami) \
--hostname $(hostname) \
-d \
-p 8080:8080 \
-v ~/code/c-and-j-towing:/opt/app-root/src/ \
tap52384:c-and-j-towing
```
