#!/bin/bash

###### 注意: 打包最终产物，发布给用户之前需要执行此脚本！
###### Undo telemetry 的目的是防止日志上传到微软。
###### 我们采用了 VSCodium 提供的方案，对源码中 telemetry 相关的代码配置进行更改。
###### 每次同步 VS Code 源码后都需要前往 VSCodium 获取对应版本 undo telemetry 的最新代码。

###### 以下代码来自: https://github.com/VSCodium/vscodium/blob/1.75.1.23040/utils.sh ######
exists() { type -t "$1" > /dev/null 2>&1; }

is_gnu_sed () {
  sed --version >/dev/null 2>&1
}

replace () {
  echo "${1}"
  if is_gnu_sed; then
    sed -i -E "${1}" "${2}"
  else
    sed -i '' -E "${1}" "${2}"
  fi
}

if ! exists gsed; then
  if is_gnu_sed; then
    function gsed() {
      sed -i -E "$@"
    }
  else
    function gsed() {
      sed -i '' -E "$@"
    }
  fi
fi

###### 以下代码来自: https://github.com/VSCodium/vscodium/blob/1.75.1.23040/undo_telemetry.sh ######
# list of urls to match:
# - mobile.events.data.microsoft.com
# - vortex.data.microsoft.com

SEARCH="\.data\.microsoft\.com"
REPLACEMENT="s|//[^/]+\.data\.microsoft\.com|//0\.0\.0\.0|g"

if is_gnu_sed; then
  replace_with_debug () {
    echo "found: ${2}"
    sed -i -E "${1}" "${2}"
  }
else
  replace_with_debug () {
    echo "found: ${2}"
    sed -i '' -E "${1}" "${2}"
  }
fi
export -f replace_with_debug

d1=`date +%s`

if [[ "${OS_NAME}" == "linux" ]]; then
  if [[ ${VSCODE_ARCH} == "x64" ]]; then
    ./node_modules/@vscode/ripgrep/bin/rg --no-ignore -l "${SEARCH}" . | xargs -I {} bash -c 'replace_with_debug "${1}" "{}"' _ "${REPLACEMENT}"
  else
    grep -rl --exclude-dir=.git -E "${SEARCH}" . | xargs -I {} bash -c 'replace_with_debug "${1}" "{}"' _ "${REPLACEMENT}"
  fi
elif [[ "${OS_NAME}" == "osx" ]]; then
  ./node_modules/@vscode/ripgrep/bin/rg --no-ignore -l "${SEARCH}" . | xargs -I {} bash -c 'replace_with_debug "${1}" "{}"' _ "${REPLACEMENT}"
else
  ./node_modules/@vscode/ripgrep/bin/rg --no-ignore --path-separator=// -l "${SEARCH}" . | xargs -I {} bash -c 'replace_with_debug "${1}" "{}"' _ "${REPLACEMENT}"
fi

d2=`date +%s`

echo "undo_telemetry: $( echo $((${d2} - ${d1})) )s"

###### 以下代码来自: https://github.com/VSCodium/vscodium/blob/1.75.1.23040/update_settings.sh ######
DEFAULT_TRUE="'default': true"
DEFAULT_FALSE="'default': false"
DEFAULT_ON="'default': TelemetryConfiguration.ON"
DEFAULT_OFF="'default': TelemetryConfiguration.OFF"
TELEMETRY_CRASH_REPORTER="'telemetry.enableCrashReporter':"
TELEMETRY_CONFIGURATION=" TelemetryConfiguration.ON"
NLS=workbench.settings.enableNaturalLanguageSearch

update_setting () {
  local FILENAME="${2}"
  # check that the file exists
  if [ ! -f "${FILENAME}" ]; then
    echo "File to update setting in does not exist ${FILENAME}"
    return
  fi

  # go through lines of file, looking for block that contains setting
  local SETTING="${1}"
  local LINE_NUM=0
  while read -r line; do
    local LINE_NUM=$(( $LINE_NUM + 1 ))
    if [[ "${line}" == *"${SETTING}"* ]]; then
      local IN_SETTING=1
    fi
    if [[ ("${line}" == *"${DEFAULT_TRUE}"* || "${line}" == *"${DEFAULT_ON}"*) && "${IN_SETTING}" == "1" ]]; then
      local FOUND=1
      break
    fi
  done < "${FILENAME}"

  if [[ "${FOUND}" != "1" ]]; then
    echo "${DEFAULT_TRUE} not found for setting ${SETTING} in file ${FILENAME}"
    return
  fi

  # construct line-aware replacement string
  if [[ "${line}" == *"${DEFAULT_TRUE}"* ]]; then
    local DEFAULT_TRUE_TO_FALSE="${LINE_NUM}s/${DEFAULT_TRUE}/${DEFAULT_FALSE}/"
  else
    local DEFAULT_TRUE_TO_FALSE="${LINE_NUM}s/${DEFAULT_ON}/${DEFAULT_OFF}/"
  fi

  replace "${DEFAULT_TRUE_TO_FALSE}" "${FILENAME}"
}

update_setting "${TELEMETRY_CRASH_REPORTER}" src/vs/workbench/electron-sandbox/desktop.contribution.ts
update_setting "${TELEMETRY_CONFIGURATION}" src/vs/platform/telemetry/common/telemetryService.ts
update_setting "${NLS}" src/vs/workbench/contrib/preferences/common/preferencesContribution.ts
