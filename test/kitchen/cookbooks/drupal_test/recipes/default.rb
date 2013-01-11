node.set['mysql']['server_debian_password'] = "ilikerandompasswords"
node.set['mysql']['server_root_password']   = "ilikerandompasswords"
node.set['mysql']['server_repl_password']   = "ilikerandompasswords"

include_recipe "mysql::server"
