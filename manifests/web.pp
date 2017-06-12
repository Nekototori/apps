define apps::web(
  $bin = undef,
  $bin_args = undef,
  $plackup = true,
  $app = undef,
  $env = $::env,
  $platform = 'rock',
  $workers = 8,
  $count = 2,
  $port = 8000,
  $environment = {},
  $run = undef,
  $sumologic = true,
  $log_prefix = '',
  $user = 'ssuser',
  $stopsignal = undef,
  $stopwaitsecs = undef,
  $jenkins = false,
  $stdout_logfile_maxbytes = '100MB',
  $stderr_logfile_maxbytes = '100MB',
  $consul = false,
  $supervisor_autorefresh = false,
  $supervisor_autostart = true,
){
  # this is necessary for strict backwards compatibility
  case $platform {
    'rock': {
      if $bin {
        fail("bin argument isn't used for ${platform}")
      }

      if $run == undef {
        fail("run argument is required for ${platform}")
      }

      $stdout_name = "web.${run}.stdout.log"
      $stderr_name = "web.${run}.stderr.log"
    }
    'binary': {
      if $bin == undef {
        fail("bin argument is required for ${platform}")
      }
      if $run {
        fail("run argument isn't used for ${platform}")
      }
      $bin_clean = regsubst(regsubst($bin, '/', '.', 'G'), '[ \-]', '_', 'G')
      $stdout_name = "web.${bin_clean}.stdout.log"
      $stderr_name = "web.${bin_clean}.stderr.log"
    }
    default: {
      if $bin == undef {
        fail("bin argument is required for ${platform}")
      }

      # Remove directories from bin path because Puppet doesn't implicitly create
      # recursive directories when ensuring a file is present
      $bin_clean = regsubst(regsubst($bin, '/', '.', 'G'), '[ \-]', '_', 'G')

      $stdout_name = "web.${bin_clean}.stdout.log"
      $stderr_name = "web.${bin_clean}.stderr.log"
    }
  }

  $root_path = "/opt/apps/${app}"
  $data_path = "${root_path}/data"
  $logs_path = "${root_path}/logs"
  if $jenkins == true {
    $deps_path = "${root_path}/deployment"
    $repo_path = "${root_path}/deployment"
  } else {
    $deps_path = "${root_path}/deps"
    $repo_path = "${root_path}/repo"
  }

  $stdout_path = "${logs_path}/${stdout_name}"
  $stderr_path = "${logs_path}/${stderr_name}"

  if $app == 'subscriptions' {
    apps::log { "${app}-${stdout_name}":
      app           => $app,
      sumologic     => $sumologic,
      category      => "${log_prefix}${stdout_name}",
      glob          => split(inline_template('<%= @stdout_name %> <%= (0...(@count.to_i)).map { |i| @stdout_name.sub(/\.log$/, ".#{@port.to_i + i}.log") }.join(" ") %>'), ' '),
      extra_headers => {
        'source'      => 'stdout',
        'source_type' => 'web',
      },
    }

    apps::log { "${app}-${stderr_name}":
      app           => $app,
      sumologic     => $sumologic,
      category      => "${log_prefix}${stderr_name}",
      glob          => split(inline_template('<%= @stderr_name %> <%= (0...(@count.to_i)).map { |i| @stderr_name.sub(/\.log$/, ".#{@port.to_i + i}.log") }.join(" ") %>'), ' '),
      extra_headers => {
        'source'      => 'stderr',
        'source_type' => 'web',
      },
    }
  } else {
    apps::log { "${app}-${stdout_name}":
      app           => $app,
      sumologic     => $sumologic,
      category      => "${log_prefix}${stdout_name}",
      glob          => $stdout_name,
      extra_headers => {
        'source'      => 'stdout',
        'source_type' => 'web',
      },
    }

    apps::log { "${app}-${stderr_name}":
      app           => $app,
      sumologic     => $sumologic,
      category      => "${log_prefix}${stderr_name}",
      glob          => $stderr_name,
      extra_headers => {
        'source'      => 'stderr',
        'source_type' => 'web',
      },
    }
  }

  # create supervisor info config for how to restart web processes during deployment
  if $app == 'deployer' and $count >= 1 and $env == 'qa' {
    file { "${root_path}/supervisor_web.yml":
      ensure  => present,
      owner   => 'ssuser',
      group   => 'ssgroup',
      content => "name: ${name}\ncount: ${count}\n"
    }
  }

  case $platform {
    'binary': {
      $command = "${root_path}/run ${repo_path}/${bin}"
      $environment[APP_WORKERS] = $workers

      if $count >= 1 {
        supervisor::program { "${name}1":
          user                    => $user,
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port }),
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          stopwaitsecs            => $stopwaitsecs,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
      if $count >= 2 {
        supervisor::program { "${name}2":
          user                    => $user,
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port + 1 }),
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          stopwaitsecs            => $stopwaitsecs,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
    }
    'rock': {
      $command = "${root_path}/run rock --path ${repo_path} run_${run}"
      $environment[APP_WORKERS] = $workers

      if $count >= 1 {
        supervisor::program { "${name}1":
          user                    => $user,
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port }),
          stdout_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stdout.#{@port.to_i + 0}.log" %>'), default => "${stdout_path}" },
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stderr.#{@port.to_i + 0}.log" %>'), default => "${stderr_path}" },
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          stopwaitsecs            => $stopwaitsecs,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
      if $count >= 2 {
        supervisor::program { "${name}2":
          user                    => $user,
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port + 1 }),
          stdout_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stdout.#{@port.to_i + 1}.log" %>'), default => "${stdout_path}" },
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stderr.#{@port.to_i + 1}.log" %>'), default => "${stderr_path}" },
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          stopwaitsecs            => $stopwaitsecs,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
      if $count >= 3 {
        supervisor::program { "${name}3":
          user                    => $user,
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port + 2 }),
          stdout_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stdout.#{@port.to_i + 2}.log" %>'), default => "${stdout_path}" },
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stderr.#{@port.to_i + 2}.log" %>'), default => "${stderr_path}" },
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          stopwaitsecs            => $stopwaitsecs,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
      if $count >= 4 {
        supervisor::program { "${name}4":
          user                    => $user,
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port + 3 }),
          stdout_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stdout.#{@port.to_i + 3}.log" %>'), default => "${stdout_path}" },
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $app ? { 'subscriptions' => inline_template('<%= "#{@logs_path}/web.#{@run}.stderr.#{@port.to_i + 3}.log" %>'), default => "${stderr_path}" },
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          stopwaitsecs            => $stopwaitsecs,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
    }
    'java16': {
      $command = "${root_path}/run ${repo_path}/bin/${bin}"

      if $count >= 1 {
        supervisor::program { "${name}1":
          user                    => 'ssuser',
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port }),
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }

      if $count >= 2 {
        supervisor::program { "${name}2":
          user                    => 'ssuser',
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port + 1 }),
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
    }
    'node04': {
      $command = "${root_path}/run ${repo_path}/bin/${bin}"

      if $count >= 1 {
        supervisor::program { "${name}1":
          user                    => 'ssuser',
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port }),
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }

      if $count >= 2 {
        supervisor::program { "${name}2":
          user                    => 'ssuser',
          command                 => $command,
          directory               => $repo_path,
          environment             => merge($environment, { 'HTTP_PORT' => $port + 1 }),
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
    }
    'perl588': {
      # XXX: this is pretty terrible and should be cleaned up,
      # we needed a way to run old school applications that don't use dancer and have command line arguments
      if $plackup == true {
        $command = "${root_path}/run plackup -E $( bash -c '. ${root_path}/env ; echo \${DANCER_ENVIRONMENT:-${env}}' ) -s Starman --workers=${workers} -a ${repo_path}/bin/${bin}"
      } else {
        if $bin_args {
          $command = "${root_path}/run ${repo_path}/bin/${bin} ${bin_args}"
        } else {
          $command = "${root_path}/run ${repo_path}/bin/${bin}"
        }
      }

      if $count >= 1 {
        supervisor::program { "${name}1":
          user                    => 'nginx',
          command                 => "${command} -l /tmp/${name}.1.sock",
          directory               => $repo_path,
          environment             => $environment,
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }

      if $count >= 2 {
        supervisor::program { "${name}2":
          user                    => 'nginx',
          command                 => "${command} -l /tmp/${name}.2.sock",
          directory               => $repo_path,
          environment             => $environment,
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }
    }
    ruby187: {
      $command = "${root_path}/run bundle exec ${bin}"

      if $count >= 1 {
        supervisor::program { "${name}1":
          user                    => 'ssuser',
          command                 => "${command} -l 127.0.0.1:${port}",
          directory               => $repo_path,
          environment             => $environment,
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }

      if $count >= 2 {
        supervisor::program { "${name}2":
          user                    => 'ssuser',
          command                 => "${command} -l 127.0.0.1:${port}",
          directory               => $repo_path,
          environment             => $environment,
          stdout_logfile          => $stdout_path,
          stdout_logfile_backups  => 0,
          stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
          stderr_logfile          => $stderr_path,
          stderr_logfile_backups  => 0,
          stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
          require                 => [Class['supervisor'], Apps::Setup[$app]],
          stopsignal              => $stopsignal,
          autorefresh             => $supervisor_autorefresh,
          autostart               => $supervisor_autostart,
        }
      }

    }


    default: {
      fail("Unsupported platform: ${platform}")
    }
  }

  if $consul {
    $port_1 = 0 + $port
    $port_2 = 1 + $port
    $port_3 = 2 + $port
    $port_4 = 3 + $port
    if $count >= 1 { consul::service_http { "${name}-${port_1}": service => $name, port => $port_1 } }
    if $count >= 2 { consul::service_http { "${name}-${port_2}": service => $name, port => $port_2 } }
    if $count >= 3 { consul::service_http { "${name}-${port_3}": service => $name, port => $port_3 } }
    if $count >= 4 { consul::service_http { "${name}-${port_4}": service => $name, port => $port_4 } }
  }
}
