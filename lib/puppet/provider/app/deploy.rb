require 'fileutils'
require 'logger'

loaded = false
begin
  require 'shutterstock/app'
  loaded = true
rescue LoadError
  # Do nothing at the moment
end

if loaded
  Puppet::Type.type(:app).provide(:deploy) do
    commands :rsync => 'rsync'
    commands :git => 'git'

    desc 'Provides the ability to deploy an application'

    def app
      @app ||= Shutterstock::App.new(@resource.value(:name), :logger => Logger.new('/dev/null'))
    end

    def current_version
      @current_version ||= app.current_version
    end

    def create
      unless File.exists?(app.deployment_path)
        FileUtils.mkdir_p(app.deployment_path)
      end

      if current_version.nil?
        raise 'Could not determine a valid version to deploy!'
      end

      app.set_version(current_version)
    end

    def destroy
      if File.exists?(app.deployment_path)
        FileUtils.rm_rf(app.deployment_path)
      end
    end

    def exists?
      File.exists?(app.deployment_path) && app.version.to_s == current_version.to_s
    end
  end
end
