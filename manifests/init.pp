# This is a fresh start from the included code
# and is locked to deploying command-center for now.
class apps (
  $application_name = $apps::params::application_name,
  $user = $apps::params::user,
  $group = $apps::params::group,
  $port = $apps::params::server_port,
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
