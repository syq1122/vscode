#!/bin/bash
set -e

export PATH=$NODEJS_16_3_0_BIN:$PATH

## 说明：
## 用于构建 ToB POC 版本的 VS Code Server
## 如果需要修改或者添加命令，请添加 $cmd 在前面，以便可以dry run

SOURCE=${PWD} # 源码目录
WORKSPACE=$(dirname ${PWD}) # 源码父目录
DRY_RUN=0

function parse_args() {
	while getopts 'na:' opt; do
		case "$opt" in
			n) DRY_RUN=1 ;;
			a) ARCH=$OPTARG ;;
		esac
	done
}

function set_up_global_variables() {
	echo "==> Setting up global variables..."
	if [[ "$DRY_RUN" -eq 1 ]]; then
		cmd=echo
	else
		cmd=''
	fi

	if [[ -z "${ARCH}" ]]; then
		ARCH="x64"
	else
		ARCH=${ARCH}
	fi

	echo "==> COMMIT: $COMMIT"
	echo "==> ARCH: $ARCH"
}

function find_target_node_version() {
	echo "==> Finding target node version..."
	local getNodeVersionJsCode="const fs = require('fs');"
#	const yarnrc = fs.readFileSync('$SOURCE/remote/.yarnrc', 'utf8');
#	const target = /^target \"(.*)\"$/m.exec(yarnrc)[1];
#	console.log(target);"

	NODE_VERSION=$(node -e "$getNodeVersionJsCode")
	echo "==> Server Node.js Version: $NODE_VERSION"
}

function download_vsserver_release() {
	local serverVSCodeVersion=$(node -e "console.log(require('$SOURCE/package.json').version)")
	$cmd mkdir -p $SOURCE/reverse
	$cmd cd $SOURCE/reverse
	$cmd curl -L -s -S "https://update.code.visualstudio.com/commit:$VSCODE_COMMIT/server-linux-$ARCH-web/stable" --output vscode-server-linux-$ARCH-web.tar.gz -w "%{http_code}"
	$cmd tar xf vscode-server-linux-$ARCH-web.tar.gz
}

function prepare_deps() {
	echo "==> Preparing dependencies..."
	$cmd cd $SOURCE
	$cmd npm install --ignore-scripts
	$cmd cd $SOURCE/build
	$cmd npm install
	$cmd cd $SOURCE/build/lib/watch
	$cmd npm install
}

function prepare_remote_web_node_modules() {
	echo "==> Preparing remote web node_modules..."
	$cmd cd $SOURCE/remote/web
	$cmd npm install
}

function change_product_dot_json() {
	echo "==> Changing product.json..."
    $cmd cd $SOURCE/build/agile-pipelines/
	$cmd export ICODING_PRODUCT_JSON_PATH=${SOURCE}/product.json
	$cmd node updateProduct.js
}

function download_builtin_extensions() {
	echo "==> Downloading builtin extensions..."
	$cmd cd $SOURCE
# TODO 这里跳过下载插件
#	$cmd rm -rf .build
#	$cmd npm run download-builtin-extensions
}

function compile_build_minify() {
	echo "==> Start the compilation process"
	$cmd cd $SOURCE

	$cmd npm run gulp compile-build
	$cmd npm run gulp minify-vscode-reh-web
	# 干掉 sourcemap
	$cmd find out-vscode-reh-web-min -type f -name '*.map' | $cmd xargs rm
}

function copy_nls_files() {
	echo "==> Copying nls files..."
	# Copy nls files to the out/vs/workbench folder
	# 注意，为了让 mac 和 linux cp 的行为一致（把 lang 目录里的内容复制到 workbench 目录），路径末尾 slash 后面的 . 是必要的
	# https://dev.to/ackshaey/macos-vs-linux-the-cp-command-will-trip-you-up-2p00
	$cmd cp -r $SOURCE/build/agile-pipelines/lang/. $SOURCE/out-vscode-reh-web-min/vs/workbench/.
}

function make_package() {
	echo "==> Making package..."
	local variant=$1

	# 这里直接用了icoding-release文件夹，理论上，如果同时执行流水线，可能会有问题
	$cmd mkdir -p $WORKSPACE/icoding-release
	$cmd cd $WORKSPACE/icoding-release

	$cmd rm -rf vscode-server-linux-$ARCH-web/
	$cmd cp -r $SOURCE/reverse/vscode-server-linux-$ARCH-web .
	$cmd cd vscode-server-linux-$ARCH-web/

	## replace product.json
	$cmd rm product.json
	$cmd cp $SOURCE/product.json .

	## replace out
	$cmd rm -rf out/
	$cmd cp -r $SOURCE/out-vscode-reh-web-min .
	$cmd mv out-vscode-reh-web-min out

	## replace resources
	$cmd rm -rf resources/
	$cmd mkdir resources
	$cmd cp -r $SOURCE/resources/server resources
	$cmd rm -rf resources/server/bin resources/server/bin-dev
	# 防拷贝功能让网页端(remote-web)依赖了crypto-js，所以要在官方node_modules包里额外加上crypto-js
	$cmd cp -r $SOURCE/remote/web/node_modules/crypto-js node_modules
	$cmd cd $WORKSPACE
	## package
	$cmd rm -rf ${COMMIT}-${variant}/
	$cmd mkdir ${COMMIT}-${variant}/
	$cmd cp -r $WORKSPACE/icoding-release/vscode-server-linux-$ARCH-web/. ${COMMIT}-${variant}/.
	$cmd tar --disable-copyfile -czf ${COMMIT}.${variant}.tar.gz ${COMMIT}-${variant}/
}

function build_icoding() {
	echo "==> Building the icoding server..."
	local variant=${1};

	change_product_dot_json
	download_builtin_extensions
	compile_build_minify ${variant}
	copy_nls_files
	make_package ${variant}
}

function clean_up() {
	echo "==> Cleaning up..."
	cd $WORKSPACE
	$cmd rm -rf ${COMMIT}-patchelf/ ${COMMIT}-nopatchelf/ ${COMMIT}-arm64/ icoding-release/
}

function main() {
	parse_args $@
	set_up_global_variables
	clean_up
	find_target_node_version
	download_vsserver_release
	prepare_deps
	prepare_remote_web_node_modules

	if [[ "$ARCH" == "x64" ]]; then
		echo -e "\n\n==> Start to build iCoding nopatchelf"
		build_icoding nopatchelf
		echo -e "==> nopatchelf DONE \n"
	else
		echo -e "\n\n==> Start to build iCoding arm64"
		build_icoding arm64
		echo -e "==> arm64 DONE \n"
	fi

	echo "==> All done!"
}

main $@
