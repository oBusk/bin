#!/usr/bin/env bash

give_up () {
  echo "Everything got messed up. Sorry about that."
  exit 1
}

branch_prefix="autoreview-"
branchlog="./create-branch.log"

if [ $# -ne 1 ]; then
  echo "usage: $0 <storynum>"
  echo
  echo "will create the branch $branch_prefix<storynum>"
  echo "with commits where the message contains <storynum>"
  exit 1
fi


if [ -n "$(git status --porcelain)" ]; then
  echo "Unclean working directory, Stash and try again."
  exit 1
fi

prev_branch=$(git rev-parse --abbrev-ref HEAD)
story_num=$1
rew_branch=$branch_prefix$story_num

if git show-ref --verify --quiet refs/heads/"$rew_branch" ; then
  echo "$rew_branch exists, delete with:"
  echo -e "\tgit branch -D $rew_branch"
  exit 1
fi

refs=($(git log --perl-regexp --grep "\\b${story_num}\\b" --no-merges --topo-order --reverse --pretty=format:"%h"))

#                       Weird indexing to appease zsh
init=$(git rev-parse "${refs[0]}~1" 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "Can't find starting point. Maybe no commits match the story number?"
  exit 1
fi

echo creating "$rew_branch" from "$init"
git checkout -b "$rew_branch" "$init" > "$branchlog" 2>&1

for ref in "${refs[@]}"
do
  # echo applying "$ref"
  git cherry-pick "$ref" --allow-empty --keep-redundant-commits --strategy=ort -X theirs >> "$branchlog" 2>&1
  if [ $? -ne 0 ]; then
    # Try merge

    # D           D    unmerged, both deleted
    # A           U    unmerged, added by us
    # U           D    unmerged, deleted by them
    # U           A    unmerged, added by them
    # D           U    unmerged, deleted by us
    # A           A    unmerged, both added
    # U           U    unmerged, both modified
    
    git status --porcelain=v1 -uno | while read line ; do
      tline=$(echo "$line" | sed -E 's/^([[:alpha:]?!]+)[[:blank:]]+(.*)/\1\t\2/') # shenanigans to allow space in paths
      mode=$(echo "$tline" | cut -f 1)
      mpath=$(echo "$tline" | cut -f 2)
      case "$mode" in
        "UA" | "DU" | "AA" | "UU")
        git checkout "$ref" -- "$mpath" >> "$branchlog" 2>&1
        ;;
        "DD" | "UD")
        git rm "$mpath" >> "$branchlog" 2>&1
        ;;
        "AU")
        git rm "$mpath" >> "$branchlog" 2>&1
        # Unsure about this, but guessing delete might be less wrong
        ;;
        *)
        # This is merged or untracked, so ignore
        ;;
      esac
    done
    GIT_EDITOR=true git cherry-pick --allow-empty --continue >> "$branchlog" 2>&1 || give_up
  fi
done

git checkout "$prev_branch" > /dev/null 2>&1
