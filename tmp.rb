#!/usr/bin/env ruby
# frozen_string_literal: true

# require 'sinatra'
# require 'sinatra/reloader'
# require 'erb'
require 'json'
require 'securerandom'
require 'date'
require 'pg'

connection = PG.connect(dbname: 'my_notes')

def make_table_name
  'notes'
end

note = connection.exec("SELECT * FROM #{make_table_name} WHERE id = 1").first
p note['title']


# helpers do
#   def h(str)
#     Rack::Utils.escape_html(str)
#   end
# end
# 
# set :show_exceptions, :after_handler if :environment == :production
# 
# error do
#   "エラーが発生しました。 - #{env['sinatra.error'].message}"
# end
# 
# not_found do
#   status 404
#   erb :page_not_found
# end
# 
# def make_app_name
#   'My Notes'
# end

# def make_json_path
#   './notes.json'
# end


def make_home_path
  '/home'
end

# def make_json_data
#   JSON.parse(File.open(make_json_path).read)
# end
# 
# def get_target_note_from_notes(notes, note_id)
#   notes.find { |note| note['id'] == note_id }
# end
# 
# def get_target_note(id)
#   # json_data = make_json_data
#   # get_target_note_from_notes(json_data['notes'], id)
#   connection.exec("SELECT * FROM #{make_table_name} WHERE id = #{id}")
# end
# 
# module Add
#   class << self
#     def add_note_to_json(params, id = SecureRandom.uuid)
#       json_data = make_json_data
#       new_note = make_new_note(params, id)
#       json_data['notes'] << new_note
#       json_data['notes'].sort_by! { |note| note['time'] }.reverse!
#       File.open(make_json_path, 'w') { |io| JSON.dump(json_data, io) }
#     end
# 
#     private
# 
#     def make_new_note(params, id)
#       title = params[:title] == '' ? '（無題）' : params[:title]
#       content = params[:content]
#       time = Time.now.to_i
#       { 'id' => id, 'title' => title, 'content' => content, 'time' => time }
#     end
#   end
# end
# 
# module Delete
#   class << self
#     def delete_note_from_json(id)
#       json_data = make_json_data
#       target_note = get_target_note_from_notes(json_data['notes'], id)
#       json_data['notes'].delete(target_note)
#       File.open(make_json_path, 'w') { |io| JSON.dump(json_data, io) }
#     end
# 
#     private
# 
#     def get_target_deleted_json_data(id)
#       json_data = make_json_data
#       target_note = get_target_note_from_notes(json_data['notes'], id)
#       json_data['notes'].delete(target_note)
#       json_data
#     end
#   end
# end
# 
# get make_home_path do
#   @title = "ホーム / #{make_app_name}"
#   json_data = make_json_data
#   @notes = json_data['notes']
#   erb :home
# end
# 
# get '/new' do
#   @title = "新規メモの追加 / #{make_app_name}"
#   erb :new
# end
# 
# post '/new' do
#   Add.add_note_to_json(params)
#   redirect to(make_home_path)
# end
# 
# get '/notes/:id' do |id|
#   @note = get_target_note(id)
#   @title = "メモ: #{@note['title']} / #{make_app_name}"
#   erb :note
# rescue NoMethodError
#   erb :page_not_found
# end
# 
# get '/notes/:id/edit' do |id|
#   @note = get_target_note(id)
#   @title = "変更: #{@note['title']} / #{make_app_name}"
#   erb :edit
# end
# 
# delete '/notes/:id' do |id|
#   Delete.delete_note_from_json(id)
#   redirect to(make_home_path)
# end
# 
# patch '/notes/:id/edit' do |id|
#   Delete.delete_note_from_json(id)
#   Add.add_note_to_json(params, id)
#   redirect to(make_home_path)
# end
