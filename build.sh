#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables (Update these with your specific details)
PROJECT_ID="YOUR_PROJECT_ID"                # Replace with your GCP project ID
REGION="us-central1"                        # Replace with your desired region (e.g., us-central1, europe-west1)
SERVICE_NAME="metadata-app"                 # Replace with your desired Cloud Run Service/GCE VM name
REPO_NAME="my-docker-repo"                  # Replace with your desired Artifact Registry repo name (OR EXISTING REPO)

# Variables that can stay default if desired
IMAGE_NAME="my-app"                        # Replace with your Docker image name
TAG="latest"                               # Replace with your desired tag (default is 'latest')
DESCRIPTION="My Docker Repo"               # Replace with your desired description

# 1. Prompt the user to check if they've run gcloud init
read -p "Have you run 'gcloud init'? (yes/no): " AUTH

if [[ "$AUTH" != "yes" ]]; then
    echo "You need to authenticate with Google Cloud. Choose your account in the webpage..."
    gcloud auth login
    gcloud config set project $PROJECT_ID
else
    echo "Assuming gcloud is initalized and the CLI is authenticated."
fi



# 2. Ask the user if they have enabled the required APIs or executed the script before
read -p "Have you enabled the required APIs (Cloud Build, Artifact Registry, Cloud Run) or executed this script before? (yes/no): " API_CHECK

if [[ "$API_CHECK" == "no" ]]; then
    # Enable required APIs (Cloud Build, Artifact Registry, and Cloud Run)
    echo "Enabling required APIs..."
    gcloud services enable artifactregistry.googleapis.com
    gcloud services enable run.googleapis.com
    gcloud services enable cloudbuild.googleapis.com
else
    echo "Skipping API enabling step since the APIs are already enabled."
fi

# 3. Ask the user if they want to create a new repository or use an existing one
echo "Select an option:"
echo "1. Create a new Artifact Registry repository"
echo "2. Use an existing Artifact Registry repository"
read -p "Enter your choice (1 or 2): " REPO_ACTION

if [[ "$REPO_ACTION" == "1" ]]; then
    # Create an Artifact Registry repository (only needed once)
    echo "Creating Artifact Registry repository..."
    gcloud artifacts repositories create $REPO_NAME \
      --repository-format=docker \
      --location=$REGION \
      --description="$DESCRIPTION" || echo "Repository may already exist, continuing..."
elif [[ "$REPO_ACTION" == "2" ]]; then
    echo "Using existing Artifact Registry repository..."
else
    echo "Invalid option. Please choose '1' or '2'."
    exit 1
fi


# 4. Use Cloud Build to build and push the Docker image to Google Artifact Registry
echo "Building and pushing the Docker image to Artifact Registry using Cloud Build..."
gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG .

# 5. Optional: Verify the image exists in the repository
echo "Verifying the image in Artifact Registry..."
gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME

# Prompt the user for their choice of deployment
echo "Choose your deployment option:"
echo "1. Deploy the Docker image to Cloud Run"
echo "2. Deploy the Docker image to a COS VM with Docker"
read -p "Enter 1 or 2: " DEPLOYMENT_OPTION

# Check the user's choice and deploy accordingly
if [ "$DEPLOYMENT_OPTION" -eq 1 ]; then
    
    # 6A. Deploy the Docker image to Cloud Run
    echo "Deploying to Cloud Run..."
    echo "Ensure port 8080 is exposed in the Dockerfile and your app uses port 8080 or you use env variables"
    gcloud run deploy $SERVICE_NAME \
        --image $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG \
        --region $REGION \
        --platform managed \
        --allow-unauthenticated
elif [ "$DEPLOYMENT_OPTION" -eq 2 ]; then
    
    # 6B. Deploy the Docker image to a VM
    echo "Deploying to a COS VM..."
    echo "Port 5000 is used here; if your app uses env vars change line 100, but the address will be http://public_ip:exposed_port no matter what"
    gcloud compute instances create-with-container $SERVICE_NAME \
        --project=$PROJECT_ID \
        --zone=${REGION}-a \
        --machine-type=e2-medium \
        --container-image=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG \
        --container-restart-policy=always \
        --container-env=PORT=5000 \
        --tags=http-server \
        --image=projects/cos-cloud/global/images/cos-stable-117-18613-75-4

    # Ask the user if they need to open port 5000 or 8080
echo "Do you need to open port 5000 or 8080?"
echo "1. Open port 5000"
echo "2. Open port 8080"
echo "3. Open both ports 5000 and 8080"
echo "4. Do not open any ports"
read -p "Enter your choice (1, 2, 3, or 4): " PORT_OPTION

# Initialize the allowed ports variable
ALLOWED_PORTS=""

case "$PORT_OPTION" in
    1)
        ALLOWED_PORTS="5000"
        ;;
    2)
        ALLOWED_PORTS="8080"
        ;;
    3)
        ALLOWED_PORTS="5000,8080"
        ;;
    4)
        echo "No ports will be opened."
        exit 0
        ;;
    *)
        echo "Invalid option. Please choose '1', '2', '3', or '4'."
        exit 1
        ;;
esac

# Create the firewall rule with the selected ports
gcloud compute firewall-rules create allow-http-$SERVICE_NAME \
    --allow tcp:$ALLOWED_PORTS \
    --target-tags=http-server \
    --description="Allow traffic on ports $ALLOWED_PORTS for HTTP" \
    --direction=INGRESS \
    --priority=1000

echo "Firewall rule created to allow traffic on ports: $ALLOWED_PORTS"

    
else
    echo "Invalid option. Please run the script again and select either 1 or 2."
fi





# Confirmation Page
echo ""
echo "Container deployed!"
echo ""
echo "Image name: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG"



