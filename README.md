# GitHub/Gist Utilities

This utilities is based on GitHub GraphQL API v4.

* ghlist.rb   : List GitHub Repositories
* gistlist.rb : List Gist Repositories

## Configuration

Get a personal access token and write it into `~/.config/ghutils/config.json`.
```
{
  "token": "personal access token"
}
```

The following permissions are enabled access to private repositories and secret gists.
- [x] security_events : Read and write security events 
- [x] gist : Create gists 

Change `config.json` permission to 500:
```
chmod 500 ~/.config/ghutils/config.json
```

# Relations

GitHub REST API v3 based utilities.
* [gistlist.rb](https://gist.github.com/kou1okada/6680cb2aedb5af890f44)
