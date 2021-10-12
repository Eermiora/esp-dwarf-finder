#!/bin/bash
# скрипт ищет библиотеки с dwarf информацией во всех коммитах в репозитории

set -e

if test -z "$1" -o -z "$2"; then
	exit 1
fi

# репозиторий в котором искать библиотеки
repo_url=$1
clone_path=$2
readelf=${READELF:-readelf}
noninteresting_libs="libc.a libgcc.a libsmartconfig.a libpwm.a libc_fnano.a libc_nano.a libm.a libssc.a libwolfssl.a libwolfssl_debug.a libwps.a libhal.a libwpa.a libcore.a libespnow.a"

if ! test -d $clone_path; then
	git clone $repo_url $clone_path
fi

pushd $clone_path >/dev/null

all_commits=$(git rev-list --all --remotes)

for commit in $all_commits; do
	cdate=$(git log -1 --pretty="%ad" $commit)
	echo -ne "Поиск в $commit ($cdate)... "
	libs_found=""
	git checkout $commit 2>/dev/null
	for lib in $(find . -name '*.a'); do
		short_name=$(basename $lib)
		if [[ $noninteresting_libs =~ $short_name ]]; then
			continue
		fi
		${readelf} -w $lib | grep -m 100 DW_TAG >/dev/null && libs_found="$libs_found $short_name"
	done
	if test -n "$libs_found"; then
		echo " найдены библиотеки с dwarf: $libs_found"
	else
		echo -ne "\r"
	fi
done

popd >/dev/null
