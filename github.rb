#!/usr/bin/ruby -w

ENV['GEM_PATH'] = "tmp"

require 'rubygems'
$:.unshift 'lib'
require 'rc_rest'
require 'json'
require 'pp'

module Net
  class HTTPGenericRequest
    remove_method :inspect
  end

  class HTTP
    class Patch < HTTPRequest
      METHOD = 'PATCH'
      REQUEST_HAS_BODY = true
      RESPONSE_HAS_BODY = true
    end
  end
end

class Github < RCRest
  def initialize username = nil, password = nil
    @username = username || `git config github.user`.chomp
    @password = password || `git config github.password`.chomp

    @github = URI.parse "https://api.github.com/"
  end

  def http_json klass, url, data = nil
    req = klass.new url
    req.content_type = 'application/json'
    req.basic_auth @username, @password
    req.body = JSON.dump data if data

    http = Net::HTTP.new @github.host, @github.port
    http.use_ssl = true

    http.start do
      http.request(req).body
    end
  end

  def get_json url
    JSON.parse http_json Net::HTTP::Get, url
  end

  def post_json url, data
    JSON.parse http_json Net::HTTP::Post, url, data
  end

  def delete_json url
    http_json Net::HTTP::Delete, url
    nil
  end

  def patch_json url, data
    JSON.parse http_json Net::HTTP::Patch, url, data
  end

  def self.api name, path, *fields
    names = "#{name}s"
    id_path = "#{path}/:id"

    url_fields   = path.scan(/:(\w+)/).flatten
    args         = url_fields
    post_args    = url_fields + fields
    post_id_args = url_fields + ["id"] + fields
    id_args      = url_fields + ["id"]
    url          = path.gsub(/:(\w+)/) { "#\{#{$1}}" }
    id_url       = url + "/#\{id}"
    body         = fields.map { |f| "#{f.inspect} => #{f}" }

    src = <<-EOM
      # #{names}       =>    GET #{path}
      def #{names} #{args.join ', '}
        get_json "#{url}"
      end

      # #{name}        =>    GET #{id_path}
      def #{name} #{id_args.join ', '}
        get_json "#{id_url}"
      end

      # #{name}_new    =>   POST #{path}
      def #{name}_new #{post_args.join ', '}
        post_json("#{url}", #{body.join ", "})
      end

      # #{name}_update =>  PATCH #{id_path}
      def #{name}_update #{id_args.join ', '}, data
        patch_json("#{id_url}", data)
      end

      # #{name}_delete => DELETE #{id_path}
      def #{name}_delete #{id_args.join ', '}
        delete_json "#{id_url}"
      end
    EOM

    eval src
  end

  # GET    /repos/:user/:repo/labels
  # GET    /repos/:user/:repo/labels/:id
  # POST   /repos/:user/:repo/labels,     "name" => name, "color" => color
  # PATCH  /repos/:user/:repo/labels/:id, "name" => name, "color" => color
  # DELETE /repos/:user/:repo/labels/:id

  api "label", "/repos/:user/:repo/labels", "name", "color"

  # not done yet:

  # GET  /orgs/:org/repos
  # POST /orgs/:org/repos

  api "all_repo", "/orgs/:org/repos"

  # GET /users/:user/repos

  # GET   /repos/:user/:repo
  # PATCH /repos/:user/:repo

  api "repo", "/repos/:user" # :repo = :id

  # GET   /repos/:user/:repo/branches

  # GET   /repos/:user/:repo/contributors

  # GET   /repos/:user/:repo/languages

  # GET   /repos/:user/:repo/tags

  # GET   /repos/:user/:repo/teams

  # GET  /user/repos
  # POST /user/repos

  # and many more...
end

github = Github.new

data     = github.all_repos "seattlerb"
repos    = data.map { |h| h["name"] }.sort
standard = [{"color"=>"02d7e1", "name"=>"status - accepted"},
            {"color"=>"02d7e1", "name"=>"status - feedback"},
            {"color"=>"02d7e1", "name"=>"status - rejected"},
            {"color"=>"e10c02", "name"=>"type - bug"},
            {"color"=>"02e10c", "name"=>"type - feature"}]

repos.each do |repo|
  p repo
  standard.each do |h|
    github.label_new "seattlerb", repo, h["name"], h["color"]
  end

  github.repo_update "seattlerb", repo, "has_issues" => true
end
