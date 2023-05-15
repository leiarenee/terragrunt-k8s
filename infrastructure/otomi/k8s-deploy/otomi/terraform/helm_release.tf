provider "helm" {
  kubernetes {
    config_path = "${path.module}/.kubeconfig"
    config_context =  element(concat(data.aws_eks_cluster.cluster[*].arn, tolist([""])), 0)
  }
}

resource "helm_release" "otomi" {
  name = "otomi"

  repository = "https://otomi.io/otomi-core"
  chart      = "otomi"

  values = [
    file("${path.module}/values.yaml")
  ]
}
