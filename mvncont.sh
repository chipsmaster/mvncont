#/bin/bash

set -e

setup_image() {
	existing_image_id=$(docker images "$image" --format '{{.ID}}')
	if [ -z "$existing_image_id" ] || [ "$action" = build ]
	then
		docker build -t "$image" \
			--build-arg "parent_tag=$base_container_tag" \
			--build-arg "host_uid=$host_uid" \
			--build-arg "host_gid=$host_gid" \
			--build-arg "normaluser=$container_normaluser" \
			- <<'DockerfileEND'

ARG parent_tag
FROM maven:$parent_tag
ARG host_uid
ARG host_gid
ARG normaluser

ENV PROJECT_DIR /var/project

# These are for parent container entrypoint
ENV USER_HOME_DIR "/home/$normaluser"
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Init normaluser home
RUN groupadd --gid $host_gid $normaluser \
	&& useradd --uid $host_uid --gid $host_gid --create-home $normaluser \
	&& echo "cd $PROJECT_DIR" >> "$USER_HOME_DIR/.bashrc" \
	&& mkdir "$MAVEN_CONFIG" && chown "$normaluser:" "$MAVEN_CONFIG"


DockerfileEND

	fi
}


setup_volume() {
	existing_volumes=$(docker volume ls -f "name=$volume_name" --format '{{.Name}}')
	if [ -z "$existing_volumes" ]
	then
		docker volume create "$volume_name"
	fi
}


# Variables to change in .mvncont eventually
project=mvn
base_container_tag=3.6
host_uid=$(id -u)
host_gid=$(id -g)
container_normaluser=mvnuser
volume_name=

if [ -f .mvncont ]
then
	source .mvncont
fi
if [ -f .mvncont.local ]
then
        source .mvncont.local
fi


image_tag="$base_container_tag-$host_uid-$host_gid-$container_normaluser"
image="chipsmaster/mvncont:$image_tag"

if [ -z "$volume_name" ]
then
	volume_name="mvncont_vol_$project"
fi

if [ $# = 0 ]
then
	cmd=mvncont.sh
	echo
	echo "Usage: $cmd <command to run in mvn container>"
	echo "  Ex: $cmd mvn --version"
	echo
	echo "Special commands:"
	echo "  $cmd reset"
	echo "    => clears volume"
	echo
	echo "  $cmd build"
	echo "    => (re)builds image"
	echo
	echo "Debug infos:"
	echo "  image = <$image>"
	echo "  volume_name = <$volume_name>"
	echo "  project = <$project>"
	echo
	exit 1
fi


action="$1"

case "$action" in
	reset)
		docker volume rm "$volume_name"
		;;
	build)
		setup_image
		;;
	*)
		setup_image
		setup_volume
		docker run --rm -it -u "$container_normaluser" \
			-v "$volume_name:/home/$container_normaluser/.m2" \
			-v "$(pwd):/var/project" \
			-w /var/project \
			"$image" $@
		;;
esac


