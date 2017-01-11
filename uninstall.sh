#!/bin/bash
if [ ! -z "$GIT_PRIVATE_UNINSTALL_H" ]; then
        return
fi

export GIT_PRIVATE_UNINSTALL_H="uninstall.sh"
echo "include $GIT_PRIVATE_UNINSTALL_H"

# 获取当前脚本的相对路径文件名称
GIT_PRIVATE_UNINSTALL_FILE="${BASH_SOURCE-$0}"
# 获取当前脚本的相对路径
GIT_PRIVATE_UNINSTALL_FILE_REF_DIR=`dirname ${GIT_PRIVATE_UNINSTALL_FILE}`
# 获取当前脚本的绝对路径
GIT_PRIVATE_UNINSTALL_FILE_ABS_DIR=`cd ${GIT_PRIVATE_UNINSTALL_FILE_REF_DIR}; pwd`
# 获取当前脚本的名称
GIT_PRIVATE_UNINSTALL_FILE_BASE_NAME=`basename ${GIT_PRIVATE_UNINSTALL_FILE}`
# 备份当前路径
GIT_PRIVATE_UNINSTALL_STACK_ABS_DIR=`pwd`
# 路径隔离
cd "${GIT_PRIVATE_UNINSTALL_FILE_REF_DIR}"
function safe_exit()
{
    cd "${GIT_PRIVATE_UNINSTALL_STACK_ABS_DIR}"
    exit $1
}

GIT_PRIVATE_INSTALL_H=""
. ./src/bash/log_util.sh
ret=$?
if [ $ret -ne 0 ]; then
	log_error "${LINENO}:  failed. EXIT"
	safe_exit 1
fi

git reset --hard
ret=$?
if [ $ret -ne 0 ]; then
	log_error "${LINENO}:  failed : $ret.EXIT"
	safe_exit 1
fi

if [[ "$(pwd)"x == "/"x ]]; then
	log_error "${LINENO}:  GIT_PRIVATE_UNINSTALL dir is /, no parent dir.EXIT"
	safe_exit 1
fi

private_prj_exist=0
for file in $(ls -au ..)
do
	if [[ ( -d "../$file" ) && ( "$file"x == ".git"x )  ]]; then
		private_prj_exist=1
		break
	fi
done

if [[ ${private_prj_exist} -eq 0 ]]; then
	log_error "${LINENO}:  private prj is not exist.EXIT"
	safe_exit 1
fi

prj_name=$(cd ../;pwd)
prj_name=${prj_name##*/}
log_info "${LINENO}:  private prj: ${prj_name} is found.EXIT"

log_info "${LINENO}: recover hooks..."
for file in $(ls ../.git/hooks/)
do
	if [ "${file##*.}"x != "bak"x ]; then
		continue
	fi
	cp "../.git/hooks/${file}" "../.git/hooks/${file%%.bak}" -Rvf
done
for file in $(ls ./src/bash)
do
	if [[ "${file}"x == "."x || "${file}"x == ".."x ]]; then
		continue
	fi
	if [[ -f "../.git/hooks/${file}" || -d "../.git/hooks/${file}" ]]; then
		rm  "../.git/hooks/${file}" -Rvf
	fi
done
log_info "${LINENO}: copying hooks's shell scripts..."
cp -Rvf ./src/bash/* ../.git/hooks/

private_prj_name=".${prj_name}.private"
log_info "${LINENO}: removing private prj: ${private_prj_name} ..."

if [ -d "../${private_prj_name}" ]; then
	rm -Rvf "../${private_prj_name}"
fi
if [ -d "../${private_prj_name}.git" ]; then
	rm -Rvf "../${private_prj_name}.git"
fi

log_info "$0 $@ running success"
# read -n1 -p "Press any key to continue..."
safe_exit 0 
