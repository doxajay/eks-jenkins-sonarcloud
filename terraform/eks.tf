# ... your existing eks.tf above ...

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [
    aws_eks_node_group.default,
    aws_eks_cluster.main
  ]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = aws_iam_role.jenkins_role.arn
        username = "jenkins"
        groups   = ["system:masters"]
      }
    ])
  }
}
