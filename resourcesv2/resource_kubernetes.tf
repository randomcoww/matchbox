locals {
  kubernetes_cluster_name = "default-cluster"
  s3_etcd_backup_bucket   = "randomcoww-etcd-backup"

  controller_hosts = {
    controller-0 = {
      network = {
        store_ip = "192.168.127.219"
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-0a"
      }
    }
    controller-1 = {
      network = {
        store_ip = "192.168.127.220"
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-0b"
      }
    }
    controller-2 = {
      network = {
        store_ip = "192.168.127.221"
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-0c"
      }
    }
  }

  worker_hosts = {
    worker-0 = {
      network = {
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-1a"
      }
    }
    worker-1 = {
      network = {
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-1b"
      }
    }
  }
}

resource "aws_iam_user" "s3-etcd-backup" {
  name = "s3-etcd-backup-${local.kubernetes_cluster_name}"
}

resource "aws_iam_access_key" "s3-etcd-backup" {
  user = aws_iam_user.s3-etcd-backup.name
}

resource "aws_iam_user_policy" "s3-etcd-backup-access" {
  name = aws_iam_user.s3-etcd-backup.name
  user = aws_iam_user.s3-etcd-backup.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = [
          "arn:aws:s3:::${local.s3_etcd_backup_bucket}/${local.kubernetes_cluster_name}",
          "arn:aws:s3:::${local.s3_etcd_backup_bucket}/${local.kubernetes_cluster_name}/*",
        ]
      }
    ]
  })
}

# Do this to each provider until for_each module is available
module "kubernetes-0" {
  source = "../modulesv2/kubernetes"

  user              = local.user
  mtu               = local.mtu
  networks          = local.networks
  services          = local.services
  domains           = local.domains
  container_images  = local.container_images
  controller_hosts  = local.controller_hosts
  worker_hosts      = local.worker_hosts
  ssh_ca_public_key = tls_private_key.ssh-ca.public_key_openssh
  ca                = local.ca

  cluster_name          = local.kubernetes_cluster_name
  s3_backup_aws_region  = "us-west-2"
  s3_etcd_backup_bucket = local.s3_etcd_backup_bucket
  aws_access_key_id     = aws_iam_access_key.s3-etcd-backup.id
  aws_secret_access_key = aws_iam_access_key.s3-etcd-backup.secret

  # Render to one of KVM host matchbox instances
  renderer = local.renderers.kvm-0
}

module "kubernetes-1" {
  source = "../modulesv2/kubernetes"

  user              = local.user
  mtu               = local.mtu
  networks          = local.networks
  services          = local.services
  domains           = local.domains
  container_images  = local.container_images
  controller_hosts  = local.controller_hosts
  worker_hosts      = local.worker_hosts
  ssh_ca_public_key = tls_private_key.ssh-ca.public_key_openssh
  ca                = local.ca

  cluster_name          = local.kubernetes_cluster_name
  s3_backup_aws_region  = "us-west-2"
  s3_etcd_backup_bucket = local.s3_etcd_backup_bucket
  aws_access_key_id     = aws_iam_access_key.s3-etcd-backup.id
  aws_secret_access_key = aws_iam_access_key.s3-etcd-backup.secret

  # Render to one of KVM host matchbox instances
  renderer = local.renderers.kvm-1
}

# Write admin kubeconfig file
resource "local_file" "kubeconfig-admin" {
  content = templatefile("${path.module}/../templates/manifest/kubeconfig_admin.yaml.tmpl", {
    cluster_name       = local.kubernetes_cluster_name
    ca_pem             = replace(base64encode(chomp(tls_self_signed_cert.ca["kubernetes-ca"].cert_pem)), "\n", "")
    private_key_pem    = replace(base64encode(chomp(tls_private_key.cert["kubernetes-client"].private_key_pem)), "\n", "")
    cert_pem           = replace(base64encode(chomp(tls_locally_signed_cert.cert["kubernetes-client"].cert_pem)), "\n", "")
    apiserver_endpoint = "https://${local.services.kubernetes_apiserver.vip}:${local.services.kubernetes_apiserver.ports.secure}"
  })
  filename = "output/${local.kubernetes_cluster_name}.kubeconfig"
}