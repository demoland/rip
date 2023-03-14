#RIP: Resources In Project

The Terraform API sets a unique identifier for every resource in Terraform.  
In order to get the list of resources in a project, you have to have two inputs to this script: 

*This is a simple script that:*

* Gets the Project ID
* Gets the list of workspaces in a Project
* Iterates over the list of workspace
* Prints the list of resources in a Workspace 


The following 

### Set Token Variable: 

TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json |jq -r '.credentials."app.terraform.io".token')

This could also be done by adding the credential into 1password Private vault and accessing the password programmatically.  You will be required to login to 1password. 

TOKEN=$(op item get --vault "Private" tfcb-token --fields label=credential)

### Get the Project ID based on the Name of the project
```bash
project="PROJNAME" 
curl -s \
  --request GET \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/demo-land/projects |jq -r '.data[]|select(.type=="projects")' |jq -r '.attributes.name + " " + .id' |grep "^$project "|awk '{print $2}'
```

### Get the list of workspace ids in a project
```bash
org=demo-land
proj=prj-xxxxxxx
curl -s \
  --request GET \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/${org}/workspaces |jq -r '.data[]|select(.type=="workspaces")'|jq -r '.|select(.relationships.project.data.id=='\"$proj\"')'|jq -r .id
```

### Get the list of resources in a workspace
```bash
ws=$1
curl -s \
  --request GET \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/workspaces/${ws}/resources | jq -r '.data[]|select(.type=="resources")' |jq -r '.attributes.address +  " " + .id'|column -t
```
