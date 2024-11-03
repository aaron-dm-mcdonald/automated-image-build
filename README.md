# Automated Build/Deploy using shell script 

## Overview

This is an automated deployent script for GCP using the google cloud SDK. A test dockerfile and python app that is basically Flaskifying the metadata startup script is included for testing. This deployment is configured for COS VMs (like AWS ECS) or Cloud Run (KNative serverless deployment). The inner workings of these platforms is not overly critical. Firewall rules for the VM can be created in the script. The serverless deployment uses port 8080 always, but you can use enviormental variables as shown in this python script. 

## Instructions 
1) Git Clone to test repo or curl the build.sh script to use for your application.
2) Modify lines 6-10 in the build.sh. You should add your project ID at least. Each deployment should have a unique service name as well. 
3) (OPTIONAL) If lines 12-15 interest you, you  can edit them. 
4) You dont need to make a new GAR Repo. In fact, if you have one existing, you can use its name for the repo name variable. 
5) Make the script executable via ```chmod +x ./build.sh``` (or whatever the relative path is to the script)
6) Either execute ```gcloud init``` or allow the script to prompt you later for authenticate to GCP and setting project ID
7) Execute with ```./build.sh``` 
8) Answer prompts accordingly. Ensure the script is in the same directory as your Dockerfile, app.py, and requirements.txt. 

NOTE: So nobody points this out, yes, buildpacks are used here with cloud build so the explict dependencies (requirements.txt) are not strictly required, but they will be passed as an argument if present. 

NOTE 2: Given that Cloud Run is serverless, some metadata is unavailable. It still works fine. 