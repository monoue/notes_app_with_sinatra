#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'erb'
require 'securerandom'
require 'pg'

set :show_exceptions, :after_handler if :environment == :production

helpers do
  def h(str)
    Rack::Utils.escape_html(str)
  end
end

module Connect
  class << self
    def make_connection
      PG.connect(dbname: make_db_name)
    end

    private

    def make_db_name
      'my_notes'
    end
  end
end

def make_table_name
  'notes'
end

def make_app_name
  'My Notes'
end

def make_home_path
  '/home'
end

def get_target_note(connection, id)
  sql = "SELECT * FROM #{make_table_name} WHERE id = $1"
  connection.exec(sql, [id]).first
end

error do
  "エラーが発生しました。 - #{env['sinatra.error'].message}"
end

not_found do
  status 404
  erb :page_not_found
end

connection = Connect.make_connection

get make_home_path do
  @title = "ホーム / #{make_app_name}"
  @notes = connection.exec("SELECT * FROM #{make_table_name} ORDER BY timestamp DESC")
  erb :home
end

get '/new' do
  @title = "新規メモの追加 / #{make_app_name}"
  erb :new
end

def add_note(connection, params)
  title = params[:title] == '' ? '（無題）' : params[:title]
  connection.exec("INSERT INTO #{make_table_name} (title, content) VALUES ($1, $2)", [title, params[:content]])
end

post '/new' do
  add_note(connection, params)
  redirect to(make_home_path)
end

get '/notes/:id' do |id|
  @note = get_target_note(connection, id)
  @title = "メモ: #{@note['title']} / #{make_app_name}"
  erb :note
rescue NoMethodError
  erb :page_not_found
end

get '/notes/:id/edit' do |id|
  @note = get_target_note(connection, id)
  @title = "変更: #{@note['title']} / #{make_app_name}"
  erb :edit
end

def delete_note(connection, id)
  connection.exec("DELETE FROM #{make_table_name} WHERE id = $1", [id])
end

delete '/notes/:id' do |id|
  delete_note(connection, id)
  redirect to(make_home_path)
end

def update_target_note(connection, params, id)
  connection.exec("UPDATE #{make_table_name} SET title = $1, content = $2 WHERE id = $3", [params[:title], params[:content], id])
end

patch '/notes/:id/edit' do |id|
  update_target_note(connection, params, id)
  redirect to(make_home_path)
end
