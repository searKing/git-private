#!/bin/bash
. ./src/bash/log_util.sh
ret=$?
if [ $ret -ne 0 ]; then
	log_error "${LINENO}:  failed. EXIT"
	exit 1
fi

git reset --hard
ret=$?
if [ $ret -ne 0 ]; then
	log_error "${LINENO}:  failed : $ret.EXIT"
	exit 1
fi

if [[ "$(pwd)"x == "/"x ]]; then
	log_error "${LINENO}:  current dir is /, no parent dir.EXIT"
	exit 1
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
	exit 1
fi

prj_name=$(cd ../;pwd)
prj_name=${prj_name##*/}
log_info "${LINENO}:  private prj: ${prj_name} is found.EXIT"

for file in $(ls ../.git/hooks/)
do
	if [ "${file##*.}"x != "bak"x ]; then
		continue
	fi
	cp "../.git/hooks/${file}" "../.git/hooks/${file%%.bak}" -Rvf
done
log_info "$0 $@ running success"
# read -n1 -p "Press any key to continue..."
exit 0 
