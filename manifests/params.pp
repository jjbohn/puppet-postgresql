# Internal: defaults
class postgresql::params {

  case $::operatingsystem {
    Darwin: {
      include boxen::config

      $executable = "${boxen::config::home}/homebrew/bin/postgres"
      $datadir    = "${boxen::config::datadir}/postgresql"
      $logdir     = "${boxen::config::logdir}/postgresql"
      $port       = 15432

      $package    = 'boxen/brews/postgresql'
      $version    = '9.3.2-boxen'

      $service    = 'dev.postgresql'

      $user       = $::boxen_user
    }

    Ubuntu: {
      $executable = undef # only used on Darwin
      $datadir    = '/var/lib/postgresql'
      $logdir     = '/var/log/postgresql'
      $port       = 5432

      $package    = 'postgresql-server-9.3'
      $version    = installed

      $service    = 'postgresql-9.3'

      $user       = 'postgresql'
    }

    default: {
      fail('Unsupported operating system!')
    }
  }

  $ensure = present
  $host   = $::ipaddress_lo0
  $enable = true

}
