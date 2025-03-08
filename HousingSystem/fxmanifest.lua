fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Coastal World RP'
description 'House Purchase System'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}
