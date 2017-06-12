define apps::worker($app,
  $env = $::env,
  $platform = 'rock',
  $custom_log_name = undef,
  $bin = undef,
  $bin_path = 'bin',
  $workers = undef,
  $environment = undef,
  $run = undef,
  $stopsignal = undef,
  $jenkins = false,
  $flume = true,
  $sumologic = true,
  $user = 'ssuser',
  $supervisor_autorefresh = false,
  $sleep = 0,
  $startretries = 3,
  $stdout_logfile_maxbytes = '100MB',
  $stderr_logfile_maxbytes = '100MB',
) {
  # this is necessary for strict backwards compatibility
  case $platform {
    'rock': {
      if $bin {
        fail("bin argument isn't used for ${platform}")
      }

      if $run == undef {
        fail("run argument is required for ${platform}")
      }

      # Remove directories from bin path because Puppet doesn't implicitly create
      # recursive directories when ensuring a file is present
      $run_clean = regsubst(regsubst($run, '/', '.', 'G'), '[ \-]', '_', 'G')

      if $custom_log_name {
        $stdout_name = "worker.${custom_log_name}.stdout.log"
        $stderr_name = "worker.${custom_log_name}.stderr.log"
      } else {
        $stdout_name = "worker.${run_clean}.stdout.log"
        $stderr_name = "worker.${run_clean}.stderr.log"
      }
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

      if $custom_log_name {
        $stdout_name = "worker.${custom_log_name}.stdout.log"
        $stderr_name = "worker.${custom_log_name}.stderr.log"
      } else {
        $stdout_name = "worker.${bin_clean}.stdout.log"
        $stderr_name = "worker.${bin_clean}.stderr.log"
      }
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

  apps::log { "${app}-${stdout_name}":
    app           => $app,
    category      => $stdout_name,
    sumologic     => $sumologic,
    glob          => $stdout_name,
    flume         => $flume,
    extra_headers => {
      'source'      => 'stdout',
      'source_type' => 'worker',
    },
  }

  apps::log { "${app}-${stderr_name}":
    app           => $app,
    category      => $stderr_name,
    sumologic     => $sumologic,
    glob          => $stderr_name,
    flume         => $flume,
    extra_headers => {
      'source'      => 'stderr',
      'source_type' => 'worker',
    },
  }

  # create supervisor info config for how to restart web processes during deployment
  if $app == 'deployer' and $env == 'qa' {
    file { "${root_path}/supervisor_worker.yml":
      ensure  => present,
      owner   => 'ssuser',
      group   => 'ssgroup',
      content => "name: ${name}\n"
    }
  }

  case $platform {
    'binary': {
      $command = "${root_path}/run ${repo_path}/${bin}"
      supervisor::program { $name:
        user                    => $user,
        command                 => $command,
        directory               => $repo_path,
        stdout_logfile          => $stdout_path,
        stdout_logfile_backups  => 0,
        stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
        stderr_logfile          => $stderr_path,
        stderr_logfile_backups  => 0,
        stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
        numprocs                => $workers,
        environment             => $environment,
        stopsignal              => $stopsignal,
        autorefresh             => $supervisor_autorefresh,
        startretries            => $startretries,
        require                 => [Class['supervisor'], Apps::Setup[$app]],
        sleep                   => $sleep,
      }
    }
    'rock': {
      $command = "${root_path}/run rock --path ${repo_path} run_${run}"

      supervisor::program { $name:
        user                    => $user,
        command                 => $command,
        directory               => $repo_path,
        stdout_logfile          => $stdout_path,
        stdout_logfile_backups  => 0,
        stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
        stderr_logfile          => $stderr_path,
        stderr_logfile_backups  => 0,
        stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
        numprocs                => $workers,
        environment             => $environment,
        stopsignal              => $stopsignal,
        autorefresh             => $supervisor_autorefresh,
        startretries            => $startretries,
        require                 => [Class['supervisor'], Apps::Setup[$app]],
        sleep                   => $sleep,
      }
    }
    'ruby187': {
      $command = "${root_path}/run ${repo_path}/${bin_path}/${bin}"
      supervisor::program { $name:
        user                    => $user,
        command                 => $command,
        directory               => $repo_path,
        stdout_logfile          => $stdout_path,
        stdout_logfile_backups  => 0,
        stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
        stderr_logfile          => $stderr_path,
        stderr_logfile_backups  => 0,
        stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
        numprocs                => $workers,
        environment             => $environment,
        stopsignal              => $stopsignal,
        autorefresh             => $supervisor_autorefresh,
        startretries            => $startretries,
        require                 => [Class['supervisor'], Apps::Setup[$app]],
        sleep                   => $sleep,
      }
    }
    'node04': {
    }
    'perl588': {
      $command = "${root_path}/run ${repo_path}/${bin_path}/${bin}"

      supervisor::program { $name:
        user                    => $user,
        command                 => $command,
        directory               => $repo_path,
        stdout_logfile          => $stdout_path,
        stdout_logfile_backups  => 0,
        stdout_logfile_maxbytes => $stdout_logfile_maxbytes,
        stderr_logfile          => $stderr_path,
        stderr_logfile_backups  => 0,
        stderr_logfile_maxbytes => $stderr_logfile_maxbytes,
        numprocs                => $workers,
        environment             => $environment,
        stopsignal              => $stopsignal,
        startretries            => 300,
        autorefresh             => $supervisor_autorefresh,
        require                 => [Class['supervisor'], Apps::Setup[$app]],
        sleep                   => $sleep,
      }
    }
    default: {
      fail("Unsupported platform: ${platform}")
    }
  }
}
