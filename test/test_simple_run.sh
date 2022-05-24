#!/bin/bash
echo "***** Simple test run of docker image. *****"
echo "Test succeeds and returns 0 exit value, if image runs and outputs 'Preparing spawn area:' within 5 minutes."
echo "Script retuns non-zero value if not successful."

if [ -z "$1" ] ; then
    echo "usage: test_simple_run.sh <name of image>"
    exit 1
fi

# ***** Configuration *****
img_name="$1"
img_run_cmd='/opt/mc/bin/run_java_app.sh'
container_name="TEST-SIMPLE-RUN-MC-VANILLA"
test_log_file_name="test_simple_run.log"
test_log_string_success="INFO]: Preparing spawn area: "

# ***** Functions *****
errchk() {
    if [ "$1" != "0" ] ; then
	echo "$2"
	echo "Exiting."
	exit 1
    fi
}

# ***** Initialization *****
# The project directory is the folder containing this script.
project_dir=$( dirname "$0" )
project_dir=$( ( cd "$project_dir" && pwd ) )
if [ -z "$project_dir" ] ; then
    errck 1 "Error: Could not determine project_dir."
fi
echo "Project test directory is ${project_dir}."
test_log_file="${project_dir}/${test_log_file_name}"

# ***** Prepare *****
docker container stop TEST-SIMPLE-RUN-MC-VANILLA > /dev/null 2>&1
docker container rm TEST-SIMPLE-RUN-MC-VANILLA > /dev/null 2>&1

# Test run, show container std output on screen.
echo "Running test: SIMPLE RUN"
( docker run --name "${container_name}" "${img_name}" "${img_run_cmd}" | tee "${test_log_file}" & )

done=0
sleep_cnt=0
while [ "$done" == "0" ] ; do
    sleep 5;
    sleep_cnt=$(( $sleep_cnt + 5 ))
    # Wait max 5 minutes for log output.
    if [ "$sleep_cnt" -ge "300" ] ; then
	done=1
    fi
    
    if grep "${test_log_string_success}" "${test_log_file}" ; then
	done=1
    fi
done

echo Removing test container.
docker kill "${container_name}" > /dev/null 2>&1
docker rm -f "${container_name}" > /dev/null 2>&1

# Check log
if grep "${test_log_string_success}" "${test_log_file}" ; then
    echo "***** Test SIMPLE RUN SUCCESSFUL *****"
    echo "Success string ""${test_log_string_success}"" found in log output."
else
    echo "***** Test SIMPLE RUN FAILED *****"
    echo "Success string ""${test_log_string_success}"" not found in log output."
    exit 1
fi
