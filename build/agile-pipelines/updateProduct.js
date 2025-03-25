const fs = require('fs');
const path = require('path');

const filePath = process.env.ICODING_PRODUCT_JSON_PATH;
const commit = process.env.COMMIT;

if (!filePath || !commit) {
	return;
}

console.log(`Changing the product.json at: ${filePath}`);
const rawContent = fs.readFileSync(filePath, 'utf8');
const product = JSON.parse(rawContent);
product.commit = commit;
fs.writeFileSync(filePath, JSON.stringify(product, null, 4));

console.log('Here is the latest product.json:');
console.log(product);
