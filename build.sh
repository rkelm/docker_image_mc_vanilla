#!/bin/bash

if [ -z $1 ] ; then
    echo "usage: $(basename $0) <mc_version>"
    exit 1
fi
# ***** Functions *****

errchk() {
    if [ "$1" != "0" ] ; then
	echo "$2"
	echo "Exiting."
	exit 1
    fi
}

ver_cmp() {
    local IFS=.
    local V1=($1) V2=($2) I
    for ((I=0 ; I<${#V1[*]} || I<${#V2[*]} ; I++)) ; do
	[[ ${V1[$I]:-0} -lt ${V2[$I]:-0} ]] && echo -1 && return
	[[ ${V1[$I]:-0} -gt ${V2[$I]:-0} ]] && echo 1 && return
    done
    echo 0
 }

ver_ge() {
    [[ ! $(ver_cmp "$1" "$2") -eq -1 ]]
}

download_mc_srv() {
    # Downloads minecraft server jar in specified version to specified file name.
    # Parameters:
    #    minecraft version
    #    output file name
    # Download version manifest.
    wget -q https://launchermeta.mojang.com/mc/game/version_manifest.json -O version_manifest.json
    version_detail_url=$( jq -r ".versions[] | select(.id==\"$1\") | .url" version_manifest.json )
    if [ -z "$version_detail_url" ] ; then
	echo "Could not determine url for minecraft detail json file for version $1. Maybe invalid version specified?"
	exit 1
    fi
    wget -q $version_detail_url -O version_detail.json
    server_jar_url=$( jq -r .downloads.server.url version_detail.json )
    wget -q $server_jar_url -O $2
    if [ ! -f $2 ] ; then
	echo "Could not download $server_jar_url to $2."
	exit 1
    fi
}

# ***** Configuration *****
# Assign configuration values here or set environment variables.
minecraft_server_dl="https://mcversions.net/download/"
rconpwd="$BAKERY_RCONPWD"
local_repo_path="$BAKERY_LOCAL_REPO_PATH"
remote_repo_path="$BAKERY_REMOTE_REPO_PATH"
# Starting with minecraft 1.12 JDK 8 is used.
repo_name_1_12="vanilla_minecraft_jdk8_2"
# Starting with minecraft 1.17 JDK 11 is used.
repo_name_1_17="vanilla_minecraft_eclipse-temurin-jdk11"
Dockerfile_1_12="Dockerfile_1_12"
Dockerfile_1_17="Dockerfile_1_17"

if ver_ge $1 "1.17" ; then
    Dockerfile="${Dockerfile_1_17}"
    repo_name="${repo_name_1_17}"
elif ver_ge $1 "1.12" ; then
    Dockerfile="${Dockerfile_1_12}"
    repo_name="${repo_name_1_12}"    
else
    errchk 1 "$1 ist an unssupported Mincecraft version."
fi
echo "Using Dockerfile ${Dockerfile}."

# Default server properties may be changed below.
# Some options may be set directly in the Dockerfile.

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
if [ -e "$project_dir/${jar_file}" ] ; then
    echo "Using local version of minecraft server jar file $project_dir/${jar_file}."
    jar_file_src="$project_dir/${jar_file}"
elif [ -e "/vagrant/${jar_file}" ] ; then
    echo "Using local version of minecraft server jar file $vagrant/${jar_file}."    
    jar_file_src="/vagrant/${jar_file}"
else
    echo "Minecraft server jar "${jar_file}" not found in /vagrant or "$project_dir". Downloading..."
    download_mc_srv $app_version "${project_dir}/${jar_file}"
    #    wget "${minecraft_server_dl}${app_version}" -O "${project_dir}/${jar_file}"
    errchk $? "Could not download Minecraft server from ${minecraft_server_dl}${app_version}. Maybe you specified an invalid version?"
    jar_file_src="${project_dir}/${jar_file}"
fi
cp "${jar_file_src}" "${rootfs}/opt/mc/jar/${jar_file}"
echo cp

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
docker build "${project_dir}" --no-cache --build-arg RCONPWD="${rconpwd}" --build-arg APP_VERSION="${app_version}" --build-arg ECHO_LOG2STDOUT="NO" -t "${local_repo_tag}" -f "${Dockerfile}"

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
