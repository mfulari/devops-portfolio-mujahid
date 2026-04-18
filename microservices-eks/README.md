Sample Microservices Code
This document contains the sample code for the two microservices you'll be working with during the hackathon: Patient Service and Appointment Service.

DevOps Use Case: Deploy a Containerized App to Kubernetes via GitHub Actions

Problem Statement: -

Modern application teams need a reliable and automated way to deploy containerized applications to Kubernetes whenever new code changes are pushed. Manual deployments are error-prone, time-consuming, and lack consistency across environments. Additionally, teams require integration with CI/CD pipelines to ensure:

•	Automated builds and deployments

•	Version-controlled infrastructure

•	Faster release cycles

•	Reduced human intervention

•	Build a Docker image

•	Scan vulnerabilities using SonarQube.

•	Push it to a container registry (e.g., Docker Hub or GitHub Container Registry)

•	Deploy the updated image to a Kubernetes cluster (Minikube or cloud)

Prerequisites: -

•	Kubernetes cluster (Minikube or  AKS)

•	kubectl configured

•	Container registry credentials (Docker Hub or GHCR)

•	GitHub repository with your app code


Test: -

•	Push code to main

•	GitHub Actions will: 

o	Build & push Docker image

o	Apply Kubernetes manifests


Outcome: - 

Fully automated deployment pipeline triggered by code changes.

Consistent and secure deployments to Kubernetes.

Improved developer productivity and faster time-to-market.

Follow security best practices.

