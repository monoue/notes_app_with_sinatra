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

error do
  "エラーが発生しました。 - #{env['sinatra.error'].message}"
end

not_found do
  status 404
  erb :page_not_found
end

def app_name
  'My Notes'
end

def table_name
  'notes'
end

def home_path
  '/home'
end

module Connect
  class << self
    def make_connection
      PG.connect(dbname: db_name)
    end

    private

    def db_name
      'my_notes'
    end
  end
end

def make_page_title(description)
  "#{description} / #{app_name}"
end

def get_target_note(connection, id)
  sql = "SELECT * FROM #{table_name} WHERE id = $1"
  connection.exec(sql, [id]).first
end

connection = Connect.make_connection

module Validate
  class << self
    def note_invalid?(note)
      return true if note.nil?

      [note['id'], note['title'], note['timestamp']].include?(nil)
    end

    def target_note_invalid?(id)
      target_note = get_target_note(Connect.make_connection, id)
      note_invalid?(target_note)
    end

    def notes_invalid?(notes)
      notes.any? { |note| note_invalid?(note) }
    end
  end
end

module Note
  class << self
    def add_note(connection, params)
      title = params[:title] == '' ? '（無題）' : params[:title]
      connection.exec(
        "INSERT INTO #{table_name} (title, content) VALUES ($1, $2)",
        [title, params[:content]]
      )
    end

    def delete_note(connection, id)
      connection.exec("DELETE FROM #{table_name} WHERE id = $1", [id])
    end

    def update_note(connection, params, id)
      connection.exec(
        "UPDATE #{table_name} SET title = $1, content = $2 WHERE id = $3",
        [params[:title], params[:content], id]
      )
    end
  end
end

get home_path do
  @title = make_page_title('ホーム')
  @notes = connection.exec("SELECT * FROM #{table_name} ORDER BY timestamp DESC")
  if Validate.notes_invalid?(@notes)
    erb :page_not_found
  else
    erb :home
  end
end

get '/notes/new' do
  @title = make_page_title('新規メモの追加')
  erb :new
end

post '/notes' do
  Note.add_note(connection, params)
  redirect to(home_path)
end

get '/notes/:id' do |id|
  @note = get_target_note(connection, id)
  if Validate.note_invalid?(@note)
    erb :page_not_found
  else
    @title = make_page_title("メモ: #{@note['title']}")
    erb :note
  end
end

get '/notes/:id/edit' do |id|
  @note = get_target_note(connection, id)
  if Validate.note_invalid?(@note)
    erb :page_not_found
  else
    @title = make_page_title("変更: #{@note['title']}")
    erb :edit
  end
end

delete '/notes/:id' do |id|
  if Validate.target_note_invalid?(id)
    erb :page_not_found
  else
    Note.delete_note(connection, id)
    redirect to(home_path)
  end
end

patch '/notes/:id/edit' do |id|
  if Validate.target_note_invalid?(id)
    erb :page_not_found
  else
    Note.update_note(connection, params, id)
    redirect to(home_path)
  end
end
