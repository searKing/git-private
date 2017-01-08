#!/bin/bash
if [ ! -z "$STRING_UTIL_H" ]; then
    return
fi

export STRING_UTIL_H="string_util.sh"
echo "include $STRING_UTIL_H"

# 获取当前脚本的相对路径文件名称
CURRENT_FILE="${BASH_SOURCE-$0}"
# 获取当前脚本的相对路径
CURRENT_FILE_REF_DIR=`dirname ${CURRENT_FILE}`
# 获取当前脚本的绝对路径
CURRENT_FILE_ABS_DIR=`cd ${CURRENT_FILE_REF_DIR}; pwd`
# 获取当前脚本的名称
CURRENT_FILE_BASE_NAME=`basename ${CURRENT_FILE}`
# 备份当前路径
STACK_ABS_DIR=`pwd`
# 路径隔离
cd "${CURRENT_FILE_REF_DIR}"
function safe_exit()
{
    cd "${STACK_ABS_DIR}"
    exit $1
}

. log_util.sh

# trim(str)
# remove blank space in both side
trim()
{
    echo $*
}

# remove the suffix and get short name
# @param in filename
get_short_name()
{
    local expected_params_in_num=1
	if [ $# -ne $expected_params_in_num ]; then
		log_error "${LINENO}:$0 expects $expected_params_in_num param_in, but receive only $#. EXIT"
		return 1;
	fi

    local full_file_name=$1
    local file_name=$(basename "$full_file_name") 
    echo "$file_name" | sed 's/\.\w*$//'
}

safe_exit 0