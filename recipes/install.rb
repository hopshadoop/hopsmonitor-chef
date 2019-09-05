group node['hopsmonitor']['group'] do
  action :create
  not_if "getent group #{node['hopsmonitor']['group']}"
end

user node['hopsmonitor']['user'] do
  gid node['hopsmonitor']['group']
  action :create
  system true
  shell "/bin/bash"
  not_if "getent passwd #{node['hopsmonitor']['user']}"
end

group node['hopsmonitor']['group'] do
  action :modify
  members ["#{node['hopsmonitor']['user']}"]
  append true
end