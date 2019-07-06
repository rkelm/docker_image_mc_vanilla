#!/bin/bash

if [ -z $1 ] ; then
    echo "usage: $(basename $0) <mc_version>"
    exit 1
fi

# ***** Configuration *****
# Assign configuration values here or set environment variables.
rconpwd="$BAKERY_RCONPWD"
local_repo_path="$BAKERY_LOCAL_REPO_PATH"
remote_repo_path="$BAKERY_REMOTE_REPO_PATH"
repo_name="vanilla_minecraft_jdk8_2"

# Default server properties may be changed below.
# Some options may be set directly in the Dockerfile.


errchk() {
    if [ "$1" != "0" ] ; then
	echo "$2"
	echo "Exiting."
	exit 1
    fi
}

if [ -z "$rconpwd" ] || [ -z "$local_repo_path" ] || [ -z "$remote_repo_path" ] ; then
    errchk 1 'Configuration variables in script not set. Assign values in script or set corresponding environment variables.'
fi

# The project directory is the folder containing this script.
project_dir=$( dirname "$0" )
project_dir=$( ( cd "$project_dir" && pwd ) )
if [ -z "$project_dir" ] ; then
    errck 1 "Error: Could not determine project_dir."
fi
echo "Project directory is ${project_dir}."

app_version="$1"
image_tag="$app_version"

if [ -n "$image_tag" ] ; then
    local_repo_tag="${local_repo_path}/${repo_name}:${image_tag}"
    remote_repo_tag="${remote_repo_path}/${repo_name}:${image_tag}"    
else
    local_repo_tag="${local_repo_path}:${repo_name}"
    remote_repo_tag="${remote_repo_path}:${repo_name}"
fi

# Prepare rootfs.
jar_file=minecraft_server.${app_version}.jar
rootfs="${project_dir}/rootfs"

echo "Cleaning up rootfs from previous build."
rm -frd "$rootfs"

echo "Preparing rootfs."
mkdir -p ${rootfs}/opt/mc
mkdir -p ${rootfs}/opt/mc/server/world
mkdir -p ${rootfs}/opt/mc/jar
mkdir -p ${rootfs}/opt/mc/bin

cp ${project_dir}/mcrcon ${rootfs}/opt/mc/bin/
cp ${project_dir}/mcrcon_LICENSE.txt ${rootfs}/opt/mc/bin/
cp ${project_dir}/run_java_app.sh ${rootfs}/opt/mc/bin/
cp ${project_dir}/stop_java_app.sh ${rootfs}/opt/mc/bin/
cp ${project_dir}/app_cmd.sh ${rootfs}/opt/mc/bin/

# Setup app.
if [ ! -e "$project_dir/${jar_file}" ] ; then
    errchk 1 "Minecraft server jar "$project_dir/${jar_file}" not found. Please download it."
fi

cp "$project_dir/${jar_file}" "${rootfs}/opt/mc/jar/${jar_file}"

echo -e "eula=true\n" > ${rootfs}/opt/mc/server/eula.txt
cat > ${rootfs}/opt/mc/server/server.properties <<EOF
enable-rcon=true
rcon.port=25575
rcon.password=${RCONPWD}
white-list=true
force-gamemode=false
gamemode=0
enable-query=false
player-idle-timeout=0
difficulty=1
spawn-monsters=true
op-permission-level=4
pvp=falses
level-type=DEFAULT
hardcore=false
enable-command-block=true
max-players=20
network-compression-threshold=256
max-world-size=29999984
server-port=25565
server-ip=0.0.0.0
spawn-npcs=true
allow-flight=false
level-name=world
view-distance=10
resource-pack=
spawn-animals=true
generate-structures=true
online-mode=true
max-build-height=256
level-seed=
use-native-transport=true
motd=Minecraft
EOF

# Build.
echo "Building $local_repo_tag"
docker build "${project_dir}" --build-arg RCONPWD="${rconpwd}" --build-arg APP_VERSION="${app_version}" --build-arg ECHO_LOG2STDOUT="NO" -t "${local_repo_tag}" 

errchk $? 'Docker build failed.'

# Get image id.
image_id=$(docker images -q "${local_repo_tag}")

test -n $image_id
errchk $? 'Could not retrieve docker image id.'
echo "Image id is ${image_id}."

# Tag for Upload to aws repo.
docker tag "${image_id}" "${remote_repo_tag}"
errchk $? "Failed re-tagging image ${image_id}".

# Upload.
echo "Execute the following commands to upload the image to a remote aws repository."
echo '   $(aws ecr get-login --no-include-email --region eu-central-1)'
echo "   docker push ${remote_repo_tag}"
