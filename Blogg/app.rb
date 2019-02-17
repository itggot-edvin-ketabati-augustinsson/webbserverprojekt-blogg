require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    slim(:home)
end

post('/login') do
    db = SQLite3::Database.new('blogg.db')
    db.results_as_hash = true
    result = db.execute("SELECT Password FROM users WHERE Username =(?)", params["name"]) 
    not_password = result[0]["Password"]
    if BCrypt::Password.new(not_password) == params["pass"]
        session[:loggedin] = true
        redirect('/welcome')
    else
        redirect('/lolno')
    end
end

get('/welcome') do
    if session[:loggedin] == true
        slim(:welcome)
    else
        redirect('/')
    end
end

post('/logout') do
    session.destroy
    redirect('/')
end

get('/register') do
    slim(:register)
end

post('/create') do
    name = params["name"]
    password = BCrypt::Password.create(params["pass"])
    db = SQLite3::Database.new('blogg.db')
    db.execute("INSERT INTO users(Username, Password) VALUES('#{name}','#{password}')")
    redirect('/')
end