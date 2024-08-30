Example build to Google Cloud Build

```
# These might be okay for defaults
export _LOCATION="us-central1"
export _REPOSITORY="vscider"
export _IMAGE="vscider:latest"

# Change this to project-it that will store the latest version
export _PROJECT_ID=<your-project-id>
export _PROJECT_NUMBER=$(gcloud projects describe "$_PROJECT_ID" --format="value(projectNumber)")
```

```
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_PROJECT_ID=${_PROJECT_ID},_PROJECT_NUMBER=${_PROJECT_NUMBER},_LOCATION=${_LOCATION},_REPOSITORY=${_REPOSITORY},_IMAGE=${_IMAGE} .
```
