class apps::params {
  $application_name = 'command-center'
  $application_description = 'Command Center Web Server'
  $root_path        = "/opt/apps/${application_name}"
  $data_path        = "${root_path}/data"
  $logs_path        = "${root_path}/logs"
  $var_path         = "${root_path}/var"
  $conf_path        = "${root_path}/conf"
  $deps_path        = "${root_path}/deployment"
  $repo_path        = "${root_path}/deployment"
  $hooks_path       = "${root_path}/hooks"

  $service_type = 'simple'
  $service_restart = 'no'
  $type = 'rolling'
  $user  = 'root'
  $group = 'root'

  $healthcheck_port    = "2525"
  $delay               = "5"
  $server_port         = "80"
  $app_port            = ['8003', '8004']
  $app_host            = "localhost"
  $app_healthcheck_url = "/healthcheck.html"

  $error_log_file = "${logs_path}/json.error.log"
  $env = 'dev'
  $environment = {
    'ERROR_LOG_FILE'         => $error_log_file,
  }
  $puppet_path = "puppet:///modules/apps/deploy_hooks/rolling"
}
