# This code is maintained for legacy purposes and not called upon for anything.
#define apps::log(
#  $glob="",
#  $app,
#  $category="",
#  $flume=true,
#  $sumologic=false,
#  $caller_name=undef,
#  $extra_headers={},
#  $syslog_enabled_logging=false,
#  $syslog_facility='local1',
#) {
#  $root_path = "/opt/apps/${app}"
#  $logs_path = "${root_path}/logs"
#
#  if $flume == true and $syslog_enabled_logging == true and defined(Class['rsyslog']) {
#    rsyslog::set { "${app}.flume":
#      content => "\$FileCreateMode 0644\n\$UMASK 0000\n\nif \$programname == '${app}' and \$syslogfacility-text == '${syslog_facility}' then @127.0.0.1:5141\nif \$programname == '${app}' and \$syslogfacility-text == '${syslog_facility}' then ${logs_path}/${app}.log\n& ~\n\$FileCreateMode 0600\n\$UMASK 0077\n",
#    }
#  } else {
#    if $glob == "" {
#      fail('apps log variable glob cannot be null')
#    }
#    if $category == "" {
#      fail('apps log variable log cannot be null')
#    }
#    if $flume and $roles::base::flume_enable != false {
#      ### NOTE: Please consult with devops before changing the below ###
#      # Categories are typically set as 'web.web.stdout.log' or 'nginx.access.log'
#      # so let's use some regex to get useful information out of that.
#      if $category =~ /^(web|worker|cron)\..*$/ {
#        $default_source = regsubst($category, '^\w+\.w+\.(stdout|stderr)\..*$', '\1')
#        $default_source_type = regsubst($category, '^(\w+)\..*$', '\1')
#      }
#
#      if $default_source and !$extra_headers['source'] {
#        $extra_headers['source'] = $default_source
#      }
#
#      if $default_source_type and !$extra_headers['source_type'] {
#        $extra_headers['source_type'] = $default_source_type
#      }
#
#      $extra_headers['app'] = $app
#      flume::log { $name:
#        category      => "${app}__${category}",
#        path          => inline_template('<%= [@glob].flatten.map {|p| "#{@logs_path}/#{p}" }.join(" ") %>'),
#        extra_headers => $extra_headers,
#      }
#    }
#  }
#  if $sumologic {
#    if $app == 'subscriptions' {
#      $fullpath = '/opt/apps/subscriptions/logs/web.web.stdout*.log'
#    } else {
#      $fullpath = inline_template('<%= [@glob].flatten.map {|p| "#{@logs_path}/#{p}" }.join(" ") %>')
#    }
#
#    if $caller_name {
#      $sumo_name = $caller_name
#    } else {
#      $sumo_name = $name
#    }
#    sumologic::log {"${sumo_name}":
#      fullpath      => "${fullpath}",
#      app_name      => "${app}",
#      sumotemplate  => "${extra_headers['source']}-${extra_headers['source_type']}",
#      collector     => true,
#    }
#  }
#}
