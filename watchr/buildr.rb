def buildr_build
  puts 'Running buildr'
  system('buildr build')
end

watch( 'html/.*\.html'  ) { buildr_build }
watch( 'sass/.*\.sass' ) { buildr_build }
