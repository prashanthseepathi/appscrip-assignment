End-to-End EKS + ArgoCD + GitOps (NGINX App) Setup Documentation

✅ Prerequisites
AWS CLI configured (aws configure)
Terraform installed
kubectl installed
GitHub repository ready (for example: https://github.com/<your-username>/nginx-k8s.git)


🚀 Step 1: Provision EKS Cluster Using Terraform
Use Terraform to provision the following:
Custom VPC
IAM roles for EKS and Fargate
EKS Cluster with version 1.32
Fargate profile for namespace default
EKS add-ons: kube-proxy, coredns, vpc-cni



✅ After creating the infrastructure, configure kubectl:
 Install kubectl (if not already installed)
To interact with the EKS cluster from your test server, you must install the appropriate version of kubectl:
# Download the EKS-compatible kubectl binary
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.0/2025-05-01/bin/linux/arm64/kubectl


# Make it executable
chmod +x ./kubectl


# Move it to a directory in your PATH
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH


(Optional): Make the change permanent by adding it to your shell's startup file:
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc


🧠 Tip: If you're using zsh, replace .bashrc with .zshrc.

aws eks update-kubeconfig --region us-east-1 --name eks-cluster-appscrip



🎯 Step 2: Install ArgoCD on EKS
# Create namespace
kubectl create namespace argocd

# Install ArgoCD via official manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml



⏳ Step 3: Verify ArgoCD Pods

kubectl get pods -n argocd


Wait until all pods are in Running status.

🌐 Step 4: Expose ArgoCD UI (LoadBalancer)

CopyEditkubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get external access URL
kubectl get svc argocd-server -n argocd

You'll get a LoadBalancer hostname like:

https://a30c59071f3d94680903de34c83538f1-1082177665.us-east-1.elb.amazonaws.com



🔐 Step 5: Get ArgoCD Admin Password

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo


Login with:
Username: admin


Password: (output from the command above)



📁 Step 6: Git Repository Structure for NGINX App
Your Git repo structure:

manifests/
├── base
│   ├── deployment.yaml
│   └── service.yaml
├── kustomization.yaml
└── overlays
    └── dev
        └── kustomization.yaml



📦 Step 7: ArgoCD Application YAML
From the ArgoCD UI → Create App → Edit as YAML, paste the following:

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-app
  namespace: argocd
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/<your-username>/nginx-k8s.git
    targetRevision: main
    path: base
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true


Click Create and then Sync.

🔍 Step 8: Verify NGINX Deployment

kubectl get pods -n default
kubectl get svc -n default


You should see your NGINX app running and exposed.

Step 9: 🔍 Test NGINX Locally via Port Forwarding
If you're not exposing NGINX via LoadBalancer or Ingress, you can still test it locally using port forwarding:

kubectl port-forward --address 0.0.0.0 svc/nginx-service 8080:80



http://localhost:8080


You should see the NGINX welcome page or your custom app output.
💡 Note:
--address 0.0.0.0 makes it accessible to other systems on your network (if firewall allows it).


Without it, it defaults to localhost only.


To stop port-forwarding, use Ctrl + C.

📘 Summary
Component
Technology
Infrastructure
Terraform
Kubernetes
EKS (Fargate)
GitOps Controller
ArgoCD
App Source
GitHub
CI/CD Strategy
GitOps (Auto Sync via ArgoCD)


