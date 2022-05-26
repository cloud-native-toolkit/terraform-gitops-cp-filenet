locals {
  name          = "cp-filenet"
  bin_dir       = module.setup_clis.bin_dir
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart"
  filenet_yaml_dir = "${local.yaml_dir}/cp4ba-filenet"
  db_yaml_dir = "${local.yaml_dir}/db-secret"
  ldap_yaml_dir = "${local.yaml_dir}/db-ldap"

  chart_dir = "${path.module}/chart"
  service_url   = "http://${local.name}.${var.namespace}"
  layer = "services"
  type  = "base"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
  db_port="${var.odm_db_port}"
  values_content = {
  "cp4ba" = {        
        namespace= var.namespace
        db_server= var.db_server
        odm_db_name= var.odm_db_name
        db_port= var.db_port
        db_type= var.db_type
        storageclass_block: var.storageclass_block
        storageclass_fast: var.storageclass_fast
        storageclass_medium: var.storageclass_medium
        storageclass_slow: var.storageclass_slow
        filenet_image_repository= var.filenet_image_repository
      #  odm_image_tag= var.odm_image_tag
     #   odm_image_version= var.odm_image_version
        }  
  "odmdbsecret"={
        namespace= var.namespace
        db_user= var.db_user
        db_password= var.db_password
    } 
     "odmldapsecret"={
        namespace= var.namespace
        ldapUsername= var.ldapUsername
        ldapPassword= var.ldapPassword
    } 
  values_file = "values-${var.server_name}.yaml"  
  }

}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.chart_dir}' '${local.filenet_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}


resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml]

  triggers = {
    #name = local.name
    name = local.name
    namespace = var.namespace
    yaml_dir = local.filenet_yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }


  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}

# Create DB Secret 
resource null_resource create_dbyaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-dbyaml.sh '${local.chart_dir}' '${local.db_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource null_resource setup_gitops_db {
  depends_on = [null_resource.create_dbyaml]

  triggers = {
    #name = local.name
    name = "db-secret"
    namespace = var.namespace
    yaml_dir = local.db_yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

 provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

}

# Create LDAP Secret 
resource null_resource create_ldapyaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-ldapyaml.sh '${local.chart_dir}' '${local.ldap_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource null_resource setup_gitops_ldap {
  depends_on = [null_resource.create_ldapyaml]

  triggers = {
    #name = local.name
    name = "ldap-secret"
    namespace = var.namespace
    yaml_dir = local.ldap_yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

}

