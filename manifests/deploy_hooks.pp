# This class sets the files needed for command-center to identify the
# applications needed to be installed on a particular system.
class apps::deploy_hooks (
  $ensure,
  $app,
) inherits apps {

  if $ensure == 'present' {

    $restart_script = "${apps::hooks_path}/restart.sh"
    $predeploy_hooks_path = "${apps::hooks_path}/predeploy.d"
    $postdeploy_hooks_path = "${apps::hooks_path}/postdeploy.d"
    $prerestart_hooks_path = "${apps::hooks_path}/prerestart.d"
    $postrestart_hooks_path = "${apps::hooks_path}/postrestart.d"

    file { $apps::hooks_path:
      ensure => directory,
      owner  => $apps::user,
      group  => $apps::group,
      mode   => '0777',
    }

    if $apps::restart == false {
      file { $restart_script:
        ensure => absent,
        force  => true,
      }
    }

    case $apps::type {
      'rolling': {
        file { [
          $predeploy_hooks_path,
          $postrestart_hooks_path,
          ]:
          ensure => directory,
          owner  => $apps::user,
          group  => $apps::group,
          mode   => '0755',
        }

        file { "${apps::hooks_path}/predeploy.d/01-predeploy.sh":
          ensure => file,
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
          source => "${apps::puppet_path}/01-predeploy.sh",
        }

        file { "${apps::hooks_path}/postrestart.d/01-postrestart.sh":
          ensure => file,
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
          source => "${apps::puppet_path}/01-postrestart.sh",
        }

        #       file { "/etc/nginx/vhost.d/healthcheck.conf":
        #  ensure  => file,
        #  owner   => 'root',
        #  group   => 'root',
        #  mode    => '0644',
        #  content => template("apps/healthcheck.conf.erb"),
        #}

        file { "${apps::root_path}/deployenv":
          ensure  => file,
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => template('apps/deployenv.erb'),
        }

        if $apps::restart {
          file { $restart_script:
            ensure  => present,
            source  => "${apps::puppet_path}/restart.sh",
            owner   => $apps::user,
            group   => $apps::group,
            mode    => '0755',
            require => File[$apps::hooks_path],
          }
        }
      }

      'custom': {
        if $apps::restart {
          file { $restart_script:
            ensure  => present,
            source  => "${apps::puppet_path}/restart.sh",
            owner   => $apps::user,
            group   => $apps::group,
            mode    => '0755',
            require => File[$apps::hooks_path],
          }
        }
      }

      'shell': {
        include ::apps::deploy_hooks::shell
      }
      default: { fail ( "Unknown deploy hook type ${apps::type}" ) }
    }

  } else {

    file { $apps::hooks_path:
      ensure  => absent,
      recurse => true,
      force   => true,
    }

  }
}
