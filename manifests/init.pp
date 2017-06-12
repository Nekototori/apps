class apps(
  $ensure=present,
  $autoupgrade=true,
) {
  if ! ("$ensure" in ['present', 'absent']) {
    fail('apps ensure parameter must be absent or present')
  }

  if ! ("$autoupgrade" in ['true', 'false']) {
    fail('apps autoupgrade parameter must be true or false')
  }

  if $ensure == 'present' {
    if $autoupgrade == true {
      $package_ensure = latest
    } else {
      $package_ensure = present
    }
    $directory_ensure = directory
    $service_enable = true
    $service_ensure = running
  } else {
    $directory_ensure = absent
    $package_ensure = absent
    $service_enable = false
    $service_ensure = stopped
  }

  package { 'rubygem-devops-utils':
    ensure => $package_ensure,
    notify => Service['mcollective'],
  }

  package { 'cortex-inventory-plugin-shutterstock-apps':
    ensure  => latest,
  }

  facts::set { 'shutterstock_env':
    ensure => $ensure,
    value  => $::env,
  }

  if ! defined(File['/opt/apps']) {
    file { '/opt/apps':
      ensure => $directory_ensure,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  file { '/opt/apps/.bin':
    ensure  => $directory_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/opt/apps'],
  }

  file { '/opt/apps/.bin/git-ssh':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/apps/git-ssh',
    require => File['/opt/apps/.bin'],
  }

  file { '/opt/apps/.bin/git-version':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/apps/git-version',
    require => File['/opt/apps/.bin'],
  }

  file { '/opt/apps/.bin/loop_with_sleep':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/apps/loop_with_sleep',
    require => File['/opt/apps/.bin'],
  }

  file { '/opt/apps/.bin/cron_monitor':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/apps/cron_monitor',
    require => File['/opt/apps/.bin'],
  }

  if $::fqdn =~ /^(dev|qa|prod)-commerce[0-9]+\./ {
    # this hack is horrible and fills me with :sad_panda:
    # the point is that we need to send a USR1 signal to the commerce service daemon when the logs are rotated
    $postscript = '[ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid` ; true;
      [ -f /var/run/supervisord.pid ] && kill -USR2 `cat /var/run/supervisord.pid` ; true;
      /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true;
      cat /opt/apps/shutterstock-commerce-rb/data/*.pid 2>/dev/null | xargs -r kill -USR1 || true'

    logrotate::log { 'apps':
      logs => ['/opt/apps/*/logs/*.log'],
      options => [
        'size 500M',
        'rotate 6',
        'missingok',
        'notifempty',
        'compress',
        'sharedscripts'
      ],
      postscript => $postscript
    }
  } elsif ($::fqdn =~ /^(dev|qa|prod)-contributor-www[0-9]+\./) {
    # We are providing our own rules in the contributor_www:web role
  } elsif ($::fqdn =~ /^(dev|qa|prod)-languageid[0-9]+\./) or ($::fqdn =~ /^(dev|qa|prod)-linguistic/) {
    # don't manage this with logrotate, it plays horribly with jetty
    file { '/opt/apps/.bin/jetty_logs.sh':
     ensure  => $ensure,
     owner   => 'root',
     group   => 'root',
     mode    => '0755',
     source  => 'puppet:///modules/apps/jetty_logs.sh',
     require => File['/opt/apps/.bin'],
    }
    cron::script { 'jetty_logs.sh':
      minute  => fqdn_rand(59),
      hour    => fqdn_rand(23),
      command => '/opt/apps/.bin/jetty_logs.sh',
    }
  } else {
    file { '/etc/logrotate.d/apps':
      ensure  => $directory_ensure,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/apps/logrotate',
    }
  }

  $git_gc_command = '#!/usr/bin/env bash
    for path in $( nice -n 15 find /opt/apps -maxdepth 1 -type d ); do
      path="$path/deployment"
      if [[ -d "$path/.git" ]]; then
        pushd $path &>/dev/null
          nice -n 15 git config gc.auto 0
          nice -n 15 git gc --aggressive --quiet
        popd &>/dev/null
      fi
    done
  '

  cron::script { 'apps_git_gc':
    weekday => 6,
    minute  => fqdn_rand(59),
    hour    => fqdn_rand(23),
    command => $git_gc_command,
  }

  if $ensure == present {
    realize File['/var/lib/ssuser/.ssh/id_rsa']
    realize Yum::Repo['shutterstock-git']

  }

  if defined(Class['mcollectived']) {
    realize Mcollectived::Agent['deploy']
    realize Mcollectived::Agent['apps']
  }
}
