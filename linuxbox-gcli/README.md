# Custom Linux Desktop Cloud Workstation

Example build to Google Cloud Build. This setup uses a headless base image (`predefined/base`) and installs the Sway window manager, Visual Studio Code (desktop), and development dependencies directly via the Dockerfile and Nix.

```md
export _PROJECT_ID=$(gcloud config get-value project)
export _LOCATION="us-east4"
export _IMAGE="vscider-gcli"
```

## Quick Start

Submit the build to Cloud Build:

```bash
gcloud builds submit --config=cloudbuild.yaml --project=${_PROJECT_ID} \
  --region=${_LOCATION} \
  --substitutions=_LOCATION=${_LOCATION},_IMAGE=${_IMAGE} .
```

After the image is built and pushed to Artifact Registry, use the Google Cloud Console to create a Workstation Cluster and Configuration pointing to this new custom image.

```
gcloud workstations start-tcp-tunnel \
  --project=prj-sheikah-slate \
  --region=us-east4 \
  --cluster=cluster-use4 \
  --config=config-vscider-gcli \
  --workstation=gcli \
  22 --local-host-port=localhost:2222
```