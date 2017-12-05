# Copyright 2017 Camptocamp SA.
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
#
# == Definition: tripleo::haproxy::userlist
#
# Configure an HAProxy userlist. It wrapps haproxy::userlist definition.
#
# [*groups*]
#  List of groups
#
# [*users*]
#  List of users
#
# == Example
# ::tripleo::haproxy::userlist {'starwars':
#   groups => [
#     'aldebaran users leia,luke',
#     'deathstar users anakin,sith',
#   ],
#   users => [
#       'leia insecure-password sister',
#       'luke insecure-password jedi',
#       'anakin insecure-password darthvador',
#       'sith password $5$h9LsKUOeCr$UlD62CNEpuZQkGYdBoiFJLsM6TlXluRLBlhEnpjDdaC', # mkpasswd -m sha-256 darkSideOfTheForce
#   ]
# }
#
# Please refer to the following HAProxy documentation for more options:
# http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4-user
# http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4-group
#
#
define tripleo::haproxy::userlist(
  Optional[Array] $groups = [],
  Optional[Array] $users  = [],
) {

  ::haproxy::userlist {$name:
    users  => $users,
    groups => $groups,
  }
}
