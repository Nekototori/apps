# Discovered and actually in use parameters for this module.
class apps::params {
  $application_name = 'test_application'
  $application_description = 'This is a test application'
  $deploy_hooks     = true
  # Don't know what restart does, but currently is false.
  $restart = false
  $service_type = 'simple'
  $service_restart = 'no'
  $type = 'rolling'
  $user  = 'root'
  $group = 'root'

  $healthcheck_port    = '2525'
  $delay               = '5'
  $server_port         = '80'
  $app_ports           = ['8000', '8001']
  $app_host            = 'localhost'
  $app_healthcheck_url = '/healthcheck.html'

  $env = 'dev'
  $puppet_path = 'puppet:///modules/apps/deploy_hooks/rolling'
}
