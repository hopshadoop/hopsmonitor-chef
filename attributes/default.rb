include_attribute "kagent"
include_attribute "kzookeeper"
include_attribute "ndb"

default['hopsmonitor']['user']                    = node['install']['user'].empty? ? "hopsmon" : node['install']['user']
default['hopsmonitor']['group']                   = node['install']['user'].empty? ? "hopsmon" : node['install']['user']


default['hopsmonitor']['dir']                     = node['install']['dir'].empty? ? "/srv" : node['install']['dir']



default['influxdb']['version']                    = "1.2.1"
# https://dl.influxdata.com/influxdb/releases/influxdb-1.1.1_linux_amd64.tar.gz
default['influxdb']['url']                        = "#{node['download_url']}/influxdb-#{node['influxdb']['version']}_linux_amd64.tar.gz"

default['influxdb']['db_user']                    = "hopsworks"
default['influxdb']['db_password']                = "hopsworks"
default['influxdb']['telegraf_user']              = "telegraf"
default['influxdb']['telegraf_password']          = "telegraf"
default['influxdb']['admin_user']                 = "adminuser"
default['influxdb']['admin_password']             = "adminpw"

default['influxdb']['databases']                  = %w{ graphite telegraf }

# The default port is '8088' in influxdb (for backup/restore). This conflicts with yarn::rm, so we change it below
default['influxdb']['port']                       = "9999"
default['influxdb']['admin']['port']              = "8084"
default['influxdb']['http']['port']               = "8086"

default['influxdb']['systemd']                    = "true"
default['influxdb']['home']                       = node['hopsmonitor']['dir'] + "/influxdb-" + "#{node['influxdb']['version']}-1"
default['influxdb']['base_dir']                   = node['hopsmonitor']['dir'] + "/influxdb"
default['influxdb']['conf_dir']                   = node['influxdb']['base_dir'] + "/conf"
default['influxdb']['pid_file']                   = "/tmp/influxdb.pid"
default['influxdb']['graphite']['port']           = "2003"
default['influxdb']['series']['max']              = 0

default['grafana']['version']                     = "4.1.1-1484211277"
default['grafana']['url']                         = "#{node['download_url']}/grafana-#{node['grafana']['version']}.linux-x64.tar.gz"
default['grafana']['port']                        = 3000

default['grafana']['admin_user']                  = "adminuser"
default['grafana']['admin_password']              = "adminpw"

default['grafana']['mysql_user']                  = "grafana"
default['grafana']['mysql_password']              = "grafana"

default['grafana']['systemd']                     = "true"
default['grafana']['home']                        = node['hopsmonitor']['dir'] + "/grafana-" + "#{node['grafana']['version']}"
default['grafana']['base_dir']                    = node['hopsmonitor']['dir'] + "/grafana"
default['grafana']['pid_file']                    = "/tmp/grafana.pid"

default['telegraf']['version']                    = "1.2.1"
default['telegraf']['url']                        = "#{node['download_url']}/telegraf-#{node['telegraf']['version']}_linux_amd64.tar.gz"
default['telegraf']['systemd']                    = "true"
default['telegraf']['home']                       = node['hopsmonitor']['dir'] + "/telegraf-" + "#{node['telegraf']['version']}"
default['telegraf']['base_dir']                   = node['hopsmonitor']['dir'] + "/telegraf"
default['telegraf']['pid_file']                   = "/tmp/telegraf.pid"


default['kapacitor']['version']                   = "1.2.0"
default['kapacitor']['url']                       = "#{node['download_url']}/kapacitor-#{node['kapacitor']['version']}_linux_amd64.tar.gz"
default['kapacitor']['systemd']                   = "true"
default['kapacitor']['home']                      = node['hopsmonitor']['dir'] + "/kapacitor-" + "#{node['kapacitor']['version']}"
default['kapacitor']['base_dir']                  = node['hopsmonitor']['dir'] + "/kapacitor"
default['kapacitor']['pid_file']                  = "/tmp/kapacitor.pid"
default['kapacitor']['notify']['email']              = ""
default['kapacitor']['slack_enabled']             = "false"
default['kapacitor']['slack_url']                 = "https://hooks.slack.com/services/********/********/******"
default['kapacitor']['slack_channel']             = "#hops"

default['hopsmonitor']['default']['private_ips']  = ['10.0.2.15']
default['hopsmonitor']['default']['public_ips']   = ['10.0.2.15']
default['hopsmonitor']['public_ips']              = ['10.0.2.15']
default['hopsmonitor']['private_ips']             = ['10.0.2.15']

default['elastic']['default']['private_ips']      = ['10.0.2.15']
