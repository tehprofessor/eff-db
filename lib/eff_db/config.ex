# config.ex
# Created by seve on Oct 24 2019
#
# This is part of the EffDB application.
#
# Copyright (c) 2019 tehprofessor - All Rights Reserved

defmodule EffDB.Config do
  @moduledoc """
  Note: Parts of this will need to be refactored down the line as
  somethings in here would be better stored with `persistent_term`,
  rather than ETS.
  """
  @namespace :eff_db

  @fdb_version 610 # Currently max supported API version
  @cluster_file "/usr/local/etc/foundationdb/fdb.cluster"

  @storable FDB.Database
  @transactable FDB.Transaction

  def fdb_version, do: c(:fdb_version, @fdb_version)
  def cluster_file, do: c(:cluster_file, @cluster_file)
  def storable, do: c(:storable, @storable)
  def transactable, do: c(:transactable, @transactable)
  def cluster_db, do: c(:cluster_db, nil)

  defp c(key, default), do: Application.get_env(@namespace, key, default)
end
