var databox = require('node-databox');

var store = process.env.DATABOX_DRIVER_TEMPLATE_NODE_DATABOX_STORE_BLOB_ENDPOINT;

Promise.resolve().then(() => {
	return databox.keyValue.write(store, 'test', { foo: 'bar' });
}).then((res) => {
	console.log(res);
	return databox.keyValue.read(store, 'test');
}).then((res) => {
	console.log(res);
}).catch((err) => {
	console.error(err);
});
