fx_version 'cerulean'
game 'gta5'
author 'Leah#001, Modified by Atu#7878'
version '1.0.0'
lua54 'yes'

shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'client/client.lua',
	'client/menu.lua'
}

server_scripts {
	'server/server.lua'
}

dependencies {
	'bixbi_core',
	'ox_inventory'
}

exports {
	"TerritoryInfoMenu"
}
