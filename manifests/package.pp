# Internal: install the pg packages
class postgresql::package(
  $ensure  = $postgresql::params::ensure,

  $package = $postgresql::params::package,
  $version = $postgresql::params::version,
) inherits postgresql::params {

  $package_ensure = $ensure ? {
    present => $version,
    default => absent,
  }

  package { $package:
    ensure => $package_ensure
  }

}
