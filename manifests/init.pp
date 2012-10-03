class postgresql {
  require postgresql::config
  require sysctl

  sysctl::set { 'kern.sysv.shmmax':
    value => 1610612736
  }

  sysctl::set { 'kern.sysv.shmall':
    value => 393216
  }

  package { 'boxen/brews/postgresql':
    ensure => '9.1.4-boxen2',
    notify => Service['com.boxen.postgresql']
  }

  exec { 'init-postgresql-db':
    command => "initdb -E UTF-8 ${postgresql::config::datadir}",
    creates => "${postgresql::config::datadir}/PG_VERSION",
    require => Package['boxen/brews/postgresql']
  }

  service { 'com.boxen.postgresql':
    ensure  => running,
    require => Exec['init-postgresql-db']
  }

  file { "${boxen::config::envdir}/postgresql.sh":
    content => template('postgresql/env.sh.erb'),
    require => File[$boxen::config::envdir]
  }

  $nc = "nc -z localhost ${postgresql::config::port}"

  exec { 'wait-for-postgresql':
    command  => "while ! ${nc}; do sleep 1; done",
    provider => shell,
    timeout  => 30,
    unless   => $nc,
    require  => Service['com.boxen.postgresql']
  }
}
