/// Configure a #(fluentdb) database
services.register { c -> #(fluentdb)Database in
    #if(fluentdb == 'SQLite') {
    return try #(fluentdb)Database(storage: .memory)
    } ##else {
    return try #(fluentdb)Database(config: c.make())<% } %>
    }
}

/// Register the configured #(fluentdb) database to the database config.
services.register { c -> DatabasesConfig in
    var databases = DatabasesConfig()
    try databases.add(database: c.make(#(fluentdb)Database.self), as: .#(fluentdbshort))
    return databases
}

/// Configure migrations
services.register { c -> MigrationConfig in
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .#(fluentdbshort))
    return migrations
}
