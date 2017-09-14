$env = 'prod'
$location = 'ma01'
$majorversion = '6'

include mcollectived
include icinga::node
include supervisor
include users
include yum

stage { 'pre': before => Stage[main] }
