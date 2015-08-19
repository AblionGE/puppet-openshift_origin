# Copyright 2013 Mojo Lingo LLC.
# Modifications by Red Hat, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
class openshift_origin::datastore {
  anchor { 'openshift_origin::datastore_begin': } ->
  class { 'openshift_origin::firewall::mongodb': } ->
  anchor { 'openshift_origin::datastore_end': }

  package { ['mongodb', 'mongodb-server', 'rubygem-open4']:
    ensure  => present,
    require => Class['openshift_origin::install_method'],
  }

  $port = $openshift_origin::mongodb_port

  class {'::mongodb::server':
    port    => $port,
    auth    => true,
    verbose => true,
  } ->
  class {'::mongodb::client': }
  
  mongodb_user { 'mongodb_admin_user':
    name          => $openshift_origin::mongodb_admin_user,
    ensure        => present,
    password_hash => mongodb_password($openshift_origin::mongodb_admin_user,$openshift_origin::mongodb_admin_password),
    roles         => ['readWrite', 'dbAdmin'],
    tries         => 10,
    require       => Class['mongodb::server'],
  }
  mongodb_user { 'mongodb_broker_user':
    name          => $openshift_origin::mongodb_broker_user,
    ensure        => present,
    password_hash => mongodb_password($openshift_origin::mongodb_broker_user,$openshift_origin::mongodb_broker_password),
    roles         => ['readWrite'],
    tries         => 10,
    require       => Class['mongodb::server'],
  }

  mongodb::db { $openshift_origin::mongodb_name :
    user          => $openshift_origin::mongodb_broker_user,
    password_hash => mongodb_password($openshift_origin::mongodb_broker_user,$openshift_origin::mongodb_broker_password),
  }
    

#  file { 'mongo setup script':
#    ensure  => present,
#    path    => '/usr/sbin/oo-mongo-setup',
#    content => template('openshift_origin/mongodb/oo-mongo-setup'),
#    owner   => 'root',
#    group   => 'root',
#    mode    => '0700',
#    require => [
#      Package['mongodb'],
#      Package['mongodb-server'],
#      Package['rubygem-open4'],
#    ],
#  }
#
#  exec { '/usr/sbin/oo-mongo-setup':
#    command => '/usr/sbin/oo-mongo-setup',
#    timeout => 1800,
#    require => [
#      File['mongo setup script'],
#      Class['openshift_origin::update_conf_files'],
#    ],
#    creates => '/etc/openshift/.mongo-setup-complete',
#  }
#
#  if $openshift_origin::mongodb_replicasets {
#    file { $openshift_origin::mongodb_keyfile:
#      content => inline_template($openshift_origin::mongodb_key),
#      owner   => 'mongodb',
#      group   => 'mongodb',
#      mode    => '0400',
#      require => Exec['/usr/sbin/oo-mongo-setup'],
#      notify  => Service['mongod'],
#    }
#    exec { 'keyfile-mongo-conf':
#      path    => ['/bin/', '/usr/bin/', '/usr/sbin/'],
#      command => "echo -e \"\nkeyFile = ${openshift_origin::mongodb_keyfile}\n\" >> /etc/mongodb.conf",
#      unless  => "grep \"keyFile = ${openshift_origin::mongodb_keyfile}\" /etc/mongodb.conf",
#      require => File[$openshift_origin::mongodb_keyfile],
#      notify  => Service['mongod'],
#    }
#    exec { 'replset-mongo-conf':
#      path    => ['/bin/', '/usr/bin/', '/usr/sbin/'],
#      command => "echo -e \"\nreplSet = ${openshift_origin::mongodb_replica_name}\n\" >> /etc/mongodb.conf",
#      unless  => "grep \"replSet = ${openshift_origin::mongodb_replica_name}\" /etc/mongodb.conf",
#      require => [
#        File[$openshift_origin::mongodb_keyfile],
#        Exec['/usr/sbin/oo-mongo-setup']
#      ],
#      notify  => Service['mongod'],
#    }
#    if $openshift_origin::mongodb_replica_primary {
#      exec { 'replset-init':
#        path      => ['/bin/', '/usr/bin/', '/usr/sbin/'],
#        command   => "mongo admin -u ${openshift_origin::mongodb_admin_user} -p ${openshift_origin::mongodb_admin_password} --quiet --eval pr#intjson\"(rs.initiate({ _id: \'${openshift_origin::mongodb_replica_name}\', members: [ { _id: 0, host: \'${openshift_origin::node_ip_addr}:${#port}\' } ] }))\"",
#        unless    => "mongo admin --host ${openshift_origin::node_ip_addr} -u ${openshift_origin::mongodb_admin_user} -p ${openshift_origin::#mongodb_admin_password} --quiet --eval \"printjson(rs.status())\" | grep '\"name\" : \"${openshift_origin::node_ip_addr}:${port}\"'",
#        tries     => 3,
#        try_sleep => 5,
#        require   => [
#          Service['mongod'],
#          Exec['keyfile-mongo-conf', 'replset-mongo-conf']
#        ],
#      }
#    }
#    elsif $openshift_origin::parallel_deployment == false {
#      # Only run the replset-add command if we are not in the middle of instantiating multiple hosts at once.
#      exec { 'replset-add':
#        path      => ['/bin/', '/usr/bin/', '/usr/sbin/'],
#        command   => "mongo admin --host ${openshift_origin::mongodb_replica_primary_ip_addr} -u ${openshift_origin::mongodb_admin_user} -p $#{openshift_origin::mongodb_admin_password} --quiet --eval \"printjson(rs.add(\'${openshift_origin::node_ip_addr}:${port}\'))\"",
#        unless    => "mongo admin --host ${openshift_origin::mongodb_replica_primary_ip_addr} -u ${openshift_origin::mongodb_admin_user} -p $#{openshift_origin::mongodb_admin_password} --quiet --eval \"printjson(rs.status())\" | grep '\"name\" : \"${openshift_origin::node_ip_addr}:$#{port}\"'",
#        tries     => 6,
#        try_sleep => 30,
#        require   => [
#          Service['mongod'],
#          Exec['keyfile-mongo-conf', 'replset-mongo-conf']
#        ],
#      }
#    }
#  }
#
#  service { 'mongod':
#    require => [Package['mongodb'], Package['mongodb-server']],
#    enable  => true,
#  }
}
