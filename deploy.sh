#!/bin/bash
# =============================================================================
# Student Guide AI Agent — Full Cloud Run Deployment Script
# Run this entirely in GCP Cloud Shell:
#   chmod +x deploy.sh && ./deploy.sh
# =============================================================================

set -e  # Exit immediately on any error

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — Edit these if needed
# ─────────────────────────────────────────────────────────────────────────────
PROJECT_ID="clear-style-491908-q4"
PROJECT_NUMBER="315961907444"
SA_NAME="lab2-cr-service"
SERVICE_ACCOUNT="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
MODEL="gemini-2.5-flash"
REGION="europe-west1"
REPO_NAME="student-guide-repo"
SERVICE_NAME="student-guide"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"
GITHUB_REPO="https://github.com/iamhriturajsaha/STUDENT-GUIDE-AI-AGENT"

# ─────────────────────────────────────────────────────────────────────────────
# COLORS for pretty output
# ─────────────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# STEP 0 — Set active project
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "======================================================"
echo "  Student Guide AI Agent — Cloud Run Deployment"
echo "======================================================"
echo ""

info "Setting active project to ${PROJECT_ID}..."
gcloud config set project "${PROJECT_ID}"
success "Project set."

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Enable required APIs
# ─────────────────────────────────────────────────────────────────────────────
info "Enabling required GCP APIs (this may take ~1 minute)..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  aiplatform.googleapis.com \
  logging.googleapis.com \
  iam.googleapis.com \
  --project="${PROJECT_ID}"
success "All APIs enabled."

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Create Service Account (if it doesn't already exist)
# ─────────────────────────────────────────────────────────────────────────────
info "Checking service account ${SERVICE_ACCOUNT}..."
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT}" --project="${PROJECT_ID}" &>/dev/null; then
  warn "Service account already exists — skipping creation."
else
  gcloud iam service-accounts create "${SA_NAME}" \
    --display-name="Student Guide CR Service Account" \
    --project="${PROJECT_ID}"
  success "Service account created."
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Grant IAM roles to the Service Account
# ─────────────────────────────────────────────────────────────────────────────
info "Granting IAM roles to ${SERVICE_ACCOUNT}..."

ROLES=(
  "roles/aiplatform.user"
  "roles/logging.logWriter"
  "roles/secretmanager.secretAccessor"
  "roles/artifactregistry.writer"
  "roles/run.invoker"
)

for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="${ROLE}" \
    --quiet
  success "  Granted ${ROLE}"
done

# Also grant Cloud Build the ability to deploy to Cloud Run
CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${CLOUD_BUILD_SA}" \
  --role="roles/run.admin" \
  --quiet
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${CLOUD_BUILD_SA}" \
  --role="roles/iam.serviceAccountUser" \
  --quiet
success "Cloud Build SA permissions granted."

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Create Artifact Registry repository
# ─────────────────────────────────────────────────────────────────────────────
info "Creating Artifact Registry repository '${REPO_NAME}' in ${REGION}..."
if gcloud artifacts repositories describe "${REPO_NAME}" \
    --location="${REGION}" \
    --project="${PROJECT_ID}" &>/dev/null; then
  warn "Artifact Registry repo already exists — skipping."
else
  gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Student Guide AI Agent Docker images" \
    --project="${PROJECT_ID}"
  success "Artifact Registry repository created."
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — Store Gemini API Key in Secret Manager
# ─────────────────────────────────────────────────────────────────────────────
info "Checking for GOOGLE_API_KEY secret in Secret Manager..."
if gcloud secrets describe "GOOGLE_API_KEY" --project="${PROJECT_ID}" &>/dev/null; then
  warn "Secret 'GOOGLE_API_KEY' already exists."
  warn "To update it, run: echo -n 'YOUR_KEY' | gcloud secrets versions add GOOGLE_API_KEY --data-file=-"
else
  echo ""
  echo -e "${YELLOW}──────────────────────────────────────────────────────${NC}"
  echo -e "${YELLOW}  You need a Gemini API key from:${NC}"
  echo -e "${YELLOW}  https://aistudio.google.com/app/apikey${NC}"
  echo -e "${YELLOW}──────────────────────────────────────────────────────${NC}"
  read -rsp "  Paste your Gemini API key and press Enter: " GEMINI_KEY
  echo ""

  if [[ -z "${GEMINI_KEY}" ]]; then
    error "No API key provided. Exiting."
  fi

  echo -n "${GEMINI_KEY}" | gcloud secrets create "GOOGLE_API_KEY" \
    --data-file=- \
    --replication-policy="automatic" \
    --project="${PROJECT_ID}"
  success "Secret 'GOOGLE_API_KEY' stored in Secret Manager."
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 — Clone repo into Cloud Shell and build the Docker image
# ─────────────────────────────────────────────────────────────────────────────
info "Cloning repo from GitHub..."
WORKDIR="${HOME}/student-guide-build"
rm -rf "${WORKDIR}"
git clone "${GITHUB_REPO}.git" "${WORKDIR}"
cd "${WORKDIR}"
success "Repo cloned to ${WORKDIR}."

info "Building Docker image with Cloud Build and pushing to Artifact Registry..."
info "Image: ${IMAGE}"
gcloud builds submit . \
  --tag="${IMAGE}" \
  --project="${PROJECT_ID}" \
  --timeout=15m
success "Docker image built and pushed successfully."

# ─────────────────────────────────────────────────────────────────────────────
# STEP 7 — Deploy to Cloud Run
# ─────────────────────────────────────────────────────────────────────────────
info "Deploying to Cloud Run service '${SERVICE_NAME}' in ${REGION}..."
gcloud run deploy "${SERVICE_NAME}" \
  --image="${IMAGE}" \
  --platform=managed \
  --region="${REGION}" \
  --service-account="${SERVICE_ACCOUNT}" \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=5 \
  --set-env-vars="MODEL=${MODEL},PROJECT_ID=${PROJECT_ID},PROJECT_NUMBER=${PROJECT_NUMBER}" \
  --set-secrets="GOOGLE_API_KEY=GOOGLE_API_KEY:latest" \
  --project="${PROJECT_ID}"

success "Cloud Run deployment complete!"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 8 — Print the live URL
# ─────────────────────────────────────────────────────────────────────────────
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="value(status.url)")

echo ""
echo "======================================================"
echo -e "${GREEN}  ✅ Deployment Successful!${NC}"
echo "======================================================"
echo -e "  🌐 Live URL: ${CYAN}${SERVICE_URL}${NC}"
echo ""
echo "  Test with:"
echo "    curl -X POST ${SERVICE_URL}/run \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"message\": \"What is Machine Learning?\"}'"
echo "======================================================"
