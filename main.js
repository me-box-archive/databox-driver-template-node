const databox = require('node-databox');
const https = require('https');
const fs = require('fs');

const store = process.env.DATABOX_STORE_ENDPOINT;

//My https cred generated by the container manager
const HTTPS_SECRETS = JSON.parse( fs.readFileSync("/run/secrets/DATABOX_PEM") );
const credentials = {
  key:  HTTPS_SECRETS.clientprivate || '',
  cert: HTTPS_SECRETS.clientcert || '',
};	

//Wait for your store to be created. Then you can read and write values into it.
databox.waitForStoreStatus(store,'active',100)
.then(() => {
	return databox.keyValue.write(store, 'test', { foo: 'bar' });
}).then((res) => {
	console.log(res);
	return databox.keyValue.read(store, 'test');
}).then((res) => {
	console.log(res);
}).catch((err) => {
	console.error(err);
});

//start the https server for the driver UI
https.createServer(credentials, function (req, res) {
  //The https server is setup to offer the configuration UI for your driver
  //you can use any framework you like to display the interface and parse 
  //user input.
  res.writeHead(200);
  res.end("<html><body><h1>hello world! from a databox driver</h1></body></html>\n");
}).listen(8080);