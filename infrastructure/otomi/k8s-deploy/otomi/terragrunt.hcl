locals {
  global_replacements = jsondecode(file(find_in_parent_folders("replace.json")))
  local_replacements = jsondecode(file("replace.json"))
  replacements = merge(local.global_replacements, local.local_replacements)
  inputs =  jsondecode(file("inputs.tfvars.json"))
  all_commands = ["apply", "plan","destroy","apply-all","plan-all","destroy-all","init","init-all"]
}

include {
 path = find_in_parent_folders()
}

terraform {
  source = ".//terraform"
  
  extra_arguments extra_args {
    commands = local.all_commands
    env_vars = {"k8s_dependency":false}
  }
  after_hook "after_hook_1" {
    commands     = ["apply"]
    execute      = ["bash","-c","kubectl logs jobs/otomi -f"]
   }
}

inputs = {
  replace_variables = merge(local.replacements,{})
  lineage = dependency.init.outputs.lineage
  
  # KMS
  kms_arn = dependency.kms.outputs.arn
  
}

dependency "kms" {
  config_path = "../../k8s-kms"
  mock_outputs = {
    arn = "mocked"
  } 
  mock_outputs_allowed_terraform_commands = ["validate, plan"]
}

dependency "init" {
  config_path = "../../init"
}

