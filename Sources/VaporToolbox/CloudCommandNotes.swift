/**

 IMPLEMENTED

 // Signup
 vapor cloud signup (-first/-f, -last/-l, -email/-e, -password/-p, -org/-o)

 // Login
 vapor cloud login (-email, -password)

 // SSH
 vapor cloud ssh push (-name, -path, -key)
 vapor cloud ssh list (-long)
 vapor cloud ssh delete

 // Deploy
 vapor cloud 
 vapor cloud deploy
 // detect application
 */

/**

 Deploy command
 - check git status is clean
 - check branch is expected branch
 - push git
 - call deploy api
 - on return, connect properly to websocket
 - show logs
 **/


/**
 // USER COMMANDS
 me - Shows information about user.
 login (-email, -password) - Logs into Vapor Cloud
 signup (-first/-f, -last/-l, -email/-e, -password/-p, -org/-o) - Creates a new account for Vapor Cloud.

 // SSH
 ssh - Use this to interact with, list, push, and delete SSH keys on Vapor Cloud
 ssh list - lists all
 ssh push (-name/-n, [-path/-p || -key/-k]) - pushes a key
 ssh delete - deletes a key

 // DEPLOY
 deploy - Deploys a Vapory Project

 // LISTS
 apps - Interact with Vapor Cloud Apps
 apps list - List all Vapor Cloud Apps
 orgs - Interact with Vapor Cloud Orgs
 orgs list - List all Vapor Cloud Orgs
 envs - Interact with Vapor Cloud Envs
 envs list - List all Vapor Cloud Envs

 // DEV
 dump-token - Dump token data
 */
