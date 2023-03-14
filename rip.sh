#!/bin/bash
#
#  Name: rip.sh
#  Purpose: To pull unique resource IDs from all workspaces in a Project
#  Author: Dan Fedick
#  Usage: ./rip.sh <org> <project>
########################################
#set -x #Uncomment to Debug


TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json |jq -r '.credentials."app.terraform.io".token')

#This could also be done by adding the credential into 1password Private vault and accessing the password programmatically.  You will be required to login to 1password. 
#TOKEN=$(op item get --vault "Private" tfcb-token --fields label=credential)

# Get the project ID: 

ORG=$1
PROJ=$2

if [ -z $ORG ]; then echo "Usage: $0 <org> <project>";  exit 1; fi
if [ -z $PROJ ]; then echo "Usage: $0 <org> <project>";  exit 1; fi
if [ "$1" == "-h" ]; then echo "Usage: $0 <org> <project>";  exit 1; fi


function get_project_id() {
curl -s \
  --request GET \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/${ORG}/projects |jq -r '.data[]|select(.type=="projects")' |jq -r '.attributes.name + " " + .id' |grep "^$PROJ"|awk '{print $2}'
}


function get_workspace_ids() {
proj_id=$1
curl -s \
  --request GET \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/${ORG}/workspaces |jq -r '.data[]|select(.type=="workspaces")'|jq -r '.|select(.relationships.project.data.id=='\"$proj_id\"')'|jq -r .id
}


function get_resource_ids() {
ws=$1
curl -s \
  --request GET \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/workspaces/${ws}/resources | jq -r '.data[]|select(.type=="resources")' |jq -r '.attributes.address +  " " + .id'|column -t
}


PROJ_ID=$(get_project_id)
WORKSPACE_IDS=$(get_workspace_ids $PROJ_ID)

for ws in $WORKSPACE_IDS
do
  echo "Project: $PROJ_ID"
  echo "Workspace: $ws"
  count=$(get_resource_ids $ws|wc -l)
  echo Count: $count
  if [[ $count -eq 0 ]]
  then
    echo "No resources in Workspace"
  else
    get_resource_ids $ws
  fi
  echo ""
done


