#!/bin/bash
if [ ! -z "$GIT_SSL_H" ]; then
        return
fi

export GIT_SSL_H="git_ssl.sh"
# echo "include $GIT_SSL_H"

# 获取当前脚本的相对路径文件名称
GIT_SSL_FILE="${BASH_SOURCE[0]-$0}"
# 获取当前脚本的相对路径
GIT_SSL_FILE_REF_DIR=`dirname ${GIT_SSL_FILE}`
# 获取当前脚本的绝对路径
GIT_SSL_FILE_ABS_DIR=`cd ${GIT_SSL_FILE_REF_DIR}; pwd`
# 获取当前脚本的名称
GIT_SSL_FILE_BASE_NAME=`basename ${GIT_SSL_FILE}`
# 备份当前路径
GIT_SSL_STACK_ABS_DIR=`pwd`
# 路径隔离
cd "${GIT_SSL_FILE_REF_DIR}"
echo "include ${GIT_SSL_FILE_ABS_DIR}/${GIT_SSL_H}"
function safe_exit()
{
    cd "${GIT_SSL_STACK_ABS_DIR}"
    exit $1
}

. ./log_util.sh
#使用方法说明
function usage() {
	cat<<USAGEEOF	
NAME  
    $GIT_SSL_FILE_BASE_NAME - 自动将当前文件夹下所有文件采用openssl进行加密
SYNOPSIS  
    $GIT_SSL_FILE_BASE_NAME [命令列表] [文件名]...   
DESCRIPTION  
	$GIT_SSL_FILE_BASE_NAME --将git仓库加密到托管在Github.com上的root git仓库中 
		-h 
			get help log_info
		-f 
			force mode to override exist file of the same name
		create_key_pairs	
			Create git.private.pem and git.public.pem under $g_key_root_dir. 
		compress_and_encrypt
			Make directory repo_name under $g_public_root_dir/ to an compressed archived file into $g_private_root_dir/ with the same name.
			Then add this archived file to git and push it to remote.
			if repo_name is null , then push all dirs under the $g_public_root_dir/
			surrpot serializable repo_names seperated by space
		decrypt_and_decompress
			Pull the update files from github to root. Decompress file repo_name under $g_private_root_dir/ to g_public_root_dir/.
			if repo_name is null , then pull all dirs on the GitHub Server
			surrpot serializable repo_names seperated by space
		git_add_changes
			add changes of all layer-1 submodules
CHEAT
    ./github.sh create_key_pairs <key_root_dir> <private_key_name> <public_key_name>
    ./github.sh compress_and_encrypt <base_dir> <key_root_dir> <public_key_name>
    ./github.sh decrypt_and_decompress <base_dir> <key_root_dir> <private_key_name>
    ./github.sh git_add_changes <base_dir>
AUTHOR 作者
    由 searKing Chan 完成。
			
DATE   日期
    2017-01-03

REPORTING BUGS 报告缺陷
    向 searKingChan@gmail.com 报告缺陷。	
    		
REFERENCE	参见
	https://github.com/searKing/PrivateGitHub.git
USAGEEOF
}


#设置默认配置参数
function set_default_cfg_param(){
	#覆盖前永不提示-f
	g_cfg_force_mode=0	
}

#git_repositories_dir --
#   |- github.sh
#   |-keyRoot/							#g_key_root_dir
#       |- git.private.pem			#g_git_private_key_name
#       |- git.public.pem			#g_git_public_key_name
#   |- publicRoot/					#g_public_root_dir
#	    |-repo_name
#	    |-tmp_name
#   |- privateRoot/					#g_private_root_dir
#		|-repo_name
#设置默认变量参数
function set_default_var_param(){	
	#私有库所在公有库的根目录，之后的私有库repo全部以加密文件的形式存放在该公有目录下
	g_key_root_dir="keyRoot" #加解密库公私钥所在目录
	g_git_private_key_name="git.private.pem" #解密库私钥名称
	g_git_public_key_name="git.public.pem" #加密库公钥名称
	
}


#创建私有库非加密本地目录
#创建非对称密钥对
function create_key_pairs() {
	expected_params_in_num=3
	if [ $# -ne $expected_params_in_num ]; then
		log_error "${LINENO}:$0 expects $expected_params_in_num param_in, but receive only $#. EXIT"
		return 1;
	fi
	local key_root_dir=$1
	local private_key_name=$2
	local public_key_name=$3
	if [[ "$key_root_dir"x == "-"x ]]; then
		key_root_dir=${g_key_root_dir}
	fi
	if [[ "$private_key_name"x == "-"x ]]; then
		private_key_name=${g_git_private_key_name}
	fi
	if [[ "$public_key_name"x == "-"x ]]; then
		public_key_name=${g_git_public_key_name}
	fi
    log_info "${LINENO}:Create pem files $private_key_name and $public_key_name under $key_root_dir"

	
    #创建非对称密钥
    if [ ! -d "$key_root_dir" ]; then
		mkdir -p "$key_root_dir"
    fi 
	    
	#加解密库公私钥名称
    if [ -e "$key_root_dir/$private_key_name" ] || [ -e "$key_root_dir/$public_key_name" ];	then 
    	if [ $g_cfg_force_mode -eq 0 ]; then
			log_error "${LINENO}:Pem files found with the same name as $private_key_name and/or $public_key_name. Exit."
			return 1
		else
			log_info "${LINENO}:force overwrite existing Pem files"
    	fi
    fi
    #调用openssl创建加解密用的密钥对，并设置证书请求
	#-x509：本选项将产生自签名的证书。一般用来做测试用，或者自己做个Root CA。证书的扩展项在 config文件里面指定。
	#-nodes：如果该选项被指定，如果私钥文件已经被创建则不用加密。
	#-days n：指定自签名证书的有效期限。默认为30天
	#-newkey rsa:bits：用于生成新的rsa密钥以及证书请求。如果用户不知道生成的私钥文件名称，默认采用privkey.pem，生成的证书请求。如果用户不指定输出文件(-out)，则将证书请求文件打印在屏幕上。生成的私钥文件可以用-keyout来指定。生成过程中需要用户输入私钥的保护口令以及证书申请中的一些信息。
	#-newkey dsa:file：用file中的dsa密钥参数来产生一个DSA密钥。
	#-newkey ec:file：用file中的密钥参数来产生一个EC密钥。
	#-keyout filename：指明创建的新的私有密钥文件的文件名。如果该选项没有被设置,，将使用config文件里面指定的文件名。
	#-out filename：输出证书请求文件，默认为标准输出。--公钥
	#-subj arg：用于指定生成的证书请求的用户信息，或者处理证书请求时用指定参数替换。
	#						生成证书请求时，如果不指定此选项，程序会提示用户来输入各个用户信息，包括国名、组织等信息，
	#						如果采用此选择，则不需要用户输入了。比如：-subj /CN=china/OU=test/O=abc/CN=forxy，注意这里等属性必须大写。
    openssl req -x509 -nodes -days 100000 -newkey rsa:2048 -keyout "$key_root_dir/$private_key_name" -out "$key_root_dir/$public_key_name" -subj '/'
    ret=$?
	if [ $ret -ne 0 ]; then
		log_error "${LINENO}:openssl smime req failed : $ret"
		return 1
	fi 
    log_info "${LINENO}:Pem files created. Please backup your key pairs under $(pwd)/$key_root_dir."
}

function compress_and_encrypt()
{
	expected_params_in_num=3
	if [ $# -ne $expected_params_in_num ]; then
		log_error "${LINENO}:$0 expects $expected_params_in_num param_in, but receive only $#. EXIT"
		return 1;
	fi
	local base_dir=$1
	local key_root_dir=$2
	local public_key_name=$3
	if [[ "$base_dir"x == "-"x ]]; then
		base_dir="."
	fi
	if [[ "$key_root_dir"x == "-"x ]]; then
		key_root_dir="${base_dir}/.git/hooks/${g_key_root_dir}"
	fi
	if [[ "$public_key_name"x == "-"x ]]; then
		public_key_name="${g_git_public_key_name}"
	fi
	log_info "${LINENO}:ergodic ${base_dir} to compress and encrypt every file."

	local prj_name=$(cd ${base_dir}; basename $(pwd))
	local private_prj_name=".${prj_name}.private"
	local cached_prj_name=".${prj_name}.cached"
	log_info "${LINENO}: scaning ${private_prj_name} to compress and encrypt every file ..."
    local iter_cached_dir="${base_dir}/${cached_prj_name}"
    local iter_dst_dir="${base_dir}/${private_prj_name}"
	# 切换到加密根目录
	cd "${iter_cached_dir}/"
	for file in `git diff --cached --name-only`
	do
		local iter_src_file="${iter_cached_dir}/${file}"  
		local iter_dst_file="${iter_dst_dir}/${file}"  
		# 源文件只是change，不是rm，所以需要压缩加密
		# 对于目录，显然不需要加密
		if [[ -f "$iter_src_file" ]]; then
				log_info "${LINENO}:compress ${iter_src_file} to ${iter_dst_file}."
				#将本地未加密的git仓库压缩打包到临时操作目录中去
				tar -czf "${iter_dst_file}.tar.gz" "${iter_src_file}"
				cd -
				if [ $ret -ne 0 ]; then
					log_error "${LINENO}:tar "${iter_src_file}" : $ret"
					cd -
					return 1
				fi

				log_info "${LINENO}:encrypt ${iter_dst_file}."
				#使用证书加密文件
				#-encrypt：用给定的接受者的证书加密邮件信息。输入文件是一个消息值，用于加密。输出文件是一个已经被加密了的MIME格式的邮件信息。
				#-des, -des3, -seed, -rc2-40, -rc2-64, -rc2-128, -aes128, -aes192, -aes256，-camellia128, -camellia192, -camellia256：指定的私钥保护加密算法。默认的算法是rc2-40。
				#-binary：不转换二进制消息到文本消息值
				#-outform SMIME|PEM|DER：输出格式。一般为SMIME、PEM、DER三种。默认的格式是SMIME
				#-in file：输入消息值，它一般为加密了的以及签名了的MINME类型的消息值。
				#-out file：已经被解密或验证通过的数据的保存位置。
				#
				openssl smime -encrypt -aes256 -binary -outform DEM -in "${iter_dst_file}.tar.gz" -out "${iter_dst_file}" "${key_root_dir}/${public_key_name}" 
				ret=$?
				rm "${iter_dst_file}.tar.gz" -Rf
				if [ $ret -ne 0 ]; then
					log_error "${LINENO}: openssl smimee -encrypt failed : $ret.EXIT"
					cd -
					return 1
				fi

		fi
		
	done
	cd -

}

function decrypt_and_decompress()
{
	expected_params_in_num=3
	if [ $# -ne $expected_params_in_num ]; then
		log_error "${LINENO}:$0 expects $expected_params_in_num param_in, but receive only $#. EXIT"
		return 1;
	fi
	local base_dir=$1
	local key_root_dir=$2
	local private_key_name=$3
	if [[ "$base_dir"x == "-"x ]]; then
		base_dir="."
	fi
	if [[ "$key_root_dir"x == "-"x ]]; then
		key_root_dir="${base_dir}/.git/hooks/${g_key_root_dir}"
	fi
	key_root_dir=$(cd "${key_root_dir}"; pwd)
	if [[ "$private_key_name"x == "-"x ]]; then
		private_key_name="${g_git_private_key_name}"
	fi
	log_info "${LINENO}:ergodic ${base_dir} to decrypt and decompress every file."

	local prj_name=$(cd ${base_dir}; basename $(pwd))
	local private_prj_name=".${prj_name}.private"
	log_info "${LINENO}: scaning ${private_prj_name} to decrypt and decompress every file ..."
    local iter_src_dir="${base_dir}/${private_prj_name}/.git.private"
	local tmp_prj_name=".${prj_name}.public"
	local iter_dst_dir="${base_dir}/${tmp_prj_name}"
	
	if [ -d "${iter_dst_dir}" ]; then
		rm -Rf "${iter_dst_dir}"
		ret=$?
		if [ $ret -ne 0 ]; then
			log_error "${LINENO}: rm -Rf ${iter_dst_dir} failed : $ret.EXIT"
			return 1
		fi	
	fi
	mkdir -p "${iter_dst_dir}"
	# 切换到加密根目录
	cd "${iter_dst_dir}/"
	cp -Rf "${iter_src_dir}/"  "${iter_dst_dir}/.git"
	# 解密之
	for file in `find . -print0 -name "*" | xargs -i -0 echo {}`
	do
		if [[ "${file}"x == ""x || "${file}"x == "."x || "${file}"x == ".."x ]]; then
			continue
		fi
		if [ -d "${file}" ]; then
			continue
		fi
	
		local iter_file="${iter_dst_dir}/${file}"  
		echo "iter_file=$iter_file"
		# 源文件只是change，不是rm，所以需要压缩加密
		# 对于目录，显然不需要加密
		if [[ -f "$iter_file" ]]; then
			log_info "${LINENO}:decrypt ${iter_file}."
				
			#使用证书解密文件
			#-decrypt：用提供的证书和私钥值来解密邮件信息值。从输入文件中获取到已经加密了的MIME格式的邮件信息值。解密的邮件信息值被保存到输出文件中。
			#-binary：不转换二进制消息到文本消息值
			#-log_inform SMIME|PEM|DER：输入消息的格式。一般为SMIME|PEM|DER三种。默认的是SMIME。
			#-inkey file：私钥存放地址，主要用于签名或解密数据。这个私钥值必须匹配相应的证书信息。如果这个选项没有被指定，私钥必须包含到证书路径中（-recip、-signer）。
			#-in file：输入消息值，它一般为加密了的以及签名了的MINME类型的消息值。
			#-out file：已经被解密或验证通过的数据的保存位置。
			#
			openssl smime -decrypt -binary -inform DEM -inkey "${key_root_dir}/${private_key_name}" -in "${iter_file}" -out "${iter_file}.tar.gz"
			ret=$?
			if [ $ret -ne 0 ]; then
				log_error "${LINENO}: openssl smimee  -decrypt failed : $ret.EXIT"
				cd -
				return 1
			fi	
				
			log_info "${LINENO}:decompress ${iter_file}."
				
			#将本地未加密的git仓库压缩打包到临时操作目录中去
			
			#--strip-components 1 去除一级目录
			tar -xzf "${iter_file}.tar.gz" -C "${iter_dst_dir}/.git" --strip-components 1
			ret=$?
			rm "${iter_file}.tar.gz" -Rf
			cd - > /dev/null
			if [ $ret -ne 0 ]; then
				log_error "${LINENO}:tar "${iter_file}" : $ret"
				cd - > /dev/null
				return 1
			fi 

		fi
		
	done
	git reset --hard
	cd -
	return 0
	
}
# 未加密
#	hooks
# 	加密
# git add 未加密的.git
function git_add_changes()
{
	expected_params_in_num=1
	if [ $# -ne $expected_params_in_num ]; then
		log_error "${LINENO}:$0 expects $expected_params_in_num param_in, but receive only $#. EXIT"
		return 1;
	fi
	local base_dir=$1
	if [[ "$base_dir"x == "-"x ]]; then
		base_dir="."
	fi
    log_info "${LINENO}:ergodic ${base_dir} to git add every file."
	
	# 检测当前原始目录是否是git 版本控制
	if [ ! -d  "${base_dir}/.git" ]; then
        log_error "${LINENO}: ${base_dir}/.git/ is not exist. EXIT"
        safe_exit 1
	fi
	
	# ergodic to find changed original files
	# 遍历当前工程，将已受控目录备份至加密文件夹，git add预处理
	
	prj_name=$(cd ${base_dir}; basename $(pwd))
	cached_prj_name=".${prj_name}.cached"
	log_info "${LINENO}: scaning ${prj_name} to update ${cached_prj_name} ..."
	local iter_src_dir="${base_dir}/.git"  
    local iter_dst_dir="${base_dir}/${cached_prj_name}/.git.private"
    if [ -d "${iter_dst_dir}" ]; then
        rm -Rf "${iter_dst_dir}"
    fi 
    mkdir -p "${iter_dst_dir}"
	# *不能拷贝隐藏文件，所以需要用.
    cp "${iter_src_dir}/."  "${iter_dst_dir}/" -Rf
	if [ ! -d "${iter_dst_dir}/../.git"  ]; then
		log_error "${LINENO}: ${iter_dst_dir}/../.git is not exist.EXIT"
		cd "${base_dir}"; git reset --hard; cd -
		safe_exit 1
	fi
	cd "${iter_dst_dir}/../"
	git add "./." -f
    # 将本地未加密的git仓库压缩打包到临时操作目录中去
	ret=$?
	cd -
	if [ $ret -ne 0 ]; then
		log_error "${LINENO}: git add "${iter_dst_dir}/." -f failed : $ret.EXIT"
		cd "${base_dir}"; git reset --hard; cd -
		safe_exit 1
	fi
	safe_exit 0
	
}

################################################################################
#脚本开始
################################################################################
#含空格的字符串若想作为一个整体传递，则需加*
#"$*" is equivalent to "$1c$2c...", where c is the first character of the value of the IFS variable.
#"$@" is equivalent to "$1" "$2" ... 
#$*、$@不加"",则无区别，

if [ "$#" -lt 1 ]; then   
	cat << HELPEOF
use option -h to get more log_information.  
HELPEOF
	safe_exit 1  
fi   	
set_default_cfg_param #设置默认配置参数	
set_default_var_param #设置默认变量参数
while getopts "fm:h" opt  
do  
	case $opt in
	f)
		#覆盖前永不提示
		g_cfg_force_mode=1
		;;
	h)  
		usage
		safe_exit 1  
		;;  	
	?)
		log_error "${LINENO}:$opt is Invalid"
		;;
	*)    
		;;  
	esac  
done  
#去除options参数
shift $(($OPTIND - 1))

if [ "$#" -lt 1 ]; then   
	cat << HELPEOF
use option -h to get more log_information .  
HELPEOF
	safe_exit 0  
fi   
#获取当前动作
git_wrap_action="$1"

#去除options参数
#shift n表示把第n+1个参数移到第1个参数, 即命令结束后$1的值等于$n+1的值
shift 1
#获取当前动作参数--私有库名称
g_repo_names="$@"	    
case ${git_wrap_action} in
	"create_key_pairs" )
		create_key_pairs "$@"
		if [ $? -ne 0 ]; then
			safe_exit 1
		fi
		;;  
	"compress_and_encrypt" )
		compress_and_encrypt "$@"
		if [ $? -ne 0 ]; then
			safe_exit 1
		fi
		;;  
	"decrypt_and_decompress" )
		decrypt_and_decompress "$@"
		if [ $? -ne 0 ]; then
			safe_exit 1
		fi
		;;
	"git_add_changes" )
		git_add_changes "$@"
		if [ $? -ne 0 ]; then
			safe_exit 1
		fi
		;;
	* )    
		cat << HELPEOF
${git_wrap_action} is unsupported.
use option -h to get more log_information .  
HELPEOF
		safe_exit 1
		;;
esac
log_info "$0 $@ running success"
# read -n1 -p "Press any key to continue..."
safe_exit 0 
