group node['hopsmonitor']['group'] do
  action :create
  not_if "getent group #{node['hopsmonitor']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['hopsmonitor']['user'] do
  gid node['hopsmonitor']['group']
  action :create
  system true
  shell "/bin/bash"
  not_if "getent passwd #{node['hopsmonitor']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hopsmonitor']['group'] do
  action :modify
  members ["#{node['hopsmonitor']['user']}"]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node["kagent"]["certs_group"] do
  action :manage
  append true
  excluded_members node['hopsmonitor']['user']
  not_if { node['install']['external_users'].casecmp("true") == 0 }
  only_if { conda_helpers.is_upgrade }
end

directory node['data']['dir'] do
  owner 'root'
  group 'root'
  mode '0775'
  action :create
  not_if { ::File.directory?(node['data']['dir']) }
end