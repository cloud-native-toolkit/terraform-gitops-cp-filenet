module "gitops_pull_secret" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-pull-secret.git"

   gitops_config = module.gitops.gitops_config
   git_credentials = module.gitops.git_credentials
   server_name = module.gitops.server_name
   namespace = module.gitops_namespace.name
   kubeseal_cert = module.gitops.sealed_secrets_cert
   docker_server = var.docker_server
   docker_username = var.docker_username
   docker_password = var.cp_entitlement_key
   secret_name    =var.registry_key_name
}