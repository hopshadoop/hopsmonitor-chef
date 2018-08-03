case node['platform']
when "ubuntu"
 if node['platform_version'].to_f <= 14.04
   node.override['influxdb']['systemd'] = "false"
 end
end


#
# InfluxDB installation
#

package_url = "#{node['influxdb']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "root"
  mode "0644"
  action :create_if_missing
end

influxdb_downloaded = "#{node['influxdb']['home']}/.influxdb.extracted_#{node['influxdb']['version']}"
# Extract influxdb
bash 'extract_influxdb' do
        user "root"
        code <<-EOH
                tar -xf #{cached_package_filename} -C #{node['hopsmonitor']['dir']}
                cd #{node['influxdb']['home']}
                mkdir bin
                mv usr/bin/* bin/

                chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['influxdb']['home']}
                chmod 750 #{node['influxdb']['home']}
                touch #{influxdb_downloaded}
                chown #{node['hopsmonitor']['user']} #{influxdb_downloaded}

        EOH
     not_if { ::File.exists?( influxdb_downloaded ) }
end

link node['influxdb']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['influxdb']['home']
end

directory "#{node['influxdb']['base_dir']}/log" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "#{node['influxdb']['base_dir']}/etc" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :delete
  recursive true
end



directory "#{node['influxdb']['conf_dir']}" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "/var/log/influxdb" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

my_private_ip = my_private_ip()

template"#{node['influxdb']['conf_dir']}/influxdb.conf" do
  source "influxdb.conf.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0650
  variables({
     :my_ip => my_private_ip
           })
end


case node['platform']
when "ubuntu"
 if node['platform_version'].to_f <= 14.04
   node.override['influxdb']['systemd'] = "false"
 end
end


service_name="influxdb"

if node['influxdb']['systemd'] == "true"

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
if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :restart, resources(:service => service_name)
  end

  kagent_config "#{service_name}" do
    action :systemd_reload
  end

else #sysv

  service service_name do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  template "/etc/init.d/#{service_name}" do
    source "#{service_name}.erb"
    owner node['hopsmonitor']['user']
    group node['hopsmonitor']['group']
    mode 0754
    notifies :enable, resources(:service => service_name)
    notifies :restart, resources(:service => service_name), :immediately
  end

end


#
# Setup influxdb for use with Hopsworks
#

ruby_block 'wait_until_influx_started' do
  block do
     sleep(15)
  end
  action :run
end



  exec = "#{node['influxdb']['base_dir']}/bin/influx"
  exec_pwd = "#{exec} -username #{node['influxdb']['admin_user']} -password #{node['influxdb']['admin_password']} -execute"

  # Create a test cluster admin
  execute 'create_adminuser' do
    command "#{exec} -execute \"CREATE USER #{node['influxdb']['admin_user']} WITH PASSWORD '#{node['influxdb']['admin_password']}' WITH ALL PRIVILEGES\""
    retries 10
    retry_delay 3
    not_if "#{exec_pwd} 'show users' | grep #{node['influxdb']['admin_user']}"
  end

  # Create a test user and give it access to the test database
  execute 'create_hopsworksuser' do
    command "#{exec_pwd} \"CREATE USER #{node['influxdb']['db_user']} WITH PASSWORD '#{node['influxdb']['db_password']}'\""
    not_if "#{exec_pwd} 'show users' | grep #{node['influxdb']['db_user']}"
  end

    # Create telegraf user
  execute 'create_telegrafuser' do
    command "#{exec_pwd} \"CREATE USER #{node['influxdb']['telegraf_user']} WITH PASSWORD '#{node['influxdb']['telegraf_password']}'\""
    not_if "#{exec_pwd} 'show users' | grep #{node['influxdb']['telegraf_user']}"
  end
#dbname = 'graphite'

for dbname in node['influxdb']['databases'] do

  # Create a test database
  execute 'create_grahpitedb' do
    command "#{exec_pwd} \"CREATE DATABASE #{dbname}\""
    not_if "#{exec_pwd} 'show databases' | grep #{dbname}"
  end

  execute 'add_hopsworksuser_to_graphite' do
    command "#{exec_pwd} \"GRANT READ ON #{dbname} TO #{node['influxdb']['db_user']}\""
    not_if "#{exec_pwd} 'show grants for #{node['influxdb']['db_user']}' | grep #{dbname}"
  end

  execute 'add_telegrafuser_to_graphite' do
    command "#{exec_pwd} \"GRANT ALL ON #{dbname} TO #{node['influxdb']['telegraf_user']}\""
    not_if "#{exec_pwd} 'show grants for #{node['influxdb']['telegraf_user']}' | grep #{dbname}"
  end


  # Create a test retention policy on the test database
  execute 'add_retention_policy_to_graphite' do
    command "#{exec_pwd} \"CREATE RETENTION POLICY one_week ON #{dbname} DURATION 1w REPLICATION 1 DEFAULT\""
    not_if "#{exec_pwd} 'show retention policies on grep #{dbname}' | grep one_week"
  end

end

if node['kagent']['enabled'] == "true"
   kagent_config "influxdb" do
     service "Monitoring"
     log_file "/var/log/influxdb.log"
   end
end


if node['install']['upgrade'] == "true"
  kagent_config "#{service_name}" do
    action :systemd_reload
  end
end  
