# Ignore annoying compiler warnings 'bout protocols.
Code.compiler_options(ignore_module_conflict: true)

ExUnit.start()
{:ok, files} = File.ls("./test/support")

# Load support files
Enum.each files, fn(file) ->
  Code.require_file "support/#{file}", __DIR__
end
