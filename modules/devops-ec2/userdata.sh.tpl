#!/bin/bash
set -euo pipefail

# Update system
dnf update -y

# Install core tools
dnf install -y git jq unzip curl tar

# AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# kubectl — version aligned with cluster
KUBECTL_VERSION="v1.34.0"
curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure kubectl for EKS cluster
aws eks update-kubeconfig \
  --region "${region}" \
  --name "${cluster_name}" \
  --kubeconfig /home/ec2-user/.kube/config

chown ec2-user:ec2-user /home/ec2-user/.kube/config
chmod 600 /home/ec2-user/.kube/config
