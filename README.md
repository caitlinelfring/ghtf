# Terraform import script for GitHub

Script to import a GitHub repo, default branch, and branch protections into Terraform.

**NOTE:** This script will clean up all generated `*.tf` files and any local statefiles in this directory before each run.

**Please don't use a remote statefile for running this. I suggest importing all your
repos into a local statefile and then importing them into your remote statefile to
avoid destroying anything accidentally.**

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
./run.sh repo_name1 repo_name2
```

You should see `repo_name1.tf` and `repo_name2.tf` created once the script finishes
and you should see `No changes. Infrastructure is up-to-date.` if everything was successful.

### Running against multiple repos

You can also supply repo names via a text file with:

```bash
./run.sh "$(< repos.txt)"
```

where `repos.txt` is a text file with each repo listed on its own line.

For example:

```text
repo_name1
repo_name2
```
