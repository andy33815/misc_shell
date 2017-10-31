#格式化输出
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"
BOLD="\033[1m"
UNDERLINE="\033[4m"
warn_debug=false
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


git_get () 
{ 
	local commitId=$1;
	local rootdir=$(pwd);
	local path=$2;
	test -z ${commitId} && return 1;
	test -z $path && path="/home/user/workspace/patch";
	local name=$(git log -1 $1 --format=%s| sed "s# ##g"| tr ":" "-");
	path=$path/${name};
	warn "该指令必须运行在git的主目录上!!!!!!";
	for file in $(git show ${commitId} --format=%n --name-only  );
	do
		good "$file";
		test -d ${path}/current/$(dirname $file) || mkdir -p ${path}/current/$(dirname $file);
		git show ${commitId}:$file > ${path}/current/$file;
		local status=$(git show  --format=%n  ${commitId} --name-status ${file} | awk -F" " '{print$1}');
		if [ "$(echo "${status}" | grep -ow M)" == "M" ]; then
			if [ "$(echo ${commitId} | wc -L)" -le "7" ]; then
				local last_commit_id=$(git log  --format=%h  ${file} | grep ${commitId} -r1 |tail -1);
			else
				local last_commit_id=$(git log  --format=%H  ${file} | grep ${commitId} -r1 |tail -1);
			fi;
			echo "(git log  --format=%h  ${file} | grep ${commitId} -r1 |tail -1)";
			echo $last_commit_id;
			test -d ${path}/last/$(dirname $file) || mkdir -p ${path}/last/$(dirname $file);
			git show ${last_commit_id}:${file} > ${path}/last/$file;
		fi;
		#test -d ${path}/new/$(dirname $file) || mkdir -p ${path}/new/$(dirname $file);
		#cp -rf ${file} ${path}/new/$(dirname $file);
	done;
	git format-patch -1 ${commitId} -o ${path};
	good "patch补丁文件保存到 ${path}";
	local REPLY;
	read -p "打开?[y/n]" REPLY;
	[ "$REPLY" != "n" ] && nautilus ${path}
}


git_get $1 $2 
