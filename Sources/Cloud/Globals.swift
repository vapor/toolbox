#if Xcode || DEBUG
    let cloudURL = "http://0.0.0.0:8100"
#else
    //let cloudURL = "http://0.0.0.0:8100"
    let cloudURL = "https://api.vapor.cloud"
#endif
