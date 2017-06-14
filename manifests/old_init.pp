class apps::old_init(
  Enum['present', 'absent'] $ensure=present,
  Boolean $autoupgrade=true,
) {

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
  File {
    ensure => $ensure
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  package { 'rubygem-devops-utils':
    ensure => $package_ensure,
# This won't do what I think it's expected to do.
# I expect it to restart mcollective. I don't know
# why one would bother to do so after installing the
# above things.
    notify => Service['mcollective'],
  }

# This resource may be called elsewhere. It shouldn't be.
  file { ['/opt/apps', 'opt/apps/.bin']:
      ensure => $directory_ensure,
  }

  file { '/opt/apps/.bin/git-ssh':
    source  => 'puppet:///modules/apps/git-ssh',
    require => File['/opt/apps/.bin'],
  }

  file { '/opt/apps/.bin/git-version':
    source  => 'puppet:///modules/apps/git-version',
    require => File['/opt/apps/.bin'],
  }

  file { '/opt/apps/.bin/loop_with_sleep':
    source  => 'puppet:///modules/apps/loop_with_sleep',
    require => File['/opt/apps/.bin'],
  }

  file { '/opt/apps/.bin/cron_monitor':
    source  => 'puppet:///modules/apps/cron_monitor',
    require => File['/opt/apps/.bin'],
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

# Need to determine scope of ssuser, especially compared to ssdeploy,
# and determine if that needs to be stored elsewhere or within here.
#  if $ensure == present {
#    realize File['/var/lib/ssuser/.ssh/id_rsa']
#    realize Yum::Repo['shutterstock-git']
#
#  }

}
