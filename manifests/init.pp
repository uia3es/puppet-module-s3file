# Definition: s3file
#
# This definition fetches and keeps synchonized a file stored in S3
#
# Parameters:
# - $name: The local target of the file
# - $source: The bucket and filename on S3
# - $ensure: 'present', 'absent', or 'latest': as the core File resource
# - $s3_domain: s3 server to fetch the file from
# - $vpc_endpoint: true or false
#
# Requires:
# - cURL
#
# Sample Usage:
#
#  s3file { '/opt/minecraft/minecraft_server.jar':
#    source => 'MinecraftDownload/launcher/minecraft_server.jar',
#    ensure => 'latest',
#  }
#
define s3file (
  $source,
  $ensure = 'latest',
  $s3_domain = 's3.amazonaws.com',
  $vpc_endpoint = false,
)
{
  $valid_ensures = [ 'absent', 'present', 'latest' ]
  validate_re($ensure, $valid_ensures)
  if $ensure == 'absent' {
    # We use a puppet resource here to force the file to absent state
    file { $name:
      ensure => absent
    }
  } else {
    if $vpc_endpoint == true {
      $bucket_file_array = split($source, '/')
      $bucket_array = [$bucket_file_array[0],]
      $file_array = difference($bucket_file_array,$bucket_array)
      $file = join($file_array, "/")
      $real_source = "https://${bucket_array[0]}.${s3_domain}/${file}"
    } else {
      $real_source = "https://${s3_domain}/${source}"
    }
    if $ensure == 'latest' {
      $unless = "[ -e ${name} ] && curl -I ${real_source} | grep ETag | grep `md5sum ${name} | cut -c1-32`"
    } else {
      $unless = "[ -e ${name} ]"
    }
    exec { "fetch ${name}":
      path    => ['/bin', '/usr/bin', 'sbin', '/usr/sbin'],
      command => "curl -L -o ${name} ${real_source}",
      unless  => $unless
    }
  }
}
