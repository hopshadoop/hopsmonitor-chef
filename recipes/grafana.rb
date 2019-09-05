#
# Grafana installation
#

package_url = "#{node['grafana']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "root"
  mode "0644"
  action :create_if_missing
  retries 2
  retry_delay 5
end


grafana_downloaded = "#{node['grafana']['home']}/.grafana.extracted_#{node['grafana']['version']}"
# Extract grafana
bash 'extract_grafana' do
        user "root"
        code <<-EOH
                tar -xf #{cached_package_filename} -C #{node['hopsmonitor']['dir']}
                chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['grafana']['home']}
                chmod 750 #{node['grafana']['home']}
                touch #{grafana_downloaded}
                chown #{node['hopsmonitor']['user']} #{grafana_downloaded}

        EOH
     not_if { ::File.exists?( grafana_downloaded ) }
end

link node['grafana']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['grafana']['home']
end

file "#{node['grafana']['base_dir']}/conf/sample.ini" do
  action :delete
end

my_private_ip = my_private_ip()
public_ip=my_public_ip()

template "/tmp/grafana_tables.sql" do
  source "grafana_tables.sql.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0650
end

directory "#{node['grafana']['base_dir']}/dashboards" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "#{node['grafana']['base_dir']}/data" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "#{node['grafana']['base_dir']}/logs" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end


template "#{node['grafana']['base_dir']}/conf/defaults.ini" do
  source "grafana.ini.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0650
  variables({
     :public_ip => public_ip
  })
end

template "#{node['grafana']['base_dir']}/public/dashboards/spark.js" do
  source "spark.js.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0650
end

template "#{node['grafana']['base_dir']}/public/dashboards/admin.js" do
  source "admin.js.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0650
end

deps = ""
if exists_local("hopsmonitor", "default") 
  deps = "influxdb.service"
end  
service_name="grafana"

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
when "debian"
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0754
  variables({
    :deps => deps
  })        
if node['services']['enabled'] == "true"
  notifies :enable, resources(:service => service_name)
end
  notifies :restart, resources(:service => service_name)
end

kagent_config "#{service_name}" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config service_name do
     service "Monitoring"
     log_file "#{node['grafana']['base_dir']}/logs/grafana.log"
   end
end

bash 'add_grafan_index_for_influxdb' do
  user "root"
  code <<-EOH
    curl --user #{node['grafana']['admin_user']}:#{node['grafana']['admin_password']} 'http://localhost:3000/api/datasources' -H "Content-Type:application/json" -X POST -d '{"Name":"influxdb","Type":"influxdb","url":"http://localhost:#{node['influxdb']['http']['port']}","Access":"proxy","isDefault":true,"database":"graphite","user":"#{node['influxdb']['db_user']}","password":"#{node['influxdb']['db_password']}"}'
  EOH
  retries 10
  retry_delay 5
end
