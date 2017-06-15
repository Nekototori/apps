class apps::deploy_hooks (
  $app,
  $base_path = '/opt/apps',
  $ensure = 'absent',
  $type = 'rolling',
  $user = 'ssuser',
  $group = 'ssgroup',
  $restart = false,
  $predeploy = false,
  $postdeploy = false,
  $prerestart = false,
  $postrestart = false,
) inherits apps {

  if $ensure == 'present' {

    $restart_script = "${hooks_path}/restart.sh"
    $predeploy_hooks_path = "${hooks_path}/predeploy.d"
    $postdeploy_hooks_path = "${hooks_path}/postdeploy.d"
    $prerestart_hooks_path = "${hooks_path}/prerestart.d"
    $postrestart_hooks_path = "${hooks_path}/postrestart.d"

    file { $hooks_path:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0777'
    }

    if $restart == false {
      file { $restart_script:
        ensure => absent,
        force  => true,
      }
    }

    case $type {
      'rolling': {
        file { [
                 "${apps_path}/${application_name}/predeploy.d/",
                 "${apps_path}/${application_name}/postrestart.d/"
               ]:
          ensure => directory,
          user   => $user,
          group  => $group,
          mode   => '0755',
       }

       file { "${hooks_path}/predeploy.d/01-predeploy.sh":
         ensure => file,
         user   => 'root',
         group  => 'root',
         mode   => '0755',
         source => "${puppet_path}/01-predeploy.sh"
       }

       file { "${hooks_path}/postrestart.d/01-postrestart.sh":
         ensure => file,
         user   => 'root',
         group  => 'root',
         mode   => '0755',
         source => "${puppet_path}/01-postrestart.sh"
       }

       file { "/etc/nginx/vhost.d/healthcheck.conf":
         ensure => file,
         user   => 'root',
         group  => 'root',
         mode   => '0644',
         source => template("apps/healthcheck.conf.erb"),
       }

       file { "${base_path}/deployenv":
         ensure => file,
         user   => 'root',
         group  => 'root',
         mode   => '0644',
         source => template("apps/deployenv.erb"),
       }

        if $restart {
          file { $restart_script:
            ensure  => present,
            source  => "${puppet_path}/restart.sh",
            user    => $user,
            group   => $group,
            mode    => '0755',
            require => File[$hooks_path],
          }
        }
      }

      'custom': {
        if $restart {
          file { $restart_script:
            ensure  => present,
            source  => "${puppet_path}/restart.sh",
            user    => $user,
            group   => $group,
            mode    => '0755',
            require => File[$hooks_path],
          }
        }
      }

      'shell': {
        include apps::deploy_hooks::shell
      }
      default: { fail ( "Unknown deploy hook type ${type}" ) }
    }

  } else {

    file { $hooks_path:
      ensure  => absent,
      recurse => true,
      force   => true,
    }

  }
}
