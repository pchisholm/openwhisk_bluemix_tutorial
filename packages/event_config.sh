. env.sh

# define all sequences, triggers and rules here

# note: as your api grows, you may want to split
# this script into child scripts by event or package

# sequences
# *************************************************

wsk package create sequences 2>&1 | grep -v "resource already exists" 

wsk action update --sequence ${seq}/getTasksByLength \
${js}/generateTasks,\
${py}/sortByLength \
--web true

if [[ -n ${rest_endpoints} ]]; then 
	echo '"getTasksByLength":"'"${base_gateway_url}""${seq}"'/getTasksByLength.json",' >> ${rest_endpoints}
fi

# triggers
# *************************************************
# define triggers

# rules
# *************************************************
# define rules

wait 

echo -e "\x1B[34mFinished initializing events.\x1B[0m\n"