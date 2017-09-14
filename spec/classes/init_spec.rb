require 'spec_helper'

describe 'apps' do
  let(:name) { 'apps' }

  it do
    is_expected.to contain_facts__set('shutterstock_env').with('ensure' => 'present')

    is_expected.to contain_file('/opt/apps').with('ensure' => 'directory',
                                                  'owner'  => 'root',
                                                  'group'  => 'root',
                                                  'mode'   => '0755')

    is_expected.to contain_file('/opt/apps/.bin').with('ensure' => 'directory',
                                                       'owner'  => 'root',
                                                       'group'  => 'root',
                                                       'mode'   => '0755')

    is_expected.to contain_file('/opt/apps/.bin/git-ssh').with('ensure' => 'present',
                                                               'owner'  => 'root',
                                                               'group'  => 'root',
                                                               'mode'   => '0755',
                                                               'source' => 'puppet:///modules/apps/git-ssh')

    is_expected.to contain_file('/opt/apps/.bin/git-version').with('ensure' => 'present',
                                                                   'owner'  => 'root',
                                                                   'group'  => 'root',
                                                                   'mode'   => '0755',
                                                                   'source' => 'puppet:///modules/apps/git-version')

    is_expected.to contain_file('/opt/apps/.bin/loop_with_sleep').with('ensure' => 'present',
                                                                       'owner'  => 'root',
                                                                       'group'  => 'root',
                                                                       'mode'   => '0755',
                                                                       'source' => 'puppet:///modules/apps/loop_with_sleep')

    is_expected.to contain_file('/opt/apps/.bin/cron_monitor').with('ensure' => 'present',
                                                                    'owner'  => 'root',
                                                                    'group'  => 'root',
                                                                    'mode'   => '0755',
                                                                    'source' => 'puppet:///modules/apps/cron_monitor')
  end

end
