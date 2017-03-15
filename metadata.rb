maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
name             "hopsmonitor"
license          "Apache v2.0"
description      "Installs/Configures a HopsFS to ElasticSearch connector"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"
source_url       "https://github.com/hopshadoop/hopsmonitor-chef"

%w{ ubuntu debian centos }.each do |os|
  supports os
end

depends 'java'
depends 'kagent'
#depends 'chef-grafana'
depends 'elastic'
depends 'influxdb'
depends 'ndb'
depends 'kzookeeper'

#depends 'runit'
#depends 'grafana'
#depends 'apt'
#depends 'yum'
#depends 'nginx'

recipe "hopsmonitor::install", "Installs Influxdb/Grafana Server"
recipe "hopsmonitor::default", "configures Influxdb/Grafana Server"
recipe "hopsmonitor::kapacitor", "Configures/starts a kapacitor agent "
recipe "hopsmonitor::telegraf", "Configures/starts a telegraf agent "
recipe "hopsmonitor::purge", "Deletes the Influxdb/Grafana Server"

attribute "hopsmonitor/user",
          :description => "User to run Influxdb/Grafana server as",
          :type => "string"

attribute "hopsmonitor/group",
          :description => "Group to run Influxdb/Grafana server as",
          :type => "string"

attribute "hopsmonitor/dir",
          :description => "Base install directory for Influxdb/Grafana ",
          :type => "string"


#
# InfluxDB
#

attribute "influxdb/db_user",
          :description => "username for influxdb account used by hopsworks ",
          :type => "string"

attribute "influxdb/db_password",
          :description => "Password for influxdb account used by hopsworks",
          :type => "string"

attribute "influxdb/admin_user",
          :description => "username for influxdb admin ",
          :type => "string"

attribute "influxdb/admin_password",
          :description => "Password for influxdb admin user",
          :type => "string"


attribute "influxdb/http/port",
          :description => "Http port for influxdb",
          :type => "string"

attribute "influxdb/port",
          :description => "Main port for influxdb",
          :type => "string"

attribute "influxdb/admin/port",
          :description => "Admin port for influxdb",
          :type => "string"

attribute "influxdb/graphite/port",
          :description => "Port for influxdb graphite connector",
          :type => "string"



#
# Grafana
#


attribute "grafana/admin_user",
          :description => "username for grafana admin ",
          :type => "string"

attribute "grafana/admin_password",
          :description => "Password for grafana admin user",
          :type => "string"


attribute "grafana/mysql_user",
          :description => "username for grafana mysql user ",
          :type => "string"

attribute "grafana/mysql_password",
          :description => "Password for grafana mysql user",
          :type => "string"

attribute "grafana/port",
          :description => "Port for grafana",
          :type => "string"

#
# Kapacitor
#

attribute "kapacitor/notify/email",
          :description => "Send notification emails to this address",
          :type => "string"

attribute "kapacitor/slack_enabled",
          :description => "Send notifications to slack",
          :type => "string"

attribute "kapacitor/slack_url",
          :description => "Slack url hook.",
          :type => "string"

attribute "kapacitor/slack_channel",
          :description => "Slack channel name",
          :type => "string"


#
# Telegraf
#

attribute "telegraf/",
          :description => "",
          :type => "string"



#
# General
#

attribute "install/dir",
          :description => "Set to a base directory under which we will install.",
          :type => "string"

attribute "install/user",
          :description => "User to install the services as",
          :type => "string"
