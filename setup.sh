# 2017 Patrick Chisholm
# Openwhisk Bluemix Tutorial (dist deployment file)

dist="cloud"
test="local"

if [ $# -eq 0 ]; then
    echo "Please pick a deployment option: ${dist}, ${test}"
    exit 1
fi

if [[ "$1" =~ ${dist} || "$1" =~ ${test} ]] ; then
	# login to bluemix
	# cf login 

	# export this file location for deployment child scripts
	export rest_endpoints="$(pwd)/public/endpoints.json"

	# create an endpoint list json file for ui dependencies
	rm -f ${rest_endpoints} 2> /dev/null
	touch ${rest_endpoints} && chmod 776 ${rest_endpoints}

	# export the base url for the API based on the user's namespace
	openwhisk_namespace=`node -e '{C=require(process.argv[1]); console.log(C.OrganizationFields.Name + "_" + C.SpaceFields.Name) }' ~/.cf/config.json`
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