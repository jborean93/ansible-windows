#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2018, Jordan Borean
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_gpo_reg
short_description: Configured a registry-based policy in a GPO.
description:
- This module will configure a registry based policy under either Computer
  COnfiguration or User Configuration in a Group Policy Object (GPO).
- This uses the *-GPRegistryValue cmdlets and are restricted to what they can
  do, see U(https://docs.microsoft.com/en-us/powershell/module/grouppolicy/get-gpregistryvalue?view=win10-ps)
  for more details.
options:
  gpo:
    description:
    - The GPO that contains the registry policy to configure.
    required: yes
  path:
    description:
    - The registry path starting with either C(HKLM\) or C(HKCU\) to the
      registry key to configure.
    required: yes
  name:
    description:
    - The name of the registry property to set the value for.
    - If omitted then this will be the default value of the key specified by
      I(path).
  value:
    description:
    - The value of the registry property to set.
    - Not specifying this option will set the registry property to null.
  type:
    description:
    - The type of value to set.
    - If the type does not match the existing type, then a change will occur
      with the new type set.
    choices:
    - String
    - ExpandString
    - Binary
    - DWord
    - MultiString
    - QWord
    default: String
author:
- Jordan Borean (@jborean93)
'''

EXAMPLES = r'''
- name: set the value of the default registry property on the path
  win_gpo_reg:
    gpo: test-gpo
    path: HKLM\Software\Policies\Microsoft\Cryptography\PolicyServers
    value: '{3ae4929f-4e0f-4a31-bd53-8fc5a98c2390}'
    type: String

- name: set the value of a named registry property on the path
  win_gpo_reg:
    gpo: test-gpo
    path: HKLM\Software\Policies\Microsoft\Cryptography\PolicyServers\37c9dc30f207f27f61a2f7c3aed598a6e2920b54
    name: PolicyID
    value: '{3ae4929f-4e0f-4a31-bd53-8fc5a98c2390}'
    type: String
'''

RETURN = r'''
before_value:
  description: The value that was previously set
  returned: always
  type: str
  sample: original value
before_type:
  description: The type of the value that was previously set
  returned: always
  type: str
  sample: String
'''

