#!/bin/bash
set -e

: ${CANDIDATE_PREFIX:='rc'}
: ${TAG_PREFIX:=''}

PATTERN="^${TAG_PREFIX}([0-9]{1,}\.[0-9]{1,}\.[0-9]{1,})\$"

get_latest_tag() {
  TAGS=$(for tag in $(git tag); do
    [[ "$tag" =~ $PATTERN ]] && echo "${BASH_REMATCH[0]}"
  done)

  if [[ ! -z "$TAGS" ]] ; then
    echo "$TAGS" | tr '.' ' ' | sort -nr -k1 -k2 -k3 | tr ' ' '.' | head -1
  else
    echo '0.0.0'
  fi
}

get_latest_release_candidate_tag() {
  PATTERN="${TAG_PREFIX}([0-9]{1,}\.[0-9]{1,}\.[0-9]{1,}\-${CANDIDATE_PREFIX}.[0-9]{1,})\$"
  echo $(get_latest_tag)
}

get_current_release_version() {
  RELEASE_PATTERN="release/${TAG_PREFIX}([0-9]{1,}\.[0-9]{1,}\.[0-9]{1,})"
  for BRANCH in `git --no-pager branch --list |sed 's/\*//g'`; do
    [[ "$BRANCH" =~ $RELEASE_PATTERN ]] && echo "${BASH_REMATCH[1]}"
  done
}

get_current_patch_version() {
  BUGFIX_PATTERN="hotfix/${TAG_PREFIX}([0-9]{1,}\.[0-9]{1,}\.[0-9]{1,})"
  for BRANCH in `git --no-pager branch --list |sed 's/\*//g'`; do
    [[ "$BRANCH" =~ $BUGFIX_PATTERN ]] && echo "${BASH_REMATCH[1]}"
  done
}

get_current_release_branch() {
  echo "release/`get_current_release_version`"
}

increment_candidate() {
  current_release_version=`get_current_release_version`
  last_release_candidate_tag=$(get_latest_release_candidate_tag)

  if [[ "$last_release_candidate_tag" != '0.0.0'  ]]; then
    echo $last_release_candidate_tag | awk -v mode="$BUMP_MODE" 'match($0, /'${CANDIDATE_PREFIX}'\.([0-9]{1,})/, matches) {   
      printf("%s%d", "'$current_release_version'-rc.", matches[1]+1 )  
    }'
  else
    echo "${current_release_version}-rc.1"
  fi
}

increment_tag_version() {
  echo $( get_latest_tag | gawk -v mode="$BUMP_MODE" 'match($0, /([0-9]{1,})\.([0-9]{1,})\.([0-9]{1,})/, matches) {
    if(mode == "MAJOR")
      printf("%d.%d.%d", matches[1]+1, 0, 0)
    else if(mode == "MINOR")
      printf("%d.%d.%d",  matches[1], matches[2]+1, 0)
    else if(mode == "PATCH")
      printf("%d.%d.%d", matches[1], matches[2], matches[3]+1)
   }')
}

get_version() {
  if [[ "${BUMP_MODE}" != "CANDIDATE" ]]; then
    echo $(increment_tag_version)
  else
    echo $(increment_candidate)
  fi
}

export next_version=`get_version`
