Example build to Google Cloud Build

```md
# These might be okay for defaults
export _PROJECT_ID=$(gcloud config get-value project)
export _LOCATION="us-central1"
export _IMAGE="vscider"
```

```bash
gcloud builds submit --config=cloudbuild.yaml --project=${_PROJECT_ID} \
  --region=${_LOCATION} \
  --substitutions=_LOCATION=${_LOCATION},_IMAGE=${_IMAGE} .
```
