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
    encrypted_pass = result[0]["Password"]
    if BCrypt::Password.new(encrypted_pass) == params["pass"]
        session[:loggedin] = true
        redirect('/profil')
    else
        redirect('/failed')
    end
end

get('/profil') do
    if session[:loggedin] == true
        # Hitta ett sätt att ta med användarnamn / ID till denna sidan och för att visa den + alla inlägg från denna användare. 
        # Lagra detta + alla inlägg i variabler och dunka in i Slim
        slim(:profil)
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

get('/failed') do
    slim(:login_failed)
end