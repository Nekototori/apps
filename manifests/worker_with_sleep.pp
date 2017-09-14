define apps::worker_with_sleep(
  $bin = undef,
  $app,
  $sleep,
  $env = $::env,
  $platform = 'rock',
  $custom_log_name = undef,
  $bin_path = 'bin',
  $sumologic = true,
  $run = undef,
  $workers = undef,
  $environment = undef,
  $jenkins = false,
  $cronitor = undef,
  $user = 'ssuser') {

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
    glob          => $stdout_name,
    sumologic     => true,
    extra_headers => {
      'source'      => 'stdout',
      'source_type' => 'worker',
    },
  }

  apps::log { "${app}-${stderr_name}":
    app           => $app,
    category      => $stderr_name,
    glob          => $stderr_name,
    sumologic     => true,
    extra_headers => {
      'source'      => 'stderr',
      'source_type' => 'worker',
    },
  }

  case $platform {
    'rock': {
      $command = "/opt/apps/.bin/loop_with_sleep ${sleep} ${root_path}/run rock --path ${repo_path} run_${run}"

      supervisor::program { $name:
        user                    => $user,
        command                 => $command,
        directory               => $repo_path,
        stdout_logfile          => $stdout_path,
        stdout_logfile_backups  => 0,
        stdout_logfile_maxbytes => '100MB',
        stderr_logfile          => $stderr_path,
        stderr_logfile_backups  => 0,
        stderr_logfile_maxbytes => '100MB',
        numprocs                => $workers,
        environment             => $environment,
        stopsignal              => $stopsignal,
        require                 => [Class['supervisor'], Apps::Setup[$app]],
      }
    }
    'node04': {
    }
    'perl588': {
      $command = "/opt/apps/.bin/loop_with_sleep ${sleep} ${root_path}/run ${repo_path}/${bin_path}/${bin}"

      supervisor::program { $name:
        user                    => $user,
        command                 => $command,
        directory               => $repo_path,
        stdout_logfile          => $stdout_path,
        stdout_logfile_backups  => 0,
        stdout_logfile_maxbytes => '100MB',
        stderr_logfile          => $stderr_path,
        stderr_logfile_backups  => 0,
        stderr_logfile_maxbytes => '100MB',
        numprocs                => $workers,
        environment             => $environment,
        require                 => [Class['supervisor'], Apps::Setup[$app]];
      }
    }
    default: {
      fail("Unsupported platform: ${platform}")
    }
  }
}
