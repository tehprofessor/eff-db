use Mix.Config

config :logger,
       level: :debug,
       metadata: :all

# This should always go on the last line... unless you want to accidentally
# override your environment variables.
import_config "#{Mix.env()}.exs"
