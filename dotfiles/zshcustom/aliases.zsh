# Reload shell
alias reload='source ~/.zshrc'

# Kindle
alias kindle='sendgmail -t anders.janmyr@kindle.com'
alias kindlec='sendgmail -t anders.janmyr@kindle.com -s Convert'

# MySql
alias mysqlstart='sudo mysql.server start'
alias mysqlstop='sudo mysql.server stop'

# Postgres
alias pgstart='pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start'
alias pgstop='pg_ctl -D /usr/local/var/postgres stop -s -m fast'

# Other
alias less='less -FRSX'
alias h='history'

# Git
alias gap='git add -p'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git hist'
alias gpu='git pull --ff-only'
alias gpuf='git pull --ff-only'
alias gs='git status -sb'

# NE
alias dc='drush -r /Users/andersjanmyr/External_Projects/ne/web/sites/ne.se cc all'
alias ne='pushd /Users/andersjanmyr/External_Projects/ne/ne_se-profile/themes/ne_bs'

# AWS
export AWS_CREDENTIALS_FILE=/Users/andersjanmyr/.aws-credentials

# Ruby performance patches
export RUBY_HEAP_MIN_SLOTS=1000000
export RUBY_HEAP_SLOTS_INCREMENT=1000000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1
export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_HEAP_FREE_MIN=500000


