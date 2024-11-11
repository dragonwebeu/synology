# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'openssl'
require 'base64'

module Synology
  class Client
    API_ENDPOINT = 'webapi/entry.cgi'

    # API endpoints definition using metaprogramming
    # https://global.download.synology.com/download/Document/Software/DeveloperGuide/Package/FileStation/All/enu/Synology_File_Station_API_Guide.pdf
    API_ENDPOINTS = {
      info: { api: 'SYNO.FileStation.Info', version: 2, method: 'get', http_method: 'GET' },
      # SYNO.API.Auth
      login: { api: 'SYNO.API.Auth', version: 3, method: 'login', http_method: 'GET' },
      logout: { api: 'SYNO.API.Auth', version: 1, method: 'logout', http_method: 'GET' },
      # SYNO.FileStation.List
      list: {
        #client.list_share
        share: { api: 'SYNO.FileStation.List', version: 2, method: 'list_share', http_method: 'GET' },
        # client.list_folder(folder_path: '/my_folder', additional: '["real_path", "size", "owner"]')
        folder: { api: 'SYNO.FileStation.List', version: 2, method: 'list', http_method: 'GET' },
        get_info: { api: 'SYNO.FileStation.List', version: 2, method: 'getinfo', http_method: 'GET' }
      },
      # SYNO.FileStation.Search
      search: {
          # client.search_start(folder_path: '/my_folder', pattern: 'test')
          start: { api: 'SYNO.FileStation.Search', version: 2, method: 'start', http_method: 'GET' },
          # client.search_list(taskid: '173126991043E83CB8')
          list: { api: 'SYNO.FileStation.Search', version: 2, method: 'list', http_method: 'GET' },
          # client.search_stop(taskid: '173126991043E83CB8')
          stop: { api: 'SYNO.FileStation.Search', version: 2, method: 'stop', http_method: 'GET' },
          # client.search_clean(taskid: '173126991043E83CB8')
          clean: { api: 'SYNO.FileStation.Search', version: 2, method: 'clean', http_method: 'GET' }
      },
      # SYNO.FileStation.VirtualFolder
      # List all mount point folders of virtual file system, e.g., CIFS or ISO
      # client.list_all_mount_points(type: 'cifs', additional: '["real_path","owner","time","perm","mount_point_type","volume_status"]')
      list_all_mount_points: { api: 'SYNO.FileStation.VirtualFolder', version: 2, method: 'list', http_method: 'GET' },
      favorite: {
          # client.favorite_list
          list: { api: 'SYNO.FileStation.Favorite', version: 2, method: 'list', http_method: 'GET' },
          # client.favorite_add(path: '/my_folder', name: 'Henry')
          add: { api: 'SYNO.FileStation.Favorite', version: 2, method: 'add', http_method: 'GET' },
          # client.favorite_edit(path: '/my_folder', name: 'Henry2')
          edit: { api: 'SYNO.FileStation.Favorite', version: 2, method: 'add', http_method: 'GET' },
          # client.favorite_delete(path: '/my_folder')
          delete: { api: 'SYNO.FileStation.Favorite', version: 2, method: 'delete', http_method: 'GET' },
          # client.favorite_clear_broken
          clear_broken: { api: 'SYNO.FileStation.Favorite', version: 2, method: 'clear_broken', http_method: 'GET' }
      },
      # SYNO.FileStation.Thumb
      # Get a thumbnail of a file.
      # client.get_thumbnail(path:'/my_folder')
      get_thumbnail: { api: 'SYNO.FileStation.Thumb', version: 2, method: 'get', http_method: 'GET' },
      # SYNO.FileStation.DirSize
      dir: {
          # client.dir_start(path: '/my_folder')
          start: { api: 'SYNO.FileStation.DirSize', version: 2, method: 'start', http_method: 'GET' },
          # client.dir_status(taskid: '1731273375F0B260B3')
          status: { api: 'SYNO.FileStation.DirSize', version: 2, method: 'status', http_method: 'GET' },
          # client.dir_stop(taskid: '1731273375F0B260B3')
          stop: { api: 'SYNO.FileStation.DirSize', version: 2, method: 'status', http_method: 'GET' }
      },
      # SYNO.FileStation.MD5
      md5: {
          # client.md5_start(file_path: '/my_folder/some_move.mov')
          start: { api: 'SYNO.FileStation.MD5', version: 2, method: 'start', http_method: 'GET' },
          # client.md5_status(taskid: '1731274183A791CF18')
          status: { api: 'SYNO.FileStation.MD5', version: 2, method: 'status', http_method: 'GET' },
          # client.md5_stop(taskid: '1731274183A791CF18')
          stop: { api: 'SYNO.FileStation.MD5', version: 2, method: 'stop', http_method: 'GET' }
      },
      # SYNO.FileStation.CheckPermission
      # client.check_permission(path: '', filename: '')
      check_permission: { api: 'SYNO.FileStation.CheckPermission', version: 3, method: 'write', http_method: 'GET' },
      #SYNO.FileStation.Upload
      # upload = client.upload(path: '/my_folder', file: {file_name:'testing', file_content: 'Testing123'})
      upload: { api: 'SYNO.FileStation.Upload', version: 2, method: 'upload', http_method: 'POST' }, # Only POST method in the API
      # download_file = client.download(path: '/my_folder/testing')
      download: { api: 'SYNO.FileStation.Download', version: 2, method: 'download', http_method: 'GET' },
      # SYNO.FileStation.Sharing
      sharing: {
          # sharing_link = client.sharing_get_info(id: '12345')
          get_info: { api: 'SYNO.FileStation.Sharing', version: 3, method: 'getinfo', http_method: 'GET' },
          # client.sharing_links_list
          links_list: { api: 'SYNO.FileStation.Sharing', version: 3, method: 'list', http_method: 'GET' },
          # client.sharing_link_create(path: '/my_folder')
          link_create: { api: 'SYNO.FileStation.Sharing', version: 3, method: 'create', http_method: 'GET' },
          # client.sharing_link_delete(id: '12345')
          link_delete: { api: 'SYNO.FileStation.Sharing', version: 3, method: 'delete', http_method: 'GET' },
          # # client.sharing_link_edit(id: '12345')
          link_edit: { api: 'SYNO.FileStation.Sharing', version: 3, method: 'edit', http_method: 'GET' },
          # client.sharing_link_clear_invalid
          link_clear_invalid: { api: 'SYNO.FileStation.Sharing', version: 3, method: 'clear_invalid', http_method: 'GET' }
      },
      # SYNO.FileStation.CreateFolder
      # client.create_folder(folder_path: '/my_folder', name: 'testing1')
      create_folder: { api: 'SYNO.FileStation.CreateFolder', version: 2, method: 'create', http_method: 'GET' },
      # SYNO.FileStation.Rename
      # client.rename(path: '/my_folder/Testing1', name: 'Testing2')
      rename: { api: 'SYNO.FileStation.Rename', version: 2, method: 'rename', http_method: 'GET' },
      # SYNO.FileStation.CopyMove
      copy_move: {
          # client.copy_move_start(path: '/my_folder/testing', dest_folder_path: '/my_folder/Testing2')
          start: { api: 'SYNO.FileStation.CopyMove', version: 3, method: 'start', http_method: 'GET' },
          # client.copy_move_status(taskid: 'FileStation_51D00B7912CDE0B0')
          status: { api: 'SYNO.FileStation.CopyMove', version: 3, method: 'status', http_method: 'GET' },
          # client.copy_move_stop(taskid: 'FileStation_51D00B7912CDE0B0')
          stop: { api: 'SYNO.FileStation.CopyMove', version: 3, method: 'stop', http_method: 'GET' },
      },
      # SYNO.FileStation.Delete
      #
      delete_async: {
          # client.delete_async_start(path: '/my_folder/testing')
          start: { api: 'SYNO.FileStation.Delete', version: 2, method: 'start', http_method: 'GET' },
          # client.delete_async_status(taskid: 'FileStation_51CEC9C979340E5A')
          status: { api: 'SYNO.FileStation.Delete', version: 2, method: 'status', http_method: 'GET' },
          # client.delete_async_stop(taskid: 'FileStation_51CEC9C979340E5A')
          stop: { api: 'SYNO.FileStation.Delete', version: 2, method: 'stop', http_method: 'GET' }
      },
      # client.delete(path: '/my_folder/testing')
      delete: { api: 'SYNO.FileStation.Delete', version: 2, method: 'delete', http_method: 'GET' },
      # SYNO.FileStation.Extract
      extract: {
        # client.extract_start(file_path: '/my_folder/testing.zip', dest_folder_path: '/my_folder')
        start: { api: 'SYNO.FileStation.Extract', version: 2, method: 'start', http_method: 'GET' },
        # client.extract_status(taskid: 'FileStation_51CBB59C68EFE6A3')
        status: { api: 'SYNO.FileStation.Extract', version: 2, method: 'status', http_method: 'GET' },
        # client.extract_stop(taskid: 'FileStation_51CBB59C68EFE6A3')
        stop: { api: 'SYNO.FileStation.Extract', version: 2, method: 'stop', http_method: 'GET' },
        # client.extract_list(file_path: '/my_folder/testing.zip')
        list: { api: 'SYNO.FileStation.Extract', version: 2, method: 'list', http_method: 'GET' }
      },
      #SYNO.FileStation.Compress
      compress: {
          # client.compress_start(path: '/my_folder/testing', dest_file_path: '/my_folder')
          start: { api: 'SYNO.FileStation.Compress', version: 3, method: 'start', http_method: 'GET' },
          # client.compress_status(taskid: 'FileStation_51CBB25CC31961FD')
          status: { api: 'SYNO.FileStation.Compress', version: 3, method: 'status', http_method: 'GET' },
          # client.compress_stop(taskid: 'FileStation_51CBB25CC31961FD')
          stop: { api: 'SYNO.FileStation.Compress', version: 3, method: 'stop', http_method: 'GET' },
          # client.compress_list(file_path: '/my_folder/testing.zip')
          list: { api: 'SYNO.FileStation.Compress', version: 3, method: 'status', http_method: 'GET' }
      },
      background_task: {
        # client.background_task_list
        list: { api: 'SYNO.FileStation.BackgroundTask', version: 3, method: 'list', http_method: 'GET' },
        # client.background_task_clear_finished(taskid: 'FileStation_51D530978633C014')
        clear_finished: { api: 'SYNO.FileStation.BackgroundTask', version: 3, method: 'clear_finished', http_method: 'GET' }
      }
    }


    attr_reader :username, :password
    attr_accessor :sid

    def initialize
      @config = Synology.configuration
      @username = @config.username
      @password = @config.password
      @sid = nil
      @api_endpoint = @config.api_endpoint || API_ENDPOINT
      # API_ENDPOINTS
      @api_endpoints = @config.api_endpoints || API_ENDPOINTS
      generate_api_methods
    end

    private

    def generate_api_methods
      @api_endpoints.each do |method_name, endpoints|
        unless endpoints.dig(:api)
          endpoints.each do |method_name2, endpoints2|
            nested_method_name = "#{method_name}_#{method_name2}"
            define_singleton_method(nested_method_name) do |params = {}|
              execute_request(endpoints2, params)
            end
          end
        else
          define_singleton_method(method_name) do |params = {}|
            execute_request(endpoints, params)
          end
        end
      end
    end

    def execute_request(endpoint_info, params)
      uri = URI("#{@config.base_url}/#{API_ENDPOINT}/#{endpoint_info[:path]}")
      request_params = {
          api: endpoint_info[:api],
          version: endpoint_info[:version],
          method: endpoint_info[:method]
      }.merge(params)

      # Todo: cleanup or get sid other way
      request_params[:_sid] = @sid if @sid && @use_cookies

      response = make_request(uri, request_params, endpoint_info[:http_method])
      handle_response(response, request_params)
    end

    def make_request(uri, params, request_type='GET')
      # Todo: find better solution for this
      if params[:method] == 'upload'
        file = params[:file]
        params.delete(:file)

        if file[:file_content].nil?
          raise "File content can't be nil!"
        end
      end
      uri.query = URI.encode_www_form(params)
      https = Net::HTTP.new(uri.host, uri.port)
      if @config.https
        https.use_ssl = true
        # https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Get.new(uri) if request_type.upcase == 'GET'
      if request_type.upcase == 'POST'
        request = Net::HTTP::Post.new(uri)
        boundary = rand(100000)
        request.body = upload_body(params, file, boundary).join
        request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      end
      unless @sid.nil?
        request['Cookie'] = "#{@sid}"
      end
      response = https.request(request)
      if response.header['set-cookie']
        @sid = response.header['set-cookie']
      end
      response
    end

    def handle_response(response, params)
      # Todo: Cleanup this later and find better solution
      if params[:method] == 'download' && response.code == '200'
        response.body = {body: Base64.strict_encode64(response.body), content_type: response['Content-Type'], success: true}.to_json
      end
      if response.is_a?(Net::HTTPSuccess)
        return parse_json(response.body, params)
      end

      raise Error, "HTTP Request failed: #{response.code} #{response.message}"
    end

    def parse_json(body, params)
      json_body = JSON.parse(body)
      # Todo: Change is so it runnable by config settings
      unless json_body['error'].nil?
        Synology::Error.raise_error(json_body['error']['code'], params[:api])
      end
      json_body
    rescue JSON::ParserError
      raise Error, "Invalid JSON response"
    end

    def upload_body(params, file, boundary)
      post_body = []
      post_body << upload_params_to_form_data(params, boundary)
      post_body << "--#{boundary}\r\n"
      post_body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{file[:file_name]}\"\r\n"
      post_body << "Content-Type: application/octet-stream\r\n\r\n"
      post_body << file[:file_content]
      post_body << "\r\n--#{boundary}--\r\n"
      post_body
    end

    def upload_params_to_form_data(params, boundary)
      params_body = []
      params.each do |param|
        params_body << "--#{boundary}\r\n"
        params_body << "Content-Disposition: form-data; name=\"#{param[0].to_s}\"\r\n\r\n"
        params_body << "#{param[1].to_s}\r\n"
      end
      params_body
    end


  end
end
