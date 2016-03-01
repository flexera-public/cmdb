# encoding: utf-8
get '/widgets' do
  headers 'Content-Type' => 'application/json; charset=utf-8'
  [200, '[]']
end
