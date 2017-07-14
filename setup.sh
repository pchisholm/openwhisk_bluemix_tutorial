# 2017 Patrick Chisholm
# Openwhisk Bluemix Tutorial (dist deployment file)

# valid deploy args
dist="cloud"
test="local"

if [ $# -eq 0 ]; then
    echo "Please pick a deployment option: ${dist}, ${test}"
    exit 1
fi

if [[ "$1" =~ ${dist} || "$1" =~ ${test} ]] ; then
	# service name vars
	tone_analyzer_name="my_tone_analyzer"

	# service key vars
	tone_analyzer_key="my_tone_key"

	# login to bluemix
	cf login

	# check if service exists
	cf services | grep ${tone_analyzer_name} 2>&1 /dev/null

	# if it does not, we need to create the objectstore to store our UI files
	if [ $? == 1 ]; then 
		echo -e "\x1B[32mSetting up a Watson tone analyzer. This may take up to a few minutes.\x1B[0m\n"
		cf create-service tone_analyzer Free ${tone_analyzer_name}
		wait

		while true; do
	    	cf service tone_analyzer ${tone_analyzer_name} | grep "create succeeded"

	    	if [ $? == 1 ]; then
	    		cf create-service-key ${tone_analyzer_name} ${tone_analyzer_key} > /dev/null 2>&1

		        if [ $? != 0 ]; then
		        	echo -n "."
		        else
		            break
		        fi
	    	fi
		done

		service_key=`cf service-key ${tone_analyzer_name} ${tone_analyzer_key}`
		echo -e "\n\x1B[34mWatson tone-analyzer was successfully integrated.\x1B[0m\n"
	fi

	# export this file location for deployment child scripts
	export rest_endpoints="$(pwd)/public/endpoints.json"

	# create an endpoint list json file for ui dependencies
	rm -f ${rest_endpoints} 2> /dev/null
	touch ${rest_endpoints} && chmod 776 ${rest_endpoints}

	# export the base url for the API based on the user's namespace
	openwhisk_namespace=`node -e '{C=require(process.argv[1]); 
		console.log(C.OrganizationFields.Name + "_" + C.SpaceFields.Name) }' ~/.cf/config.json`
	export base_gateway_url="https://openwhisk.ng.bluemix.net/api/v1/experimental/web/${openwhisk_namespace}/"
	echo -e "\nYour OpenWhisk namespace is: \x1B[1m${openwhisk_namespace}\x1B[0m. Hosted at:\n\x1B[1m${base_gateway_url}\x1B[0m\n"

	# start building the API
	echo -e "\x1B[32mDeploying OpenWhisk assets:\x1B[0m\n"

	# write each endpoint url as a key/val pair with key being the 
	# action name, value being the url into an endpoint json file
	echo "{" >> ${rest_endpoints}

	# loop through all the package directories and run child initializations
	for package in packages/*/; do
		if [ $package != "packages/config/" ]; then
			(cd $package && ./initialize.sh) &
			wait 
		fi
	done

	wait

	# set up the application events once assets have been deployed
	cd packages && ./event_config.sh

	wait

	cd .. 

	# finish writing endpoint file (remove last comma) & 'prettyify' json
	echo `sed '$s/,$//' < ${rest_endpoints}` > ${rest_endpoints}
	echo "}" >> ${rest_endpoints}
	echo "$(python -m json.tool ${rest_endpoints})" > ${rest_endpoints}

	npm install

	if [[ "$1" =~ ${dist} ]]; then
		echo -e "\x1B[32mDeploying NodeJS server on Bluemix:\x1B[0m\n"

		# push the node application to bluemix
		cf push -f "$(pwd)/manifest.yml"
	fi

	if [[ "$1" =~ ${test} ]]; then
		echo -e "\x1B[32mStarting NodeJS server...\x1B[0m\n"

		# start node server on local
		node app.js
	fi 
else
	echo -e "\x1B[31mInvalid argument.\x1B[0m\nPlease use either: ${dist}, ${test}"
fi 

# use these variables to name your objectstore service and service objectstore_key
objectstore_name="demo_store" && objectstore_key="demo_store_key"

# check if service exists
# cf services | grep ${objectstore_name} 2>&1 /dev/null

# if it does not, we need to create the objectstore to store our UI files
# if [ $? == 1 ]; then 
# 	echo -e "\x1B[32mSetting up a Bluemix objectstore. This may take up to a few minutes.\x1B[0m\n"
# 	cf create-service Object-Storage Free ${objectstore_name}
# 	wait

# 	while true; do
#     	cf service ${objectstore_name} | grep "create succeeded"

#     	if [ $? == 1 ]; then
#     		cf create-service-key ${objectstore_name} ${objectstore_key} > /dev/null 2>&1

# 	        if [ $? != 0 ]; then
# 	        	echo -n "."
# 	        else
# 	            break
# 	        fi
#     	fi
# 	done

# 	store_creds=`cf service-key ${demo_store} ${demo_store_key}`
# 	echo -e "\n\x1B[34mObjectstorage was successfully integrated.\x1B[0m\n"
# fi	

container_name="static"
objectstore_service_creds=`cf service-key ${objectstore_name} ${objectstore_key} | grep -v "Getting"`
openstack_creds=$(node ./getAuthToken.js ${objectstore_service_creds})
objectstore_url=$(jq -r '.url' <<< "$openstack_creds")
objectstore_auth_token=$(jq -r '.authToken' <<< "$openstack_creds")

echo -e "\nUsing OpenStack endpoint: ${objectstore_url}\n"
echo -e "\n\x1B[32mCreating container to serve static content:\x1B[0m\n"

curl -i -o /dev/null $objectstore_url/$container_name -X PUT \
-H "X-Auth-Token: ${objectstore_auth_token}"

echo -e "\n\x1B[32mConfiguring container to serve static content:\x1B[0m\n"

curl -i -o /dev/null $objectstore_url/$container_name -X POST \
-H "X-Auth-Token: ${objectstore_auth_token}" \
-H "X-Container-Read: .r:*" \
-H "X-Container-Meta-Web-Index: index.html" \
-H "X-Container-Meta-Access-Control-Allow-Origin: *" \
-H "X-Container-Meta-Access-Control-Expose-Headers: Content-Type"

for file in public/*; do
	file_name=$(basename "$file") && file_content=$(cat $file)

	if [[ $file == *.js ]]; then
		mimetype="application/javascript; charset=UTF-8"
	fi

	if [[ $file == *.html ]]; then
		mimetype="text/html; charset=UTF-8"
	fi

	if [[ $file == *.css ]]; then
		mimetype="text/css; charset=UTF-8"
	fi

	if [[ $file == *.json ]]; then
		mimetype="application/json; charset=UTF-8"
	fi

	echo -e "\n\x1B[32mAttempting to push: $file_name ($mimetype) to object store:\x1B[0m\n"

	curl -i -o /dev/null $objectstore_url/$container_name/$file_name \
	-X PUT -d "$file_content" \
	-H "Content-Type: ${mimetype}" \
	-H "X-Auth-Token: ${objectstore_auth_token}" \
	-H "X-Detect-Content-Type: false"
done

echo -e "\n\x1B[34mFinished deploying static content.\x1B[0m"
echo -e "\n\x1B[32mConfiguring your openwhisk web assets:\x1B[0m\n"

wsk package update static -p objectstoreUrl ${objectstore_url} 

wsk action update static/index getIndex.js \
-p containerPath "/static/" \
-p indexFile "index.html" \
--web true

echo -e "\n\x1B[32mCreating nginx proxy:\x1B[0m\n"

# cf push whisktut \
#      -b https://github.com/cloudfoundry/staticfile-buildpack.git \
#      -m 64m