Example build to Google Cloud Build

```
export _LOCATION="us-central1"
export _REPOSITORY="ide-vscode"
export _IMAGE="vscode:latest"
export _PROJECT_ID=<>
```

```
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_PROJECT_ID=${_PROJECT_ID},_LOCATION=${_LOCATION},_REPOSITORY=${_REPOSITORY},_IMAGE=${_IMAGE} .
```
