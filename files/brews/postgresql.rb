require 'formula'

class Postgresql < Formula
  homepage 'http://www.postgresql.org/'
  url 'http://ftp.postgresql.org/pub/source/v9.3.2/postgresql-9.3.2.tar.bz2'
  sha256 '700da51a71857e092f6af1c85fcd86b46d7d5cd2f2ba343cafb1f206c20232d7'
  version '9.3.2-boxen'

  depends_on 'readline'
  depends_on 'ossp-uuid'

  def options
    [
      ['--32-bit', 'Build 32-bit only.'],
      ['--no-python', 'Build without Python support.'],
      ['--no-perl', 'Build without Perl support.'],
      ['--enable-dtrace', 'Build with DTrace support.']
    ]
  end

  # Fix uuid-ossp build issues: http://archives.postgresql.org/pgsql-general/2012-07/msg00654.php
  def patches
    DATA
  end

  skip_clean :all

  fails_with :clang do
    build 211
    cause 'Miscompilation resulting in segfault on queries'
  end

  def install
    ENV.libxml2 if MacOS.snow_leopard?

    args = [
      "--disable-debug",
      "--prefix=#{prefix}",
      "--datadir=#{share}/#{name}",
      "--docdir=#{doc}",
      "--enable-thread-safety",
      "--with-bonjour",
      "--with-gssapi",
      "--with-krb5",
      "--with-openssl",
      "--with-libxml",
      "--with-libxslt",
      "--with-libedit"
    ]

    args << "--with-ossp-uuid" unless ARGV.include? '--no-ossp-uuid'
    args << "--with-python" unless ARGV.include? '--no-python'
    args << "--with-perl" unless ARGV.include? '--no-perl'
    args << "--enable-dtrace" if ARGV.include? '--enable-dtrace'

    ENV.append 'CFLAGS', `uuid-config --cflags`.strip
    ENV.append 'LDFLAGS', `uuid-config --ldflags`.strip
    ENV.append 'LIBS', `uuid-config --libs`.strip

    if not ARGV.build_32_bit? and MacOS.prefer_64_bit? and not ARGV.include? '--no-python'
      args << "ARCHFLAGS='-arch x86_64'"
      check_python_arch
    end

    if ARGV.build_32_bit?
      ENV.append 'CFLAGS', '-arch i386'
      ENV.append 'LDFLAGS', '-arch i386'
    end

    # Fails on Core Duo with O4 and O3
    ENV.O2 if Hardware.intel_family == :core

    system "./configure", *args
    system "make install-world"
  end

  def check_python_arch
    # On 64-bit systems, we need to look for a 32-bit Framework Python.
    # The configure script prefers this Python version, and if it doesn't
    # have 64-bit support then linking will fail.
    framework_python = Pathname.new "/Library/Frameworks/Python.framework/Versions/Current/Python"
    return unless framework_python.exist?
    unless (archs_for_command framework_python).include? :x86_64
      opoo "Detected a framework Python that does not have 64-bit support in:"
      puts <<-EOS.undent
          #{framework_python}

        The configure script seems to prefer this version of Python over any others,
        so you may experience linker problems as described in:
          http://osdir.com/ml/pgsql-general/2009-09/msg00160.html

        To fix this issue, you may need to either delete the version of Python
        shown above, or move it out of the way before brewing PostgreSQL.

        Note that a framework Python in /Library/Frameworks/Python.framework is
        the "MacPython" version, and not the system-provided version which is in:
          /System/Library/Frameworks/Python.framework
      EOS
    end
  end
end

__END__
--- a/contrib/uuid-ossp/uuid-ossp.c
+++ b/contrib/uuid-ossp/uuid-ossp.c
@@ -9,6 +9,8 @@
  *-------------------------------------------------------------------------
  */

+#define _XOPEN_SOURCE
+
 #include "postgres.h"
 #include "fmgr.h"
 #include "utils/builtins.h"
