#!/bin/bash
set -x
echo “post-commit $@”

export POST_COMMIT_H="post-commit"
# echo "include $POST_COMMIT_H"

# 获取当前脚本的相对路径文件名称
POST_COMMIT_FILE="${BASH_SOURCE[0]-$0}"
# 获取当前脚本的相对路径
POST_COMMIT_FILE_REF_DIR=`dirname ${POST_COMMIT_FILE}`
# 获取当前脚本的绝对路径
POST_COMMIT_FILE_ABS_DIR=`cd ${POST_COMMIT_FILE_REF_DIR}; pwd`
# 获取当前脚本的名称
POST_COMMIT_FILE_BASE_NAME=`basename ${POST_COMMIT_FILE}`
# 备份当前路径
POST_COMMIT_STACK_ABS_DIR=`pwd`

commit_msg=$(cat .git/COMMIT_EDITMSG)
pwd
. ./.git/hooks/log_util.sh

# 生成密钥
if [ ! -d "./.git/hooks/keyRoot" ]; then
    ./.git/hooks/git_ssl.sh create_key_pairs - - -
    ret=$?
    if [ $ret -ne 0 ]; then
        log_error "${LINENO}:  failed : $ret.EXIT"
        git reset --hard
        exit 1
    fi
    
fi

cd "${POST_COMMIT_STACK_ABS_DIR}"
# 添加
./.git/hooks/git_ssl.sh git_add_changes `cd .; pwd`
ret=$?
if [ $ret -ne 0 ]; then
    log_error "${LINENO}:  failed : $ret.EXIT"
    git reset --hard
    exit 1
fi 

cd "${POST_COMMIT_STACK_ABS_DIR}"
./.git/hooks/git_ssl.sh compress_and_encrypt `cd .; pwd` - -
ret=$?
if [ $ret -ne 0 ]; then
    log_error "${LINENO}:  failed : $ret.EXIT"
    git reset --hard
    exit 1
fi 

cd "${POST_COMMIT_STACK_ABS_DIR}"
prj_name=$(basename $(pwd))
private_prj_name=".${prj_name}.private"
log_info "${LINENO}: git add ${private_prj_name}..."
cd "${private_prj_name}"
git add -u
ret=$?
cd -
if [ $ret -ne 0 ]; then
    log_error "${LINENO}:  failed : $ret.EXIT"
    git reset --hard
    exit 1
fi 

cd "${POST_COMMIT_STACK_ABS_DIR}"
cd "${private_prj_name}"
git commit -m "$commit_msg"
ret=$?
cd -
if [ $ret -ne 0 ]; then
    log_error "${LINENO}:  failed : $ret.EXIT"
	cd "${private_prj_name}"
    git reset --hard
	ret=$?
    exit 1
fi 
cd "${POST_COMMIT_STACK_ABS_DIR}"

exit 0