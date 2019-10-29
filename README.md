# EffDB

A record layer over FoundationDB in Elixir.

**Status** literally toxic for your data, do not use.

## Usage

### Defining a table

```elixir
defmodule MyApp.Models.User
use EffDB.Table

table("users", id: :string, email: :string)
```

### Using the table


```elixir
alias MyApp.Models.User
bozo = %User{id: UUID.uuid4(:hex), email: "me(at)tehprofessor"}
EffDB.Storage.insert(User, bozo)
```

```elixir
alias MyApp.Models.User
bozo_id = UUID.uuid4(:hex)
EffDB.Storage.get(User, user_id)
```

```elixir
alias MyApp.Models.User
EffDB.Storage.all(User)
```
