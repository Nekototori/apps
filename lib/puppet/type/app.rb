Puppet::Type.newtype(:app) do
  @doc = 'Create a new shutterstock app deployment'
  ensurable

  newparam(:name) do
    desc 'The app name we are dealing with'
  end

  newparam(:environment) do
    desc 'The environment associated with this application'
    newvalues(:dev, :qa, :prod, :staging, :local)
    defaultto :dev
  end

  newparam(:deploy_style) do
    desc 'The type of deployment to use, this should be rsync or git'
    newvalues(:git, :rsync)
    defaultto :git
  end

  autorequire(:package) do
    ['rubygem-devops-utils', 'git', 'rsync']
  end

  autorequire(:file) do
    ['/opt/apps']
  end
end
