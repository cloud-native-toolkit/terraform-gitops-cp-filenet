
resource null_resource write_outputs {
  provisioner "local-exec" {
    command = "echo \"$${OUTPUT}\" > gitops-output.json"

    environment = {
      OUTPUT = jsonencode({
        name        = module.cp-filenet.name
        branch      = module.cp-filenet.branch
        namespace   = module.cp-filenet.namespace
        server_name = module.cp-filenet.server_name
        layer       = module.cp-filenet.layer
        layer_dir   = module.cp-filenet.layer == "infrastructure" ? "1-infrastructure" : (module.cp-filenet.layer == "services" ? "2-services" : "3-applications")
        type        = module.cp-filenet.type
      })
    }
  }
}
