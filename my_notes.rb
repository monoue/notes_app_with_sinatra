#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader'
require 'erb'
require 'json'
require 'securerandom'
require 'date'

# set :environment, :production
set :show_exceptions, :after_handler if :environment == :production

error do
  'エラーが発生しました。 - ' + env['sinatra.error'].message
end

def get_json_path
  './notes.json'
end

def get_target_note_from_notes(notes, note_id)
  notes.find { |note| note['id'] == note_id }
end

def get_json_data
  open(get_json_path) { |io| JSON.load(io) }
end

def get_target_note(id)
  json_data = get_json_data
  get_target_note_from_notes(json_data['notes'], id)
end

get '/home' do
  @title = 'ホーム / My Notes'
  json_data = get_json_data
  @notes = json_data['notes']
  erb :home
end

def make_new_note(params, id)
  title = params[:title] == '' ? '（無題）' : params[:title]
  content = params[:content]
  time = Time.now.to_i
  {"id"=> id, "title"=> title, "content"=> content, "time"=> time}
end

def add_note_to_json(params, id = SecureRandom.uuid)
  json_data = get_json_data
  new_note = make_new_note(params, id)
  json_data['notes'] << new_note
  json_data['notes'].sort_by! { |note| note["time"] }.reverse!
  open(get_json_path, 'w') { |io| JSON.dump(json_data, io) }
end

not_found do
  status 404
  erb :page_not_found
end

post '/new' do
  add_note_to_json(params)
  redirect to ('/home')
end

get '/notes/:id' do |id|
  @note = get_target_note(id)
  @title = "メモ: #{@note['title']}"
  erb :note
rescue NoMethodError
  erb :page_not_found
end

get '/notes/:id/edit' do |id|
  @note = get_target_note(id)
  @title = "変更: #{@note['title']}"
  erb :edit
end

def get_target_deleted_json_data(id)
  json_data = get_json_data
  target_note = get_target_note_from_notes(json_data['notes'], id)
  json_data['notes'].delete(target_note)
  json_data
end

def delete_note_from_json(id)
  json_data = get_json_data
  target_note = get_target_note_from_notes(json_data['notes'], id)
  json_data['notes'].delete(target_note)
  open(get_json_path, 'w') { |io| JSON.dump(json_data, io) }
end

patch '/notes/:id/edit' do |id|
  delete_note_from_json(id)
  add_note_to_json(params, id)
  redirect to ('/home')
end

def get_json_data
  open(get_json_path) { |io| JSON.load(io) }
end

patch '/notes/:id' do |id|
  target_deleted_json_data = get_target_deleted_json_data(id)
  open(get_json_path, 'w') { |io| JSON.dump(target_deleted_json_data, io) }
  redirect to ('/home')
end

delete '/notes/:id' do |id|
  delete_note_from_json(id)
  redirect to ('/home')
end

get '/new' do
  @title = '追加'
  erb :new
end
