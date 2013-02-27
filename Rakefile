task :update do
    sh "git pull"
    sh "touch tmp/restart.txt"
end

task :restart do
    sh "touch tmp/restart.txt"
end

task :default => [:update]
