Config = {}

Config.AllowedJobs = {
    mechanic = true,
    sadot = true,
    police = true
}

Config.TowVehicles = {
    rollback = { 'flatbed', 'flatbed4', 'gtow' },
    boom = { 'wrecker', 'freightliner' },
    trailers = { 'trailersmall', 'trailer', 'cartrailer' }
}

Config.AttachOffset = {
    rollback = vec3(0.0, -5.0, 1.0),
    boom = vec3(0.0, -3.5, 1.2),
    trailer = vec3(0.0, -6.0, 1.0)
}

Config.BoomBones = {
    arm = 'boom',
    hook = 'hook'
}