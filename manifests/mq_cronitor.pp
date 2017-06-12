# Test implementation for apps::cron to handle monitoring
define apps::mq_cronitor(
  $command,
  $workerscheduler_invocation,
  $app,
  $ensure    = present,
  $hour      = undef,
  $minute    = undef,
  $weekday   = undef,
  $month     = undef,
  $monthday  = undef,
  $env       = $::env,
  $user      = 'ssuser',
  $error_key = undef,
  $timer_key = undef,
  $mode = 'external',
) {

  $root_path = "/opt/apps/${app}"
  $repo_path = "${root_path}/deployment"

  # allow for optional invocation under a monitoring harness
  $monitor_script = '/opt/apps/.bin/cron_monitor'
  $monitor_flag = $::env ? {
    'prod'  => '',
    default => '-d',
  }

  if $timer_key {
    $timer_option = "-t ${timer_key}"
  } else {
    $timer_option = ''
  }

  if $error_key {
    $error_option = "-e ${error_key}"
  } else {
    $error_option = ''
  }

  if $timer_key or $error_key {
    $full_command = "${monitor_script} ${monitor_flag} -m ${mode} ${timer_option} ${error_option} -- ${repo_path}/${command}"
  } else {
    $full_command = "${repo_path}/${command}"
  }

  cron { $name:
    ensure   => $ensure,
    command  => "${workerscheduler_invocation} ${full_command}",
    hour     => $hour,
    minute   => $minute,
    month    => $month,
    monthday => $monthday,
    weekday  => $weekday,
    user     => $user,
  }
}
