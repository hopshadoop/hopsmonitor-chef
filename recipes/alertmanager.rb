# Install Alertmanager

base_package_filename = File.basename(node['alertmanager']['url'])
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source node['alertmanager']['url']
  owner "root"
  mode "0644"
  action :create_if_missing
end

directory node['alertmanager']['root_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  action :create
end

directory node['alertmanager']['data_volume']['data_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  recursive true
  action :create
end

bash 'Move alertmanager data to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['alertmanager']['data_dir']}/* #{node['alertmanager']['data_volume']['data_dir']}
    rm -rf #{node['alertmanager']['data_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['alertmanager']['data_dir'])}
  not_if { File.symlink?(node['alertmanager']['data_dir'])}
end

link node['alertmanager']['data_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  to node['alertmanager']['data_volume']['data_dir']
end

remote_directory node['alertmanager']['tmpl_dir'] do 
  source "templates"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0770
  files_owner node['hopsmonitor']['user']
  files_group node['hopsmonitor']['group']
  files_mode 0770
end

alertmanager_downloaded= "#{node['alertmanager']['home']}/.alertmanager.extracted_#{node['alertmanager']['version']}"
# Extract alertmanager 
bash 'extract_alertmanager' do
  user "root"
  code <<-EOH
    tar -xf #{cached_package_filename} -C #{node['alertmanager']['root_dir']}
    chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['alertmanager']['home']}
    chmod -R 750 #{node['alertmanager']['home']}
    touch #{alertmanager_downloaded}
    chown #{node['hopsmonitor']['user']} #{alertmanager_downloaded}
  EOH
  not_if { ::File.exists?( alertmanager_downloaded ) }
end

link node['alertmanager']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['alertmanager']['home']
end

template "#{node['alertmanager']['base_dir']}/alertmanager.yml" do
  source "alertmanager.yml.erb" 
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0770'
  action :create
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/alertmanager.service" 
else
  systemd_script = "/lib/systemd/system/alertmanager.service"
end

service "alertmanager" do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

template systemd_script do
  source "alertmanager.service.erb"
  owner "root"
  group "root"
  mode 0664
  if node['services']['enabled'] == "true"
    notifies :enable, "service[alertmanager]"
  end
  notifies :restart, "service[alertmanager]"
end

kagent_config "alertmanager" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config "alertmanager" do
     service "Monitoring"
     restart_agent false 
   end
end

if service_discovery_enabled()
  # Register Alertmanager with Consul
  consul_service "Registering Alertmanager with Consul" do
    service_definition "alertmanager-consul.hcl.erb"
    action :register
  end
end 
