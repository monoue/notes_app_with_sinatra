require 'sinatra'
require 'sinatra/reloader'
require 'erb'
require 'json'

def get_json_path
  './notes.json'
end

get '/home' do
  File.open(get_json_path) do |file|
    @notes = JSON.load(file)['notes']
  end
  erb :home
end

get '/notes/:id' do |id|
  File.open(get_json_path) do |file|
    notes = JSON.load(file)['notes']
    @note = notes.find { |note| note['id'] == id }
  end
  erb :note
end

patch '/notes/:id' do |id|
  json_data = open(get_json_path) do |io|
    JSON.load(io)
  end
  target_note = json_data['notes'].find { |note| note['id'] == id }
  json_data['notes'].delete(target_note)
  open(get_json_path, 'w') { |io| JSON.dump(json_data, io) }
  redirect to ('/home')
end

delete '/notes/:id' do |id|
  json_data = open(get_json_path) do |io|
    JSON.load(io)
  end
  target_note = json_data['notes'].find { |note| note['id'] == id }
  json_data['notes'].delete(target_note)
  open(get_json_path, 'w') { |io| JSON.dump(json_data, io) }
  redirect to ('/home')
end

get '/new' do
  erb :new
end
