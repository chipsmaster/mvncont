# mvncont

A custom maven container utility based on the official maven image.

## Setup

* Download or clone this somewhere
* Make `mvncont.sh` available in $PATH (optional) : `sudo ln -srv mvncont.sh /usr/local/bin/`

## Usage

* Place yourself in a maven project folder : `cd ~/projects/x`
* Run `mvncont.sh` from this folder, the arguments will be the command to run inside the container, examples:
    * `mvncont.sh mvn --version`
    * `mvncont.sh bash`
    * `mvncont.sh mvn clean install`

The script will :

* Create a docker image based on the official maven image if not done yet ; the image will include a normal user that maps directly to your current user
* Create a docker volume to hold maven user data (~/.m2) if not done yet
* Run a container with the custom image where the current directory is mounted in `/var/project`. The container is destroyed in the end

### Config

A config file is read (if exists) from where you run the script: `.mvncont` ; it is a shell script where you can override some variables (non exhaustive list):

* `project`: a name that will be included in the used volume name. You may set a different name here for each project (particularly if different maven versions are used), or may use the same name to avoid downloading dependencies each time.
* `base_container_tag`: base tag from the official maven image

sample:
```
project=mymvnproject
base_container_tag=latest
```

Another file is read to override config once again: `.mvncont.local`

### Special commands

If the script arguments are one of these, it will do special actions,and not run a command inside the container

* `build`: rebuilds the docker image
* `reset`: remove the volume (next execution will recreate it)

