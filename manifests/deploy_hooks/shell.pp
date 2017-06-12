class apps::deploy_hooks::shell{

  if $predeploy {
    file { $predeploy_hooks_path:
      ensure  => directory,
      owner   => $owner,
      group   => $group,
      mode    => '0755',
      require => File[$hooks_path],
    }

    file { "${predeploy_hooks_path}/01-predeploy.sh":
      ensure   => present,
      owner    => $user,
      group    => $group,
      mode     => '0755',
      content  => "#!/bin/bash\n\n ${predeploy}",
      require  => File[$predeploy_hooks_path],
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
      owner   => $owner,
      group   => $group,
      mode    => '0755',
      require => File[$hooks_path],
    }

    file { "${postdeploy_hooks_path}/01-postdeploy.sh":
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      content => "#!/bin/bash\n\n ${postdeploy}",
      require => File[$postdeploy_hooks_path],
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
      owner   => $owner,
      group   => $group,
      mode    => '0755',
      require => File[$hooks_path],
    }

    file { "${prerestart_hooks_path}/01-prerestart.sh":
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      content => "#!/bin/bash\n\n ${prerestart}",
      require => File[$prerestart_hooks_path],
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
      owner   => $owner,
      group   => $group,
      mode    => '0755',
      require => File[$hooks_path],
    }

    file { "${postrestart_hooks_path}/01-postrestart.sh":
      ensure   => present,
      owner    => $user,
      group    => $group,
      mode     => '0755',
      content  => "#!/bin/bash\n\n ${postrestart}",
      require  => File[$postrestart_hooks_path],
    }
  } else {
    file { $postrestart_hooks_path:
      ensure  => absent,
      force   => true,
      recurse => true,
    }
  }

}
