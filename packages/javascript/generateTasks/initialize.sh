. ../../env.sh

# deploy action 
wsk action update --kind nodejs:6 ${js}/${action} index.js --web true --param-file "${assets}/tasks.json"

# since this is action requires an API route, we add it to the endpoint file
if [[ -n ${rest_endpoints} ]]; then
	echo '"'"${action}"'":"'"${base_gateway_url}""${js}"'/'"${action}"'.json",' >> ${rest_endpoints}
fi

wait