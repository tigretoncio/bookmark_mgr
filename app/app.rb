require 'sinatra/base'
# require './app/models/link'
require_relative 'models/link'

class BookMarkManager < Sinatra::Base
  set :root, File.dirname(__FILE__)

  enable :sessions

  get '/links' do
    @links = Link.all
    erb :'links/index'
  end


  # start the server if ruby file executed directly
  run! if app_file == $PROGRAM_NAME
end
