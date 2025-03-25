set -e

VSCODE_ARCH='' # x64 | arm64
SOURCE=${PWD}
BUILD_DIRECTORY=$(dirname ${PWD})

function parse_args() {
	while getopts 'a:' opt; do
		case "$opt" in
			a) VSCODE_ARCH=$OPTARG ;;
		esac
	done

	if [[ -z "$VSCODE_ARCH" ]]; then
		echo '[Error] Missing -a, it could be either x64 or arm64 for now' >&2
		exit 1
	fi
}

function set_up_global_variables() {
	echo "==> Setting up global variables..."
	echo "VSCODE_ARCH: ${VSCODE_ARCH}"
	echo "SOURCE: ${SOURCE}"
	echo "BUILD_DIRECTORY: ${BUILD_DIRECTORY}"
	echo "COMMIT: ${COMMIT}"
}

function install_global_dependencies() {
	echo "==> Installing global dependencies..."
	npm install -g yarn create-dmg < /dev/null
}

function update_source_product_dot_json() {
	# 提前修改好源码里面的product.json， build内部插件的时候需要用到
	echo "==> Pre-updating the product.json file..."
	cd $SOURCE/build/agile-pipelines/
	export ICODING_PRODUCT_JSON_PATH=${SOURCE}/product.json
	node updateProduct.js
}

function install_build_dependencies() {
	echo "==> Install build dependencies..."
	cd ${SOURCE}
	PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 ELECTRON_SKIP_BINARY_DOWNLOAD=1 yarn --frozen-lockfile < /dev/null
}

function compile_build_minify() {
	echo "==> Compiling, building, and minifying vscode darwin..."
	cd ${SOURCE}
	yarn gulp compile-build  < /dev/null
	yarn gulp extensions-ci < /dev/null
	yarn gulp minify-vscode < /dev/null
}

function package_vscode_darwin() {
	echo "==> Packaging vscode darwin..."
	yarn gulp vscode-darwin-${VSCODE_ARCH}-min-ci < /dev/null
}

function update_app_product_dot_json() {
	# commit 需要再做一次修改
	echo "==> Updating the app's product.json file..."
	local vscode_package_path=${BUILD_DIRECTORY}/VSCode-darwin-${VSCODE_ARCH}

	cd ${SOURCE}/build/agile-pipelines
	export ICODING_PRODUCT_JSON_PATH=${vscode_package_path}/iCoding.app/Contents/Resources/app/product.json
	node updateProduct.js
}

function create_dmg() {
	echo "==> Creating dmg..."
	# 需要在 VSCodePackagePath 目录下
	local vscode_package_path=${BUILD_DIRECTORY}/VSCode-darwin-${VSCODE_ARCH}
	cd ${vscode_package_path}
	# Create dmg
	create-dmg iCoding.app < /dev/null
}

function prebuild() {
	install_global_dependencies
	update_source_product_dot_json
}

function build() {
	export npm_config_arch=${VSCODE_ARCH}
	export npm_target_arch=${VSCODE_ARCH}
	install_build_dependencies
	compile_build_minify
}

function package() {
	package_vscode_darwin
	update_app_product_dot_json
}

function main() {
	parse_args $@
	set_up_global_variables
	prebuild
	build
	package
	create_dmg
	echo "==> All done!"
}

main $@
