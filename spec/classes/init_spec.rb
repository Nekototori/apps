require 'spec_helper'

describe 'apps' do
  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_file('/opt/apps/test_application/deployenv').with_content(%r{2525}) }
    end
  end
end
