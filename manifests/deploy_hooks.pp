# This class generates files based on the type set in the apps class.
#
# It is a private class and should not be declared directly.
#
class apps::deploy_hooks inherits apps {

# Provide a warning if this class is tried to be called directly.
  if $caller_module_name != $module_name {
        warning('apps::deploy_hooks is private and should not be called directly. Use apps')
          }

  if $apps::deploy_hooks == true {


    file { $apps::hooks_path:
      ensure => directory,
      owner  => $apps::user,
      group  => $apps::group,
      mode   => '0777',
    }

    if $apps::restart == false {
      file { $apps::restart_script:
        ensure => absent,
        force  => true,
      }
    }

    case $apps::type {
      'rolling': {
        file { [ $apps::predeploy_hooks_path, $apps::postrestart_hooks_path ]:
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

        file { "${apps::root_path}/deployenv":
          ensure  => file,
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => epp('apps/deployenv.epp'),
        }

        if $apps::restart {
          warning('You\'ve set something that hasn\'t been configured! Beware!')
          #          file { $apps::restart_script:
          #  ensure  => present,
          #  source  => "${apps::puppet_path}/restart.sh",
          #  owner   => $apps::user,
          #  group   => $apps::group,
          #  mode    => '0755',
          #  require => File[$apps::hooks_path],
          #}
        }
      }
      # Only a rolling deploy exists. The file referenced for custom never survived the inquisition.
      'custom': {
        warning('You\'ve set something that hasn\'t been configured! Beware!')
          # if $apps::restart {
          #file { $apps::restart_script:
          #  ensure  => present,
          #  source  => "${apps::puppet_path}/restart.sh",
          #  owner   => $apps::user,
          #   group   => $apps::group,
          #  mode    => '0755',
          #  require => File[$apps::hooks_path],
          #}
          # }
      }
      # Shell doesn't do anything. Was not setup/migrated.
      'shell': {
        warning('You\'ve set something that hasn\'t been configured! Beware!')
        #        include apps::deploy_hooks::shell
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
