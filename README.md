
# apps

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with apps](#setup)
    * [What apps affects](#what-apps-affects)
    * [Beginning with apps](#beginning-with-sstk_apps)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)

## Description

This module deploys the framework needed for command center to deploy
the application from git or whetever source command center uses.

This creates the folders, scripts, and stages the services using systemd
so everything is bootstrapped and ready for command center to push out.

## Setup

### What apps affects

It configures rock with defaults, sets the deploy hooks by default, and fills out the various files, directories, and scripts for use to launch and run the application.

This is still a bit in development, so don't expect it to work for your
app on the first go.  Some warnings are in place if you attempt to set
values and settings that haven't been migrated over due to them not
being fully understood yet.  Improvements welcome.


### Beginning with apps

An example basic use case for using this module:
```
class { 'apps':
     application_name        => 'my_little_app',
     application_description => 'The app that could.',
     app_ports               => ['8004', '8005'],
     env                     => $facts['ss_tier'],
   }
```

## Usage

This section is where you describe how to customize, configure, and do the fancy stuff with your module here. It's especially helpful if you include usage examples and code samples for doing things with your module.

## Reference

See /docs for the documented parameters exposed for use.

## Limitations

As this requires systemd, this only works on modern releases of Ubuntu
and CentOS/RedHat.

## Development

Make a branch, and use `pdk validate` and `pdk test unit` to verify
prior to opening a PR. Bonus points if you add additional spec tests to
cover new templates/states/changes.

