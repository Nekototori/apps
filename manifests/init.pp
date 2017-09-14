# This is a fresh start from the included code
# and is locked to deploying command-center on centos 7 for now.
class apps (
  String $application_name = $apps::params::application_name,
  String $application_description = $apps::params::application_description,
  String $user = $apps::params::user,
  String $group = $apps::params::group,
  String $server_port = $apps::params::server_port,
  Array  $app_ports = $apps::params::app_ports,
  String $service_type = $apps::params::service_type,
  String $service_restart = $apps::params::service_restart,
  Hash $environment = $apps::params::environment,
  String $error_log_file = $apps::params::error_log_file,
  String $env = $apps::params::env

) inherits apps::params {
  class { 'apps::deploy_hooks' :
    ensure => present,
    app    => $application_name,
  }

  # Since rock is a dependency, we want to ensure rock
  # is included.
  include rock

  file { '/opt/apps':
    ensure => directory,
  }

  file { [$apps::root_path, $apps::data_path, $apps::logs_path, $apps::var_path, $apps::conf_path]:
    ensure  => directory,
    owner   => $apps::user,
    group   => $apps::group,
    mode    => '0777',
    require => File['/opt/apps'],
  }

  file { "${apps::root_path}/run":
    ensure  => file,
    mode    => '0755',
    content => epp('apps/run.epp'),
    require => File['/opt/apps'],
  }
  file { "${apps::root_path}/env":
    ensure  => file,
    content => epp('apps/rock_env.epp'),
    require => File['/opt/apps'],
  }

  # We also want to stage the service via systemd
  $app_ports.each | $port | {
    systemd::service { "${application_name}_${port}":
      description => $application_description,
      type        => $service_type,
      user        => $user,
      group       => $group,
      execstart   => "/opt/apps/${application_name}/run rock --path /opt/apps/${application_name}/deployment run_web",
      pid_file    => "/opt/apps/${application_name}/master.pid",
      restart     => $service_restart,
      env_vars    => [
        "HTTP_PORT=${port}"
      ],
      before      => Service["${application_name}_${port}"],
    }
    service { "${application_name}_${port}":
      enable => true,
    }
  }
}
