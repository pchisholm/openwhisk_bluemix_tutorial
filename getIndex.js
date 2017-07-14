const request = require('request');

function main(params) {
	return new Promise((resolve, reject) => {
		const options = {
			url: `${params.objectstoreUrl}${params.containerPath}${params.indexFile}`,
			method: "GET",
			headers: {
				"Content-Type": "text/html"
			}
		};

		request(options, (err, res, body) => {
			if (err) {
				console.error("Error performing request: ", err);
				reject({"error": ""});
			}

			resolve({"html": body});
		});
	});
}