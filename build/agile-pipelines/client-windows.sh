#!/bin/bash

set -e

# Initialize some global variables
SOURCE=$(pwd)

# Helper functions
parse_args() {
	echo "Determined the following variables..."
	echo "SOURCE: $SOURCE"
	echo "COMMIT: $COMMIT"
}

install_global_deps() {
	echo "Installing global dependencies..."
	npm install -g yarn node-gyp
}

update_source_product_dot_json() {
	echo "Updating the product.json file..."
	cd $SOURCE/build/agile-pipelines
	echo Running yarn at $(pwd)
	yarn
	ICODING_PRODUCT_JSON_PATH=$SOURCE/product.json COMMIT=$COMMIT node updateProduct.js
}

prepare_build_environment() {
	echo "Preparing build environment..."
	cd $SOURCE
	ELECTRON_SKIP_BINARY_DOWNLOAD=1 PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 CHILD_CONCURRENCY=1 yarn --frozen-lockfile
}

build_vscode() {
	echo "Building vscode..."
	cd $SOURCE
	# Start the build task
	yarn gulp vscode-win32-x64-min
}

update_app_product_dot_json() {
	echo "Updating the app's product.json file..."
	cd ../VSCode-win32-x64
	local vscode_package_path=$(pwd)
	cd $SOURCE/build/agile-pipelines
	ICODING_PRODUCT_JSON_PATH=$vscode_package_path/resources/app/product.json COMMIT=$COMMIT node updateProduct.js
}

make_package() {
	echo "Making package..."
	cd $SOURCE
	yarn gulp vscode-win32-x64-inno-updater
	yarn gulp vscode-win32-x64-system-setup vscode-win32-x64-user-setup
}

main() {
	parse_args $@
	install_global_deps
	update_source_product_dot_json
	prepare_build_environment
	build_vscode
	update_app_product_dot_json
	make_package
}

main $@
exit 0
