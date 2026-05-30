# Module: eks

Provisions the EKS cluster, managed node groups, managed add-ons, and all IRSA roles. IRSA roles are created here (not in the `iam` module) because they require the cluster OIDC provider URL, which only exists after the cluster is provisioned.

## Cluster configuration

- **Version:** 1.34 (set via `kubernetes_version`, defaulted to `"1.34"`)
- **API endpoint:** Private only by default (`endpoint_public_access = false`) — access via DevOps EC2 through SSM
- **Secrets encryption:** KMS at rest for Kubernetes Secrets
- **Control plane logs:** All log types enabled (api, audit, authenticator, controllerManager, scheduler)
- **IMDSv2:** Required on all node launch templates
- **EBS:** gp3, encrypted with KMS, on all nodes

## IRSA roles created

| Role | Service Account | Namespace |
|---|---|---|
| `irsa-vpc-cni` | `aws-node` | `kube-system` |
| `irsa-ebs-csi` | `ebs-csi-controller-sa` | `kube-system` |
| `irsa-efs-csi` | `efs-csi-controller-sa` | `kube-system` |
| `irsa-lb-controller` | `aws-load-balancer-controller` | `kube-system` |
| `irsa-cluster-autoscaler` | `cluster-autoscaler` | `kube-system` |

## Node groups

Configured via the `node_groups` map variable. Example for production:

```hcl
node_groups = {
  general = {
    instance_types = ["m5.xlarge"]
    capacity_type  = "ON_DEMAND"
    desired_size   = 3
    min_size       = 2
    max_size       = 10
    disk_size_gb   = 50
    labels         = {}
    taints         = []
  }
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `project` | string | yes | Project prefix |
| `environment` | string | yes | Environment |
| `kubernetes_version` | string | no | Default `"1.34"` |
| `cluster_role_arn` | string | yes | From `iam` module |
| `node_group_role_arn` | string | yes | From `iam` module |
| `private_app_subnet_ids` | list(string) | yes | Node group subnets |
| `cluster_sg_id` | string | yes | From `security-groups` module |
| `kms_key_arn` | string | yes | KMS key for secrets encryption |
| `endpoint_public_access` | bool | no | Default `false` |
| `node_groups` | map(object) | yes | Node group configs |
| `addon_versions` | object | yes | Explicit add-on version pins |
| `tags` | map(string) | no | Common tags |

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | Used in kubeconfig and other modules |
| `cluster_endpoint` | EKS API server URL |
| `oidc_provider_arn` | Used to attach additional IRSA roles |
| `irsa_lb_controller_role_arn` | Annotate the LB controller service account |
| `irsa_cluster_autoscaler_role_arn` | Annotate the cluster-autoscaler service account |
