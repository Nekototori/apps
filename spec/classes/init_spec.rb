require 'spec_helper'

describe 'apps' do
  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_file('/opt/apps/test_application/deployenv').with_content(%r{2525}) }

      context 'with custom params' do
        let(:params) do
          {
            'application_name' => 'spec_test',
            'application_description' => 'testing spec',
            'app_ports' => %w[1234 5678],
            'env' => 'spec',
          }
        end

        it 'directories' do
          is_expected.to contain_file('/opt/apps/spec_test').with('ensure' => 'directory')
          is_expected.to contain_file('/opt/apps/spec_test/data').with('ensure' => 'directory')
          is_expected.to contain_file('/opt/apps/spec_test/var').with('ensure' => 'directory')
          is_expected.to contain_file('/opt/apps/spec_test/logs').with('ensure' => 'directory')
          is_expected.to contain_file('/opt/apps/spec_test/conf').with('ensure' => 'directory')
        end

        it 'files' do
          is_expected.to contain_file('/opt/apps/spec_test/run').with_content(%r{spec_test})
          is_expected.to contain_file('/opt/apps/spec_test/env').with_content(%r{spec})
        end

        it 'services' do
          is_expected.to contain_systemd__service('spec_test_1234').with(
            'description' => 'testing spec',
            'execstart'   => '/opt/apps/spec_test/run rock --path /opt/apps/spec_test/deployment run_web',
            'pid_file'    => '/opt/apps/spec_test/master.pid',
          )
          is_expected.to contain_systemd__service('spec_test_5678').with(
            'description' => 'testing spec',
            'execstart'   => '/opt/apps/spec_test/run rock --path /opt/apps/spec_test/deployment run_web',
            'pid_file'    => '/opt/apps/spec_test/master.pid',
          )
          is_expected.not_to contain_systemd__service('test_application_8000')
        end
      end
    end
  end
end
