# Test implementation for apps::cron to handle monitoring
define apps::cronitor(
  $bin=undef,
  $run=undef,
  $app,
  $env = $::env,
  $platform = 'rock',
  $bin_path = 'bin',
  $hour = undef,
  $minute = undef,
  $weekday = undef,
  $month = undef,
  $monthday = undef,
  $environment = {},
  $ensure = present,
  $log_name = undef,
  $jenkins = false,
  $user = 'ssuser',
  $error_key = undef,
  $timer_key = undef,
  $mode = 'external',
  $monitor_non_prod = false,
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

      if $log_name {
        $stdout_name = "cron.${log_name}.stdout.log"
        $stderr_name = "cron.${log_name}.stderr.log"
      } else {
        $stdout_name = "cron.${run}.stdout.log"
        $stderr_name = "cron.${run}.stderr.log"
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

      if $log_name {
        $stdout_name = "cron.${log_name}.stdout.log"
        $stderr_name = "cron.${log_name}.stderr.log"
      } else {
        # Remove directories from bin path because Puppet doesn't implicitly create
        # recursive directories when ensuring a file is present
        $bin_clean = regsubst(regsubst($bin, '/', '.', 'G'), '[ \-]', '_', 'G')
        $stdout_name = "cron.${bin_clean}.stdout.log"
        $stderr_name = "cron.${bin_clean}.stderr.log"
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
    extra_headers => {
      'source'      => 'stdout',
      'source_type' => 'cron',
    },
  }

  apps::log { "${app}-${stderr_name}":
    app           => $app,
    category      => $stderr_name,
    glob          => $stderr_name,
    extra_headers => {
      'source'      => 'stderr',
      'source_type' => 'cron',
    },
  }

  case $platform {
    'rock': {
      $command = "${root_path}/run rock --path ${repo_path} run_${run}"
    }
    'binary': {
      $command = "${root_path}/run ${repo_path}/${bin}"
    }
    default: {
      $command = "${root_path}/run ${repo_path}/${bin_path}/${bin}"
    }
  }

  # allow for optional invocation under a monitoring harness
  $monitor_script = '/opt/apps/.bin/cron_monitor'
  if $monitor_non_prod or $::env == 'prod' {
    $monitor_flag = ''
  } else {
    $monitor_flag = '-d'
  }

  if $timer_key {
    $timer_option = "-t \"${timer_key}\""
  } else {
    $timer_option = ''
  }

  if $error_key {
    $error_option = "-e \"${error_key}\""
  } else {
    $error_option = ''
  }

  if $timer_key or $error_key {
    $full_command = "${monitor_script} ${monitor_flag} --env ${::env} -m ${mode} ${timer_option} ${error_option} -- ${command}"
  } else {
    $full_command = $command
  }

  cron { $name:
    ensure   => $ensure,
    hour     => $hour,
    minute   => $minute,
    month    => $month,
    monthday => $monthday,
    user     => 'root',
    weekday  => $weekday,
    require  => Apps::Setup[$app],
    command  => "/bin/su ${user} -s /bin/bash -c '${full_command}' 1>> ${stdout_path} 2>> ${stderr_path}",
  }

}
