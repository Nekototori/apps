require 'spec_helper'

describe 'apps' do
  let(:name) { 'apps' }
  let(:facts) { Helper.facts }
  let(:pre_condition) { Helper.pre_condition }
  let(:hiera_data) { Helper.hiera_data }

  it do
    should contain_facts__set('shutterstock_env').with({
      'ensure' => 'present',
    })

    should contain_file('/opt/apps').with({
      'ensure' => 'directory',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755',
    })

    should contain_file('/opt/apps/.bin').with({
      'ensure' => 'directory',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755',
    })

    should contain_file('/opt/apps/.bin/git-ssh').with({
      'ensure' => 'present',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755',
      'source' => 'puppet:///modules/apps/git-ssh',
    })

    should contain_file('/opt/apps/.bin/git-version').with({
      'ensure' => 'present',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755',
      'source' => 'puppet:///modules/apps/git-version',
    })

    should contain_file('/opt/apps/.bin/loop_with_sleep').with({
      'ensure' => 'present',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755',
      'source' => 'puppet:///modules/apps/loop_with_sleep',
    })

    should contain_file('/opt/apps/.bin/cron_monitor').with({
      'ensure' => 'present',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755',
      'source' => 'puppet:///modules/apps/cron_monitor',
    })
  end

  context 'with ensure => absent' do
    let(:params) {{
      :ensure => 'absent',
    }}

    it do
      should contain_facts__set('shutterstock_env').with({
        'ensure' => 'absent',
      })

      should contain_file('/opt/apps').with({
        'ensure' => 'absent',
      })

      should contain_file('/opt/apps/.bin').with({
        'ensure' => 'absent',
      })

      should contain_file('/opt/apps/.bin/git-ssh').with({
        'ensure' => 'absent',
      })

      should contain_file('/opt/apps/.bin/git-version').with({
        'ensure' => 'absent',
      })

      should contain_file('/opt/apps/.bin/loop_with_sleep').with({
        'ensure' => 'absent',
      })
    end
  end
end
