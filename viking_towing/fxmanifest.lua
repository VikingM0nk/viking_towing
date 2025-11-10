fx_version 'cerulean'
game 'gta5'

description 'QBCore Tow Script with Rollback, Boom, Winch, Trailer, and UI'
author 'VikingM0nk'

shared_script { 'shared/config.lua',
'shared/flatbed_multi.lua' }

stream { 'def_flatbed3_props.ytyp', 'inm_flatbed_base.ydr' }
client_scripts {
    'client/main.lua',
    'client/rollback.lua',
    'client/boom.lua',
    'client/ui.lua',
    'client/tow_targets.lua',
    'client/trailer.lua'
}

server_script 'server/main.lua'

dependencies {
    'ox_target',
    'ox_lib',
    'qb-core'
}