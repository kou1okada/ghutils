#!/usr/bin/env ruby
#
# gistlist.rb
# Copyright (c) 2021 Koichi OKADA. All rights reserved.
# This script is distributed under the MIT license.
#
require "graphql/client"
require "graphql/client/http"
require "fileutils"
require "optparse"
require "json"

$config = {}

CONFIGDIR=File.expand_path("~/.config/ghutils")
CACHEDIR="/tmp/.cache/ghutils"
config_file="#{CONFIGDIR}/config.json"
schema_cache="#{CACHEDIR}/schema.marshal"
FileUtils.mkdir_p [CACHEDIR, CONFIGDIR]

$config.merge! JSON.parse IO.read config_file if File.exist? config_file

opts = OptionParser.new
opts.banner = "Usage: #{File.basename $0} [<username> ...]"
opts.on("-t", "--token TOKEN"){|v| $config["token"]=v}
opts.parse! ARGV

if $config["token"].nil?
  STDERR.puts <<~EOD
    \e[31;1mError:\e[0m token is not set.
      Please use "-t TOKEN" option
      or add {"token": "TOKEN"} to #{config_file}.
    EOD
  exit 1
end

HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
  def headers(context)
    { "Authorization": "Bearer #{$config["token"]}" }
  end
end

if File.exist? schema_cache
  Schema = GraphQL::Client.load_schema(Marshal.load(IO.read schema_cache))
else
  schema_hash = GraphQL::Client.dump_schema(HTTP)
  IO.write schema_cache, Marshal.dump(schema_hash)
  Schema = GraphQL::Client.load_schema(schema_hash)
end

Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

Gists = Client.parse <<~'GRAPHQL'
  query($first: Int, $user: String!) {
    user(login: $user) {
      gists(privacy: ALL, first: $first) {
        totalCount
        edges {
          cursor
          node {
            isFork
            isPublic
            description
            url
            forks(first:0) {totalCount}
            stargazerCount 
            createdAt
            updatedAt
          }
        }
        pageInfo{ hasPreviousPage hasNextPage } 
      }
    }
  }
GRAPHQL

GistsAfter = Client.parse <<~'GRAPHQL'
  query($first: Int, $user: String!, $after: String) {
    user(login: $user) {
      gists(privacy: ALL, first: $first, after: $after) {
        totalCount
        edges {
          cursor
          node {
            isFork
            isPublic
            description
            url
            forks(first:0) {totalCount}
            stargazerCount 
            createdAt
            updatedAt
          }
        }
        pageInfo{ hasPreviousPage hasNextPage } 
      }
    }
  }
GRAPHQL

def gist_info gist
  v = gist
  puts <<~EOD
  #{"-"*40}
  public          : #{v.is_public}
  fork            : #{v.is_fork}
  description     : #{v.description}
  url             : #{v.url}
  fork_count      : #{v.forks.total_count}
  stargazer_count : #{v.stargazer_count}
  created_at      : #{v.created_at}
  updated_at      : #{v.updated_at}
  EOD
end

ARGV.each{|user|
  first = 100
  result = Client.query(Gists, variables: {first: first, user: user})
  result.data.user.gists.edges.each{|v| gist_info v.node}
  while result.data.user.gists.page_info.has_next_page
    after = result.data.user.gists.edges[-1].cursor
    result = Client.query(GistsAfter, variables: {first: first, user: user, after: after})
    result.data.user.gists.edges.each{|v| gist_info v.node}
  end
  puts "-"*40
}
