class apps::params {
  $root_path  = "/opt/apps/${application_name}"
  $data_path  = "${root_path}/data"
  $logs_path  = "${root_path}/logs"
  $var_path   = "${root_path}/var"
  $conf_path  = "${root_path}/conf"
  $deps_path  = "${root_path}/deployment"
  $repo_path  = "${root_path}/deployment"
  $hooks_path = "${root_path}/hooks"

  $healthcheck_port    = "2525"
  $delay               = "5"
  $server_port         = $port
  $app_host            = "localhost"
  $app_healthcheck_url = "/healthcheck.html"
  $app_ports           = []

  $env = 'dev'

  $puppet_path = "puppet:///modules/apps/deploy_hooks/rolling"
}
