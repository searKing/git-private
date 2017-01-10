#!/bin/bash
if [ ! -z "$LOG_UTIL_H" ]; then
        return
fi

export LOG_UTIL_H="log_util.sh"
# echo "include $LOG_UTIL_H"

# 获取当前脚本的相对路径文件名称
LOG_UTIL_FILE="${BASH_SOURCE-$0}"
# 获取当前脚本的相对路径
LOG_UTIL_FILE_REF_DIR=`dirname ${LOG_UTIL_FILE}`
# 获取当前脚本的绝对路径
LOG_UTIL_FILE_ABS_DIR=`cd ${LOG_UTIL_FILE_REF_DIR}; pwd`
# 获取当前脚本的名称
LOG_UTIL_FILE_BASE_NAME=`basename ${LOG_UTIL_FILE}`
# 备份当前路径
LOG_UTIL_STACK_ABS_DIR=`pwd`
# 路径隔离
cd "${LOG_UTIL_FILE_REF_DIR}"
# function safe_exit()
# {
#     cd "${STACK_ABS_DIR}"
#     exit $1
# }
echo "include ${LOG_UTIL_FILE_ABS_DIR}/${LOG_UTIL_H}"
. string_util.sh

# @param_in message
# @param_in loglevel
function log()
{
    datetime=`date +"%y-%m-%d %H:%M:%S"`
    local message=$1
    local loglevel=$2
    local log_file_name=$3
    local base_dir=$4
    if [[ -z "$loglevel" || ""x == "$loglevel"x ]]; then
        loglevel="INFO"
    fi
    if [[ -z "$log_file_name" || ""x == "$log_file_name"x ]]; then
        log_file_name="$0"
    fi

    if [[ -z "$basedir" || ""x == "$basedir"x ]]; then
        basedir="${LOG_UTIL_FILE_ABS_DIR}"
    fi

    local outdir="$basedir/log"
    if [ ! -d "$outdir" ]; then
        mkdir -p "$outdir"
    fi
    local log_file_name=`get_short_name $log_file_name`
    echo "$datetime [$0] $loglevel :: $message" | tee -a "$outdir/$log_file_name.log"
}

function log_error()
{
        log "$1" "ERROR"
}

function log_info()
{
        log "$1" "INFO"
}

function log_debug()
{
        log "$1" "DEGUG"
}

function log_warn()
{
        log "$1" "WARN"
}

cd "${LOG_UTIL_STACK_ABS_DIR}"
