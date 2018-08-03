case node['platform']
when "ubuntu"
 if node['platform_version'].to_f <= 14.04
   node.override['telegraf']['systemd'] = "false"
 end
end

#
# Telegraf installation
#
package_url = "#{node['telegraf']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "root"
  mode "0644"
  action :create_if_missing
end

package "logrotate"

telegraf_downloaded = "#{node['telegraf']['home']}/.telegraf.extracted_#{node['telegraf']['version']}"
# Extract telegraf
bash 'extract_telegraf' do
        user "root"
        code <<-EOH
                tar -xf #{cached_package_filename} -C #{node['hopsmonitor']['dir']}
                mv #{node['hopsmonitor']['dir']}/telegraf #{node['telegraf']['home']}
                cd #{node['telegraf']['home']}
                mkdir conf
                cp etc/logrotate.d/telegraf /etc/logrotate.d/telegraf
                mv etc/telegraf conf
                mv usr/bin bin/
                mv usr/lib/* /usr/lib
                rm -rf usr
                rm -rf etc
                rm -rf var
                mv var/log log
                chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['telegraf']['home']}
                chmod 750 #{node['telegraf']['home']}
                touch #{telegraf_downloaded}
                chown #{node['hopsmonitor']['user']} #{telegraf_downloaded}
        EOH
     not_if { ::File.exists?( telegraf_downloaded ) }
end

link node['telegraf']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['telegraf']['home']
end

bash 'remove_auth.log_policy' do
  user 'root'
  group 'root'
  code <<-EOH
       sed -i '/\\/var\\/log\\/auth.log/d' /etc/logrotate.d/rsyslog
  EOH
  only_if { ::File.exist?('/etc/logrotate.d/rsyslog') }
end

cookbook_file '/etc/logrotate.d/auth' do
  source 'auth'
  owner 'root'
  group 'root'
  mode '0644'
end

template "/etc/logrotate.d/telegraf" do
  source "logrotate.telegraf.erb"
  owner "root"
  group "root"
  mode 0655
end

directory "#{node['telegraf']['base_dir']}/log" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
end

my_ip = my_private_ip()
influx_ip = private_recipe_ip("hopsmonitor","default")

# Query any local zookeeper broker
found_zk = ""
for zk in node['kzookeeper']['default']['private_ips']
  if my_ip.eql? zk
    Chef::Log.info "Telegraf found matching zk IP address"
    found_zk = zk
  end
end

# Query any local elasticsearch broker
found_es = ""
for es in node['elastic']['default']['private_ips']
  if my_ip.eql? es
    Chef::Log.info "Telegraf found matching es IP address"
    found_es = es
  end
end

template "#{node['telegraf']['base_dir']}/conf/telegraf.conf" do
  source "telegraf.conf.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0750
  variables({
   :influx_ip => influx_ip,
   :zk_ip => found_zk,
   :elastic_ip => found_es
  })
end



case node['platform']
when "ubuntu"
 if node['platform_version'].to_f <= 14.04
   node.override['influxdb']['systemd'] = "false"
 end
end

service_name="telegraf"
if node['telegraf']['systemd'] == "true"

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

if node['kagent']['enabled'] == "true"
   kagent_config service_name do
     service "Monitoring"
     log_file "#{node['telegraf']['base_dir']}/log/telegraf.log"
   end
end

if node['install']['upgrade'] == "true"
  kagent_config "#{service_name}" do
    action :systemd_reload
  end
end  
