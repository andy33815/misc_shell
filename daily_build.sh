#!/bin/bash

#初始化变量
CUR_DIR=$(pwd)
CODE_DIR="/E"
LOG_DIR="$CODE_DIR/Log"
PRO_LIST="$CODE_DIR/project_list"
#帮助
function showhelp(){
printf "Usage: 
直接运行
"
}

#格式化输出
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"
BOLD="\033[1m"
UNDERLINE="\033[4m"
warn_debug=true
die() {
	echo -e "==> ${RED}${@}${NO_COLOR}"
	exit 1
}

warn() {
	if [[ "$warn_debug" = true ]]; then
		echo -e "==> ${YELLOW}${@}${NO_COLOR}"
	fi
}

good() {
	echo -e "==> ${GREEN}${*}${NO_COLOR}"
}
#获取当前时间
function get_time(){
	echo $(date +%Y-%m-%d"_"%H-%M)
}

#获取当前最新commit_id
function get_commit_id(){
	local commit_id
	commit_id=$(git log --oneline --format="%h" | head -1)
	echo $commit_id
}
#下载代码
function download_code(){
	local code=$1
	test -d ${CODE_DIR}/${code} || git-gerrit clone $project 
}

#清除上次代码编译残留
function do_project_clean(){
	git checkout . 
	git clean -fd
	good "Project clean completed."

}

#更新代码
function update_project(){
	before_commit=$(get_commit_id)
	git pull 
	after_commit=$(get_commit_id)
	if [ "${before_commit}" != "${after_commit}" ];then
		return 0
	else
		return 1
	fi

}

#编译代码
function make_project(){
	local project=$1
	local variant=$2
	local build_type=$3
	#获取当前项目编译指令
	#执行编译
	#编译结果
	case $build_type in
		android)
			source build/envsetup.sh
			lunch full_${project}-${variant}
			make -j12 
			;;
		mtk)
			if [ "${variant}" == "user" ];then
				./mk -o=TARGET_BUILD_VARIANT=user ${project} n
			else
				./mk ${project} n
			fi
			;;
		ali)
			if [ "${variant}" == "user" ];then
				./mk_aliphone.sh ${project} user adb new
			else
				./mk_aliphone.sh ${project} eng adb new
			fi
			;;
		*)
			warn "无法识别项目的正确编译方法"
			continue
			;;
	esac

}


#发送邮件提醒
function send_email(){
	local from_email="cai_sy@chinaxuhu.com"
	local from_email_name="cai_sy@chinaxuhu.com"
	local from_email_passwd="trf123"
	local to_email="cai_sy@chinaxuhu.com"
	local cc_email=""
	local subject="$(get_time)_$1自动编译$2的$3版本出错"
	local content=""
	local log_file=""
	local extra_parm=" -s smtp.exmail.qq.com -o tls=no "
	local blamer=""
	local log_dir=$4
	#过滤出代码提交者邮箱
	for blamer in $(cat $log_dir/update_author.txt)
	do
		blamer="$(echo $blamer | cut -d ':' -f 2)"
		cc_email="${cc_email} ${blamer}"
	done
	unset blamer
	#邮件内容
	log_file="${log_dir}/build_${2}_${3}.log"
	content="$(grep -rinw "\*\*\* " ${log_file} -r4)"
	echo "send_email"
	#echo " sendEmail -f ${from_email} -t ${to_email} -cc ${cc_email} -u "${subject}" -xu ${from_email_name} -xp ${from_email_passwd} ${extra_parm} -a "${log_file}"  "
	echo "${content}" | sendEmail -f ${from_email} -t ${to_email} -cc ${cc_email} -u "${subject}" -xu ${from_email_name} -xp ${from_email_passwd} ${extra_parm} -a "${log_file}"
}
#主函数
function do_main(){
	local line
	local project
	local code
	local variant
	local build_type
	local log_dir
	local cur_dir
	local blamer
	#遍历编译列表
	for line in $(cat $PRO_LIST)
	do
		code=$(echo $line | cut -d":" -f 1)
		project=$(echo $line | cut -d":" -f 2)
		variant=$(echo $line | cut -d":" -f 3)
		build_type=$(echo $line | cut -d":" -f 4)
		#检查参数是否合法
		#check_parm
		#下载代码
		download_code $code
		#编译前准备
		cur_dir=$(pwd)
		cd $CODE_DIR/$code
		#代码更新
		do_project_clean
		before_commit=""
		after_commit=""
		update_project $log_dir
		result=$?
		if [ $result == 1 ];then
			good "${code}本次没有更新,不做编译"
			#continue
		else
			good "${code}代码有更新,进行编译"
		fi
		#log文件
		log_dir=$LOG_DIR/$code/$(get_time)_${project}_${variant}
		test -d $log_dir || mkdir -p $log_dir
		#判断本次上传提交人信息
		git log ${before_commit}..${after_commit} --format="%an:%ae" | sort | uniq > $log_dir/update_author.txt
		blamer=$(git log ${before_commit}..${after_commit} --format="%an" | sort | uniq | xargs )
		
		good "=================================="
		good "code:$CODE_DIR/$code"
		good "project:$project"
		good "build_mode:$variant"
		good "build_type:$build_type"
		good "log_dir:$log_dir"
		good "blamer:$blamer"
		good "=================================="
		#开始编译
		#清空out目录
		rm -rf ./out
		make_project ${project} ${variant} ${build_type} 2>&1 | tee $log_dir/build_${project}_${variant}.log
		#编译结果判断
		if [ ! -f out/target/product/${project}/system.img ];then
			warn  "编译出错,抄送给最近更新上传代码的负责人"
			send_email ${code} ${project} ${variant} ${log_dir}
		else
			good "编译成功,拷贝版本到xxxxx"
		fi

		cd $cur_dir
	done 


}




#do_main   2>&1 | tee $LOG_DIR/
do_main 

