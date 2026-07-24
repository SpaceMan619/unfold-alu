# C# Exceptions

Practice exercises for handling exceptions in C#.

Each numbered directory contains one SDK-style .NET project and the required
class implementation:

- `0-safe_list_print`: safely print a requested number of list elements.
- `1-divide_print`: divide two integers and report the result in `finally`.
- `2-divide_lists`: safely divide corresponding elements from two lists.
- `3-throw_exception`: throw a basic `Exception`.
- `4-throw_exception_msg`: throw an `Exception` with a supplied message.

The projects intentionally omit namespaces and entry points so the classes can
be used directly by exercise harnesses.

Build all task projects from this directory with:

```bash
for project in */*.csproj; do dotnet build "$project"; done
```

Generated `bin/` and `obj/` directories are ignored by the repository.
