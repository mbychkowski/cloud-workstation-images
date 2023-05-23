Example build to Google Cloud Build

```
# These might be okay for defaults
export _LOCATION="us-central1"
export _REPOSITORY="ide-vscode"
export _IMAGE="vscode:latest"

# Change this to project-it that will store the latest version
export _PROJECT_ID=<project-id>
```

```
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_PROJECT_ID=${_PROJECT_ID},_LOCATION=${_LOCATION},_REPOSITORY=${_REPOSITORY},_IMAGE=${_IMAGE} .
```
