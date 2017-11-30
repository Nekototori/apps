# This is a fresh start from the included code
# and is only tested with command-center on centos 7 for now.
#
# @example Declaring the class
#   class { 'apps':
#     application_name        => 'my_little_app',
#     application_description => 'The app that could.',
#     app_ports               => ['8004', '8005'],
#     env                     => $facts['ss_tier'],
#     deploy_hooks            => true,
#   }
#
# @param application_name [String] Specify the name of the application. This needs to match what
# command center expects in order to discover and deploy the application correctly.
# Default Value: 'test_application'
# @param application_description [String] Specify the description of the application. This is used
# in comments and service description to help provide unique or longer names than what command
# center needs purely for parsing.
# Default Value: 'This is a test application'
# @param user [String] Specifies the user to set on all the files this creates. Default Value: 'root'
# @param group [String] Specifies the group to set on all the files this creates. Default Value: 'root'
# @param server_port [String] Specifies the port that the web server should be listening on for this app.
# Default Value: 80.
# @param app_ports [Array] Specifies an array of ports for service and backend configuration.
# Default Value: ['8000', '8001']
# @param service_type [String] Specifies the type of service systemd will configure it with. See
# systemd documentation for more options.
# Default Value: 'simple'
# @param service_restart [String] Specify if you want the service to restart automatically or not.
# Accepts values of 'yes' or 'no'.
# Default Value: 'no'
# @param env [String] Allows for an override of the environment, in case you have a vagrant box or
# some other unique snowflake that doesn't work with the $facts['ss_tier'] call.
# Default Value: 'dev'
# @param deploy_hooks [Boolean] Specify whether you want to deploy hooks or not.
# Default Value: true
class apps (
  String $application_name = $apps::params::application_name,
  String $application_description = $apps::params::application_description,
  String $user = $apps::params::user,
  String $group = $apps::params::group,
  String $server_port = $apps::params::server_port,
  Array  $app_ports = $apps::params::app_ports,
  String $service_type = $apps::params::service_type,
  String $service_restart = $apps::params::service_restart,
  String $env = $apps::params::env,
  Boolean $deploy_hooks = $apps::params::deploy_hooks,

) inherits apps::params {

  # Set the parameters used elsewhere.
  $root_path        = "/opt/apps/${application_name}"
  $data_path        = "${root_path}/data"
  $logs_path        = "${root_path}/logs"
  $var_path         = "${root_path}/var"
  $conf_path        = "${root_path}/conf"
  $deps_path        = "${root_path}/deployment"
  $repo_path        = "${root_path}/deployment"
  $hooks_path       = "${root_path}/hooks"
  $restart_script = "${hooks_path}/restart.sh"
  $predeploy_hooks_path = "${hooks_path}/predeploy.d"
  $postdeploy_hooks_path = "${hooks_path}/postdeploy.d"
  $prerestart_hooks_path = "${hooks_path}/prerestart.d"
  $postrestart_hooks_path = "${hooks_path}/postrestart.d"
  $error_log_file = "${logs_path}/json.error.log"
  $environment = {
    'ERROR_LOG_FILE'         => $error_log_file,
  }

  # Depending on what deploy_hooks is set to, it will execute this
  # class and add the files, or remove the files.
  include apps::deploy_hooks

  # Since rock is a dependency, we want to ensure rock
  # is included. This will need to be addressed for other apps.
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
