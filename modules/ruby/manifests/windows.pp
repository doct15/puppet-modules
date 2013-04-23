# == Class: ruby::windows
#
# This installs Ruby on Windows.
#
class ruby::windows(
  $install_dir = undef,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
) {
  $devkit_source_url = "http://rubyforge.org/frs/download.php/76805/DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe/noredirect"
  $devkit_installer_path = "${file_cache_dir}\\devkit.exe"
  $ruby_source_url = "http://cdn.rubyinstaller.org/archives/1.9.3-p392/rubyinstaller-1.9.3-p392.exe"
  $ruby_installer_path = "${file_cache_dir}\\ruby.exe"

  $extra_args = $install_dir ? {
    undef   => "",
    default => " /dir=\"${install_dir}\"",
  }

  #------------------------------------------------------------------
  # Ruby
  #------------------------------------------------------------------
  download { "ruby":
    source      => $ruby_source_url,
    destination => $ruby_installer_path,
  }

  exec { "install-ruby":
    command => "cmd.exe /C ${ruby_installer_path} /silent${extra_args}",
    creates => "${install_dir}/bin/ruby.exe",
    require => Download["ruby"],
  }

  #------------------------------------------------------------------
  # Ruby DevKit
  #------------------------------------------------------------------
  download { "ruby-devkit":
    source      => $devkit_source_url,
    destination => $devkit_installer_path,
  }

  exec { "extract-devkit":
    command => "cmd.exe /C ${devkit_installer_path} -y -o\"${install_dir}\"",
    creates => "${install_dir}/dk.rb",
    require => [
      Download["ruby-devkit"],
      Exec["install-ruby"],
    ],
  }

  file { "${install_dir}/config.yml":
    content => template("ruby/windows/config.yml.erb"),
    require => Exec["extract-devkit"],
  }

  exec { "install-devkit":
    command => "cmd.exe /C ${install_dir}\\bin\\ruby.exe dk.rb install",
    creates => "${install_dir}/lib/ruby/site_ruby/devkit.rb",
    cwd     => $install_dir,
    require => [
      Exec["extract-devkit"],
      File["${install_dir}/config.yml"],
    ],
  }
}
