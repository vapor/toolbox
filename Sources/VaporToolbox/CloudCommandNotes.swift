/**

 IMPLEMENTED

 // Signup
 vapor cloud signup (-firstName/-f, -lastName/-l, -email/-e, -password/-p, -organizationName/-o)

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
 vapor cloud login - Logs into Vapor Cloud
 vapor cloud signup - Creates a new account for Vapor Cloud.
 vapor cloud ssh - Use this to interact with, list, push, and delete SSH keys on Vapor Cloud
    list - lists all
    push - pushes a key
    delete - deletes a key
 envs Interact with Vapor Cloud Environments
 me Shows information about user.
 deploy Deploys a Vapory Project
 dump-token Dump token data
 
 apps Interact with Vapor Cloud Applications
 orgs - Interact with Vapor Cloud Orgs
 envs Interact with Vapor Cloud Environments
 */
