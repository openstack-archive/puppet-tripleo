# Copyright 2016 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: tripleo::ssl::cinder_config
#
# Enable SSL middleware for the cinder service's pipeline.
#

class tripleo::ssl::cinder_config {
  cinder_api_paste_ini {
    'filter:ssl_header_handler/paste.filter_factory':
      value => 'oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory';
    'pipeline:apiversions/pipeline':
      value => 'ssl_header_handler faultwrap osvolumeversionapp';
  }
}
