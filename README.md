# Synology

Synology NAS API client written in Ruby.

Full implantation of Synology API based on this documentation: https://global.download.synology.com/download/Document/Software/DeveloperGuide/Package/FileStation/All/enu/Synology_File_Station_API_Guide.pdf

## Installation

```ruby
gem 'synology'
```

And then execute:

    $ bundle install


## Usage

Have some other Synology Service exposed define endpoints in config. 
```
Synology.configure do |config|
 
  ....
  # Define your own endpoints
  # May break code with POST request...
  # Example: lib/synology/client.rb  
  config.api_endpoint = { 
     info: { api: 'SYNO.FileStation.Info', version: 2, method: 'get', http_method: 'GET' },
     # SYNO.API.Auth
     login: { api: 'SYNO.API.Auth', version: 3, method: 'login', http_method: 'GET' },
     logout: { api: 'SYNO.API.Auth', version: 1, method: 'logout', http_method: 'GET' }
    ...
  }
end
```

### Basic usages

```
Synology.configure do |config|
  config.host = 'https://finds.synology.com'
  config.username = 'admin'
  config.password = 'password'
  config.https = true
end

client = Synology::Client.new
# Login
client.login(account: client.username, passwd: client.password)

# List files in folder
client.list_folder(folder_path: '/my_folder', additional: '["real_path", "size", "owner"]')

# Upload a file
client.upload(path: '/my_folder', file: {file_name:'testing', file_content: 'Testing123'})
# Download a file body Base64.strict_encoded
client.download(path: '/my_folder/testing')

client.close

```

Authentication Methods

    client.login(account: , passwd:)# Authenticate with Synology NAS
    client.logout # End the current session

#### File and Folder Operations

List & Info

    client.list_share # List all shared folders
    client.list_folder(folder_path:, additional:) # List contents of a folder
    client.list_get_info # Get information about files/folders

Search Operations

    client.search_start(folder_path:, pattern:) # Start a search operation
    client.search_list(taskid:) # List search results
    client.search_stop(taskid:) # Stop a search operation
    client.search_clean(taskid:) # Clean up search results

Virtual Folder Operations

    client.list_all_mount_points(type:, additional:) # List mount points of virtual file systems

Favorite Management

    client.favorite_list # List favorite folders
    client.favorite_add(path:, name:) # Add folder to favorites
    client.favorite_edit(path:, name:) # Edit favorite folder
    client.favorite_delete(path:) # Remove from favorites
    client.favorite_clear_broken # Clear broken favorite links

Thumbnail Operations

    client.get_thumbnail(path:) # Get thumbnail of a file

Directory Operations

    client.dir_start(path:) # Start directory size calculation
    client.dir_status(taskid:) # Check directory size calculation status
    client.dir_stop(taskid:) # Stop directory size calculation

MD5 Operations

    client.md5_start(file_path:) # Start MD5 calculation
    client.md5_status(taskid:) # Check MD5 calculation status
    client.md5_stop(taskid:) # Stop MD5 calculation

#### File Management

Basic Operations

    client.check_permission(path:, filename:) # Check file/folder permissions
    client.upload(path:, file:{file_name:, file_content:}) # Upload files
    client.download(path:) # Download files
    client.create_folder(folder_path:, name:) # Create new folder
    client.rename(path:, name:) # Rename file/folder
    client.delete(path:) # Delete file/folder immediately

Sharing Operations

    client.sharing_get_info(id:) # Get sharing link info
    client.sharing_links_list # List all sharing links
    client.sharing_link_create(path:) # Create sharing link
    client.sharing_link_delete(id:) # Delete sharing link
    client.sharing_link_edit(id:) # Edit sharing link
    client.sharing_link_clear_invalid # Clear invalid sharing links

Asynchronous Operations

    client.copy_move_start(path:, dest_folder_path:) # Start copy/move operation
    client.copy_move_status(taskid:) # Check copy/move status
    client.copy_move_stop(taskid:) # Stop copy/move operation

Delete Operations

    client.delete_async_start(path:) # Start asynchronous delete
    client.delete_async_status(taskid:) # Check delete status
    client.delete_async_stop(taskid:) # Stop delete operation

Archive Operations

    client.extract_start(file_path:, dest_folder_path:) # Start extraction
    client.extract_status(taskid:) # Check extraction status
    client.extract_stop(taskid:) # Stop extraction
    client.extract_list(file_path:) # List archive contents
    client.compress_start(path:, dest_file_path:) # Start compression
    client.compress_status(taskid:) # Check compression status
    client.compress_stop(taskid:) # Stop compression
    client.compress_list(file_path:) # List compressed file contents

Background Tasks

    client.background_task_list # List background tasks
    client.background_task_clear_finished(taskid:) # Clear finished background tasks

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dragonwebeu/synology.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
