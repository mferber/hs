#!/bin/sh

#
# hs: git history grepper
#
# Runs git grep against every ancestor of <commit> (inclusive), in chronological
# order (oldest to first), searching for <regexp>.
#
# Matthias Ferber, Cantina
# matthias@cantinaconsulting.com
#

function usage {
  echo "`basename $0` [<options>] <regexp> [<commit-id> [<path-spec>...]]"
  echo "Search git ancestry of <commit-id> for regexp, starting with oldest version"
  echo
  echo " Options:"
  echo
  echo "   -a"
  echo "   --all"
  echo "       Find all matches.  If unset, stops after the first version that produces"
  echo "       a match."
  echo "   -i"
  echo "   --ignore-case"
  echo "       Use case-insensitive matching; default is case-sensitive"
  echo
  echo " Arguments:"
  echo "   <regexp>: use extended regexp syntax"
  echo "   <commit-id>: if omitted, uses HEAD (current branch)"
  echo "   <path-spec>...: limit the search to paths listed here"
  echo
}

stop_after_first_match=1
case_sensitive=1

while [[ $# > 0 ]]
do
  case $1 in

    -h|--help)
     usage
     exit 0
     ;;

    -a|--all)
      stop_after_first_match=0
      shift
      ;;

    -i|--ignore-case)
      case_sensitive=0
      shift
      ;;

    *)
      break
      ;;

  esac
done

regexp=$1; shift
tip_commit_id=`git rev-parse ${1:-HEAD}`; shift

if [[ -z $regexp ]]; then
  echo "Regexp is required."
  echo
  usage
  exit 1
fi

commit_sha1s=`git rev-list --reverse $tip_commit_id`
for commit_sha1 in ${commit_sha1s[*]}
do
  printf .

  if [[ $case_sensitive -eq 0 ]]; then ignore_case_arg=" --ignore-case"; fi
  git_grep="git grep$ignore_case_arg --extended-regexp --color $regexp $commit_sha1 $@"
  output=`$git_grep`

  if [[ $? -eq 0 ]]; then
    printf -- "\n\n--------------------------------------\n"
    git log --pretty=format:'%h (%cn, %cd): %s' --date=relative -n 1 $commit_sha1
    #printf "$git_grep\n"
    printf -- "--------------------------------------\n"
    printf "$output\n\n"

    if [[ $stop_after_first_match -eq 1 ]]; then exit 0; fi
  fi

done
echo
