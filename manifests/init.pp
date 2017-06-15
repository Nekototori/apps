# This is a fresh start from the included code
# and is locked to deploying command-center for now.
class apps (
  $application_name = 'command-center',
  $user = 'root',
  $group = 'root',
  $port = '80',
) {
  $root_path = "/opt/apps/${application_name}"
  $data_path = "${root_path}/data"
  $logs_path = "${root_path}/logs"
  $var_path  = "${root_path}/var"
  $conf_path = "${root_path}/conf"
  $deps_path = "${root_path}/deployment"
  $repo_path = "${root_path}/deployment"

  $healthcheck_port    = "2525"
  $delay               = "5"
  $server_port         = $port
  $app_host            = "localhost"
  $app_healthcheck_url = "/healthcheck.html"
  $app_ports           = []

# The mystery env variable that does things like set other
# things whose wicked web is yet untangled.
  $env = 'dev'

  apps::deploy_hooks { 'rolling_deploy':
    ensure => present,
    app    => $application_name,
  }

  # Since rock is a dependency, we want to ensure rock
  # is included.
  include rock

  file { '/opt/apps':
    ensure => directory,
  }

  file { [$root_path, $data_path, $logs_path, $var_path, $conf_path]:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0777',
    require => File['/opt/apps'],
  }

  file { "${root_path}/run":
    ensure  => file,
    content => epp('apps/run.epp'),
    require => File['/opt/apps'],
  }
  file { "${root_path}/env":
    ensure  => file,
    content => epp('apps/rock_env.epp'),
    require => File['/opt/apps'],
  }
}
