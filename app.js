// Simple NodeJS server for hosting static content
const express = require('express'),
	http = require('http');

const app = express();
app.use(express.static(__dirname + '/public'));
app.use('/', express.static(__dirname + '/public'));

// Listen for VCAP env port for deployment on Bluemix
const server = http.createServer(app),
	port = process.env.VCAP_APP_PORT || 8080;

server.listen(port, () => {
	console.log(`Node server started on port ${port}. Thanks for using my tutorial! ^_^`)
});
