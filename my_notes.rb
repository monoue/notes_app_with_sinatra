#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'erb'
require 'json'
require 'securerandom'
require 'date'

helpers do
  def h(str)
    Rack::Utils.escape_html(str)
  end
end

set :show_exceptions, :after_handler if :environment == :production

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

def json_path
  './notes.json'
end

def home_path
  '/home'
end

def make_json_data
  JSON.parse(File.open(json_path).read)
end

def get_target_note_from_notes(notes, note_id)
  notes.find { |note| note['id'] == note_id }
end

def get_target_note(id)
  json_data = make_json_data
  get_target_note_from_notes(json_data['notes'], id)
end

module Validate
  class << self
    def note_invalid(note)
      return true if note.nil?

      [note['id'], note['title'], note['time']].include?(nil)
    end

    def target_note_invalid(id)
      target_note = get_target_note(id)
      note_invalid(target_note)
    end

    def notes_invalid(notes)
      notes.each { |note| return true if note_invalid(note) }
      false
    end
  end
end

module Note
  class << self
    def add_note_to_json(params, id = SecureRandom.uuid)
      json_data = make_json_data
      new_note = make_new_note(params, id)
      json_data['notes'] << new_note
      json_data['notes'].sort_by! { |note| note['time'] }.reverse!
      File.open(json_path, 'w') { |io| JSON.dump(json_data, io) }
    end

    def delete_note_from_json(id)
      json_data = make_json_data
      target_note = get_target_note_from_notes(json_data['notes'], id)
      return if Validate.note_invalid(target_note)

      json_data['notes'].delete(target_note)
      File.open(json_path, 'w') { |io| JSON.dump(json_data, io) }
    end

    private

    def make_new_note(params, id)
      title = params[:title] == '' ? '（無題）' : params[:title]
      content = params[:content]
      time = Time.now.to_i
      { 'id' => id, 'title' => title, 'content' => content, 'time' => time }
    end
  end
end

get home_path do
  @title = "ホーム / #{app_name}"
  json_data = make_json_data
  @notes = json_data['notes']
  if Validate.notes_invalid(@notes)
    erb :page_not_found
  else
    erb :home
  end
end

get '/notes/new' do
  @title = "新規メモの追加 / #{app_name}"
  erb :new
end

post '/notes/new' do
  Note.add_note_to_json(params)
  redirect to(home_path)
end

get '/notes/:id' do |id|
  @note = get_target_note(id)
  if Validate.note_invalid(@note)
    erb :page_not_found
  else
    @title = "メモ: #{@note['title']} / #{app_name}"
    erb :note
  end
end

get '/notes/:id/edit' do |id|
  @note = get_target_note(id)
  if Validate.note_invalid(@note)
    erb :page_not_found
  else
    @title = "変更: #{@note['title']} / #{app_name}"
    erb :edit
  end
end

delete '/notes/:id' do |id|
  if Validate.target_note_invalid(id)
    erb :page_not_found
  else
    Note.delete_note_from_json(id)
    redirect to(home_path)
  end
end

patch '/notes/:id' do |id|
  if Validate.target_note_invalid(id)
    erb :page_not_found
  else
    Note.delete_note_from_json(id)
    Note.add_note_to_json(params, id)
    redirect to(home_path)
  end
end
