define apps::deploy_hooks (
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
) {

  $root_path = "${base_path}/${app}"
  $hooks_path = "${root_path}/hooks"

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
        $puppet_path = "puppet:///modules/apps/deploy_hooks/rolling"
        include apps::deploy_hooks::directory

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
        $puppet_path = "puppet:///modules/roles/${app}/deploy_hooks"
        include apps::deploy_hooks::directory

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
