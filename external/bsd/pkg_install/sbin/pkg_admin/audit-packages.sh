#!/bin/sh

pkg_admin=/usr/sbin/pkg_admin

usage() {
	echo 'Usage: audit-packages [-deqsVv] [-c config_file] [-F file]' >& $2
	echo '                      [-g file] [-h file]' >& $2
	echo '                      [-K pkg_dbdir] [-n package] [-p package]' >& $2
	echo '                      [-Q varname] [-t type]' >& $2
	echo "Please use the audit, audit-pkg, audit-batch and fetch-pkg-vulnerabilities" >& $2
	echo "commands of pkg_admin instead." >& $2
	exit $1
}

do_pkgdb=
do_eol=
do_fetch=
do_quiet=
do_sign=
do_verbose=
do_check_file=
do_check_pattern=
do_check_installed=
do_check_vul_file=
do_limit_type=
do_print_var=

args=`getopt F:K:Q:Vc:deg:h:n:p:qst:v $*`
if [ $? -ne 0 ]; then
	usage 1 2
fi

set -- $args

while [ $# -gt 0 ]; do
	case "$1" in
	-F)
		do_check_file=$2
		shift
		;;
	-K)
		do_pkgdb="$1 $2"
		shift
		;;
	-Q)
		do_print_var="$2"
		shift
		;;
	-V)
		exec ${pkg_admin} -V
		;;
	-c)
		echo "The audit-packages wrapper does not support -c" >&2
		echo "Please use the audit, audit-pkg, audit-batch and fetch-pkg-vulnerabilities" >& 2
		echo "commands of pkg_admin instead." >& 2
		exit 1
		;;
	-d)
		do_fetch=1
		;;
	-e)
		do_eol=-e
		;;
	-g)
		echo "The audit-packages wrapper does not support -g" >&2
		echo "Please switch to \`\`pkg_admin fetch-pkg-vulnerabilities''." >&2
		exit 1
		;;
	-h)
		do_check_vul_file=$2
		shift
		;;
	-n)
		do_check_pattern=$2
		shift
		;;
	-p)
		do_check_installed=$2
		shift
		;;
	-q)
		do_quiet=-q
		;;
	-s)
		do_sign=-s
		;;
	-t)
		do_limit_type="-t $2"
		shift
		;;
	-v)
		do_verbose="$do_verbose -v"
		;;
	esac
	shift
done

if [ -n "${do_fetch}" ]; then
	exec ${pkg_admin} ${do_pkgdb} fetch-pkg-vulnerabilities ${do_sign}
fi

if [ -n "${do_check_vul_file}" ]; then
	exec ${pkg_admin} ${do_pkgdb} check-pkg-vulnerabilities ${do_sign} "${do_check_vul_file}"
fi

if [ -n "${do_print_var}" ]; then
	exec ${pkg_admin} ${do_pkgdb} config-var "${do_print_var}"
fi

if [ -n "${do_check_file}" ]; then
	if [ -n "${do_check_pattern}" -o -n "${do_check_installed}" ]; then
		echo "Only one of -F, -n or -p is interpreted at a time." >& 2
		usage 1 2
	fi
	exec ${pkg_admin} ${do_pkgdb} ${do_verbose} ${do_quiet} audit-pkg \
	    ${do_eol} ${do_limit_type} ${do_check_file}
fi

if [ -n "${do_check_pattern}" ]; then
	if [ -n "${do_check_installed}" ]; then
		echo "Only one of -F, -n or -p is interpreted at a time." >& 2
		usage 1 2
	fi
	exec ${pkg_admin} ${do_pkgdb} ${do_verbose} ${do_quiet} audit-pkg \
	    ${do_eol} ${do_limit_type} ${do_check_pattern}
fi

# If do_check_installed is empty, all packages are checked.
exec ${pkg_admin} ${do_pkgdb} ${do_verbose} ${do_quiet} audit \
    ${do_eol} ${do_limit_type} ${do_check_installed}
