# frozen_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'securerandom'
require 'gauntlt'
require 'optimist'

SERVER_CRT = File.join(File.dirname(__FILE__), 'files', 'server.crt')
SERVER_KEY = File.join(File.dirname(__FILE__), 'files', 'server.key')

USER_SECRET = ENV['USER_SECRET'].freeze || 'secret'.freeze
ENROLL_SECRET = ENV['TLS_ENROLL_SECRET'].freeze || 'secret'.freeze
BAD_USER_RESPONSE = '{"user_invalid": "true"}'.freeze
BAD_NODE_RESPONSE = '{"node_invalid": "true"}'.freeze

class Server < Sinatra::Base
  @@node_ids = []

  configure do
    set :bind, '0.0.0.0'
    set :node_ids, []
    set :ssl_certificate, SERVER_CRT
    set :ssl_key, SERVER_KEY
    set :port, ENV['SINATRA_PORT']
  end

  def verify_user
    if @parsed['user_secret'] != USER_SECRET
      halt 400, BAD_USER_RESPONSE
    end
  end

  def verify_node
    if !@@node_ids.include? @parsed['node_key']
      puts "invalid! node key: #{@parsed['node_key']}, node_ids: #{@@node_ids}"
      halt 200, {'Content-Type' => 'text/javascript'}, json({ :node_invalid => true })
    end
  end

  def generate_node_key(host)
    id = host + '-' + SecureRandom.uuid
    @@node_ids << id
    id
  end

  before do
    request.body.rewind
    print " -- ", request.request_method, " - ", request.path, "\n"

    begin
      @parsed = JSON.parse(request.body.read) if request.body.length != 0
    rescue JSON::ParserError => e
      halt 400, e.inspect
    end
  end

  after do
    print " ", response.status, " <- ", request.body.string, "\n"
    headers \
      'Allow'   => %w[POST GET PATCH],
      'Content-Type' => 'application/json'
  end

  def self.run!
    @@node_ids = []
    Dir.mkdir('results') unless File.exists?('results')

    super do |server|
      server.ssl = true
      server.ssl_options = {
        :cert_chain_file  => SERVER_CRT,
        :private_key_file => SERVER_KEY,
        :verify_peer      => false
      }
    end
  end

  ### GET ###

  get '/' do
    json :data => 'Hello World'
  end

  get '/config' do
  end

  post '/nodes' do
    verify_user
    json :data => @@node_ids
  end

  post '/adhoc-result' do
    verify_node
    verify_user

    file = File.join('results', @parsed['node_key'], 'ff_addon.result')
    data = File.read(file)

    json :data => data
  end

  ### POST ###

  post '/enroll' do
    if @parsed['enroll_secret'] == ENROLL_SECRET
      uuid = generate_node_key(request.host)

      json({
        'node_invalid' => false,
        'node_key' => uuid
      })
    else
      BAD_NODE_RESPONSE
    end
  end

  post '/config' do
    verify_node
  end

  post '/log' do
    verify_node
  end

  post '/distributed_read' do
    verify_node

    json({
      :queries => { "windows-patches" => "SELECT * from patches;" },
      :node_invalid => false
    })
  end

  post '/distributed_write' do
    verify_node

    node_key = @parsed['node_key']
    out_dir = File.join('results', node_key)
    Dir.mkdir(out_dir) unless File.exists?(out_dir)

    queries = @parsed['queries']
    queries.each do |(query_id, results)|
      out_file = File.join(out_dir, query_id + '.result')
      results.each do |result|
        open(out_file, 'w') { |f| f.puts json(result) }
      end
    end
  end

  post '/gauntlt-exec' do
    @a = nil
    node_key = @parsed['node_key']
    out_dir = File.join('results', node_key)

    Kernel.system "rm -rf results/*"
    Dir.mkdir(out_dir) unless File.exists?(out_dir)

    begin
      Gauntlt::Attack.new(
        File.join(File.dirname(__FILE__), 'examples', 'generic.attack'),
        '',
        'json',
        File.join(out_dir, 'result.log')
      ).run
      sleep 2
    rescue SystemExit
    end

    json :data => "Ran successfully!"
  end

  run! if app_file == $0
end
