# Terraform import script for GitHub

Script to import a GitHub repo, default branch, and branch protections into Terraform.

**NOTE:** This script will clean up all generated `*.tf` files and any local statefiles in this directory before each run.

It uses local state files to handle the initial importing, but will use whatever statefile you have configured.

## Configure

Create a [GitHub personal access token](https://github.com/settings/tokens/new) with
`read:discussion, read:org, repo` scopes.

Save this and the github org owner/user to `secrets.auto.tfvars` (or however you like to
configure [Terraform input variables](https://www.terraform.io/docs/language/values/variables.html))

```bash
cat > secrets.auto.tfvars <<EOF
github_owner = "octocat"
github_token = "PAT"
EOF
```

## Running

Supports only terraform `0.12` right now.

```bash
./run.sh repo_name
```

You should see `repo_name.tf` created once the script finishes and you should see
`No changes. Infrastructure is up-to-date.` if everything was successful.
