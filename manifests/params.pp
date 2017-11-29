# Discovered and actually in use parameters for this module.
class apps::params {
  $application_name = 'test_application'
  $application_description = 'This is a test application'
  $root_path        = "/opt/apps/${application_name}"
  $data_path        = "${root_path}/data"
  $logs_path        = "${root_path}/logs"
  $var_path         = "${root_path}/var"
  $conf_path        = "${root_path}/conf"
  $deps_path        = "${root_path}/deployment"
  $repo_path        = "${root_path}/deployment"
  $deploy_hooks     = true
  $hooks_path       = "${root_path}/hooks"
  $restart_script = "${hooks_path}/restart.sh"
  $predeploy_hooks_path = "${hooks_path}/predeploy.d"
  $postdeploy_hooks_path = "${hooks_path}/postdeploy.d"
  $prerestart_hooks_path = "${hooks_path}/prerestart.d"
  $postrestart_hooks_path = "${hooks_path}/postrestart.d"
  # Don't know what restart does, but currently is false.
  $restart = false
  $service_type = 'simple'
  $service_restart = 'no'
  $type = 'rolling'
  $user  = 'root'
  $group = 'root'

  $healthcheck_port    = '2525'
  $delay               = '5'
  $server_port         = '80'
  $app_ports           = ['8000', '8001']
  $app_host            = 'localhost'
  $app_healthcheck_url = '/healthcheck.html'

  $error_log_file = "${logs_path}/json.error.log"
  $env = 'dev'
  $environment = {
    'ERROR_LOG_FILE'         => $error_log_file,
  }
  $puppet_path = 'puppet:///modules/apps/deploy_hooks/rolling'
}
