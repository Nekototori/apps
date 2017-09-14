define apps::setup(
  $env = $::env,
  $platform = 'rock',
  $user = 'ssuser',
  $group = 'ssgroup',
  $environment = {},
  $owner = 'shutterstock',
  $jenkins = false,
  $deploy_style = 'git',
) {

  facts::set { "shutterstock_app_${name}":
    value => 'enabled',
  }

  # NOTE(afeid): this is an awful hack that can be removed once we finish
  # migrating all mason applications to use jenkins based deployment
  if ($name == 'shutterstock-mason') {
    facts::set { "shutterstock_app_${name}_jenkins":
      value => $jenkins,
    }
  }

  $root_path = "/opt/apps/${name}"
  $data_path = "${root_path}/data"
  $logs_path = "${root_path}/logs"
  $var_path = "${root_path}/var"
  $conf_path = "${root_path}/conf"

  if $jenkins == true {
    $deps_path = "${root_path}/deployment"
    $repo_path = "${root_path}/deployment"

    # Ensure we remove the old way of doing things
    file { "${root_path}/deps":
      ensure  => absent,
      recurse => true,
      force   => true,
    }
    file { "${root_path}/repo":
      ensure  => absent,
      recurse => true,
      force   => true,
    }
  } else {
    $deps_path = "${root_path}/deps"
    $repo_path = "${root_path}/repo"
  }

  # Add custom fact script to determine the version of the app on this node
  # XXX TODO add ability to create scripts to the 'facts::set' module
  file { "/etc/facter/facts.d/shutterstock_app_${name}_version.sh":
    ensure  => present,
    mode    => '0755',
    content => template('apps/shutterstock_app_version.sh.erb'),
  }

  case $platform {
    'custom': {
      $platform_rpm = 'yum'
      $rock_enable = false
    }
    'binary': {
      $platform_rpm = 'yum'
      $rock_enable = false
    }
    'java16': {
      $platform_rpm = 'shutterstock-java-platform'
      $rock_enable = false
    }
    'node04': {
      $platform_rpm = 'shutterstock-node-platform'
      $rock_enable = false

      file { "${root_path}/node_modules":
        ensure  => link,
        target  => $deps_path,
        require => [Exec["app_${name}_deps"], Exec["app_${name}_repo"]],
      }
      # this makes me want to puke
      file { "${repo_path}/node_modules":
        ensure  => link,
        target  => "${root_path}/node_modules",
        require => [Exec["app_${name}_deps"], Exec["app_${name}_repo"]],
      }
    }
    'perl588': {
      $platform_rpm = 'shutterstock-perl-platform'
      $rock_enable = false
    }
    'ruby187': {
      $platform_rpm = 'shutterstock-ruby-platform'
      $rock_enable = false
    }
    'rock': {
      $rock_enable = true
    }
    default: {
      fail("Unsupported platform: ${platform}")
    }
  }

  File { owner => 'root', group => 'root', mode => '0755' }

  if $rock_enable {
    $root_path_require = [File['/opt/apps'], Class['shutterstock_rock']]
  } else {
    $root_path_require = [File['/opt/apps'], Package[$platform_rpm]]
  }

  file { $root_path:
    ensure  => directory,
    require => $root_path_require,
  }

  file { "${root_path}/env":
    content => template("apps/${platform}_env.erb"),
    require => File[$root_path],
  }


  file { "${root_path}/run":
    content => template('apps/run.erb'),
    require => File[$root_path],
  }

  file { $var_path:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0777',
    require => File[$root_path],
  }

  file { $data_path:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0777',
    require => File[$root_path],
  }

  file { $conf_path:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0777',
    require => File[$root_path],
  }

  file { $logs_path:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0777',
    require => File[$root_path],
  }

  if $jenkins == true {
    $app_env = $env ? {
      'local' => 'dev',
      default => $env,
    }

    app { $name:
      ensure       => present,
      deploy_style => $deploy_style,
      environment  => $app_env,
    }
  } else {

    file { $repo_path:
      ensure  => directory,
      owner   => 'ssuser',
      require => File['/opt/apps'],
    }

    file { "${root_path}/ensure":
      content => template("apps/${platform}_ensure.erb"),
      require => File['/opt/apps'],
    }

    exec { "app_${name}_deps":
      command => "/usr/bin/git clone 'git://deps.shuttercorp.net/${name}' '${deps_path}'",
      timeout => 1500,
      unless  => "/usr/bin/git --git-dir='${deps_path}/.git' --work-tree='${deps_path}' branch &>/dev/null",
      require => [File[$root_path]],
    }

    $git_repo = "git@github.shuttercorp.net:${owner}/${name}.git"

    exec { "app_${name}_repo":
      cwd     => '/tmp',
      command => "/usr/bin/git clone '${git_repo}' '${repo_path}'",
      timeout => 1500,
      user    => 'ssuser',
      notify  => Exec["app_${name}_ensure"],
      unless  => "/usr/bin/git --git-dir='${repo_path}/.git' --work-tree='${repo_path}' branch &>/dev/null",
      require => File[$repo_path],
    }


    exec { "app_${name}_ensure":
      cwd         => '/tmp',
      command     => "${root_path}/ensure &>/dev/null",
      timeout     => 1500,
      refreshonly => true,
      user        => 'ssuser',
      require     => [
        File["${root_path}/ensure"],
        Exec["app_${name}_deps"],
        Exec["app_${name}_repo"],
      ],
    }
  }
}
