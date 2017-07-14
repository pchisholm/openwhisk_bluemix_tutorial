const request = require('request');
const args = process.argv.slice(2);
var creds = '';

args.forEach((line) => {
	creds += line;
});

try {
	creds = JSON.parse(creds);
} catch (err) {
	console.error('Error parsing objectstore service creds: ', err);
}

const options = {  
	method: "POST",
	url:"https://identity.open.softlayer.com/v3/auth/tokens",
	headers: {  
        "Content-Type":"application/json"
    },
	body: JSON.stringify({  
		"auth": {  
			"identity": {  
				"methods": ["password"],
				"password": {  
					"user": 
					{  
						"id": creds.userId,
						"password": creds.password
					}
				}
			},
			"scope": {  
				"project": {  
					"id": creds.projectId
				}
			}
		}
	})
}

request(options, (err, res, body) => {
	if (err) {
		console.error("Something went wrong authenticating with OpenStack objectstore.", err);
		process.exit();
	}

	if (res.statusCode < 400) {
		let out = {}, parsedBody = JSON.parse(body);

		parsedBody.token.catalog.forEach((item) => {
			if (item.type === "object-store") {
				item.endpoints.forEach((endpoint) => {
					if (endpoint.region === creds.region && endpoint.interface === "public") {
						out.url = endpoint.url;
						out.authToken = res.headers['x-subject-token'];
					}
				});
			}
		});

		console.log(JSON.stringify(out, null, 2));
	}
});