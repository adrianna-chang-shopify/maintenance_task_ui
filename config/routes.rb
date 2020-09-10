MaintenanceTaskUi::Engine.routes.draw do
  get '/tasks', to: 'tasks#show'
  post '/tasks/:task', to: 'tasks#enqueue', as: 'enqueue_task'
  get '/tasks/:task_id', to: 'tasks#detail', as: 'detail_task'

  root to: 'tasks#show'
end
