class apps::deploy_hooks::directory {

  if $predeploy {
    file { $predeploy_hooks_path:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      source  => "${puppet_path}/predeploy",
      recurse => true,
      require => File[$hooks_path],
    }
  } else {
    file { $predeploy_hooks_path:
      ensure  => absent,
      force   => true,
      recurse => true,
    }
  }

  if $postdeploy {
    file { $postdeploy_hooks_path:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      source  => "${puppet_path}/postdeploy",
      recurse => true,
      require => File[$hooks_path],
    }
  } else {
    file { $postdeploy_hooks_path:
      ensure  => absent,
      force   => true,
      recurse => true,
    }
  }

  if $prerestart {
    file { $prerestart_hooks_path:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      source  => "${puppet_path}/prerestart",
      recurse => true,
      require => File[$hooks_path],
    }
  } else {
    file { $prerestart_hooks_path:
      ensure  => absent,
      force   => true,
      recurse => true,
    }
  }

  if $postrestart {
    file { $postrestart_hooks_path:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      source  => "${puppet_path}/postrestart",
      recurse => true,
      require => File[$hooks_path],
    }
  } else {
    file { $postrestart_hooks_path:
      ensure  => absent,
      force   => true,
      recurse => true,
    }
  }

}
