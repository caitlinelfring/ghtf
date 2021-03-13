#!/bin/bash

# https://github.com/hashicorp/learn-terraform-import

# mv_state will move the state of an object from one statefile to the default statefile
mv_state() {
  local state="${1}"
  local ref="${2}"
  terraform state mv \
    -state="${state}" -state-out="terraform.tfstate" \
    "${ref}" "${ref}"
}

# import_repo will run a terraform import to pull in the existing repo
# and generate valid terraform config based on the import
import_repo() {
  local repo="${1}"
  mkdir -p "state/${repo}"
  local state="state/${repo}/repo.tfstate"
  rm -f "${state}"
  local tmp="${repo}_repo_tmp.tf"

  echo "resource \"github_repository\" \"${repo}\" {}" > "${tmp}"
  terraform import -state="${state}" "github_repository.${repo}" "${repo}"
  terraform show -no-color "${state}" > "${tmp}"

  # Clean up unsupported fields
  gsed -E '/(full_name|etag|git_clone_url|node_id|http_clone_url|ssh_clone_url|repo_id|svn_url|private|html_url|id|default_branch)/d' "${tmp}" >> "${repo}.tf"

  mv_state "${state}" "github_repository.${repo}"

  rm -f "${state}" "${tmp}"
}

# import_branch_protections will run a terraform import to pull in the existing branch protection
# (for the default branch only right now) and generate valid terraform config based on the import
import_branch_protections() {
  local repo="${1}"
  local state="state/${repo}/branch_protection.tfstate"
  local tmp="${repo}_branch_protection_tmp.tf"
  rm -f "${state}"
  trap "rm -f ${state} ${tmp}" RETURN
  mkdir -p "state/${repo}"

  local default_branch
  default_branch=$(get_default_branch "${repo}")

  echo 'resource "github_branch_protection" "'"${repo}-${default_branch}"'" {}' > "${tmp}"

  terraform import -state="${state}" "github_branch_protection.${repo}-${default_branch}" "${repo}:${default_branch}" || return

  terraform show -no-color "${state}" > "${tmp}"

  # convert repository_id to a reference
  gsed -i -E "s/(\s+repository_id\s+=\s+).*/\1github_repository.${repo}.node_id/" "${tmp}"
  terraform fmt -write=true "${tmp}"

  # Clean up unsupported fields
  gsed -E '/\s+(id)/d' "${tmp}" >> "${repo}.tf"

  mv_state "${state}" "github_branch_protection.${repo}-${default_branch}"
}

# import_default_branch will run a terraform import to pull in the existing default branch
# and will generate a valid terraform config for the branch and default branch
import_default_branch() {
  local repo="${1}"
  mkdir -p "state/${repo}"
  local state="state/${repo}/default_branch.tfstate"
  rm -f "${state}"
  local default_branch
  default_branch=$(get_default_branch "${repo}")

  # default_branch and branch are straightforward, there's no need to pull
  # them from state, can just create the config from scratch
  cat >> "${repo}.tf" << EOF

resource "github_branch" "${repo}-${default_branch}" {
  repository = github_repository.${repo}.name
  branch     = "${default_branch}"
}

resource "github_branch_default" "${repo}" {
  repository = github_repository.${repo}.name
  branch     = github_branch.${repo}-${default_branch}.branch
}

EOF

  terraform import "github_branch.${repo}-${default_branch}" "${repo}:${default_branch}"
  terraform import "github_branch_default.${repo}" "${repo}"
}

# get_default_branch outupts the default branch for the repo
get_default_branch() {
  local repo="${1}"
  terraform state show -no-color "github_repository.${repo}" \
    | grep default_branch \
    | awk '{print $3}' \
    | tr -d '"'
}

import() {
  local repo="${1}"
  rm -f "${repo}"*.tf
  import_repo "${repo}"
  import_default_branch "${repo}"
  import_branch_protections "${repo}"
}

if [ "$#" == 0 ]; then
  echo "Usage: $0 [repo_names...]"
  exit 1
fi
# Delete local state before running. WARNING! You can't go back from this!!!
rm -f terraform.tfstate*
find . -name "*.tf" ! -name "main.tf" -delete

for repo in "$@"; do
  import "${repo}"
done

terraform fmt -write
terraform plan
