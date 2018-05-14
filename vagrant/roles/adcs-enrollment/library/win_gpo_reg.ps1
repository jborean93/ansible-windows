#!powershell

# Copyright: (c) 2018, Jordan Borean
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false

$gpo = Get-AnsibleParam -obj $params -name "gpo" -type "str" -failifempty $true
$path = Get-AnsibleParam -obj $params -name "path" -type "str" -failifempty $true
$name = Get-AnsibleParam -obj $params -name "name" -type "str" -default ""
$value = Get-AnsibleParam -obj $params -name "value" -type "str"
$type = Get-AnsibleParam -obj $params -name "type" -type "str" -default "String" -ValidateSet "String", "ExpandString", "Binary", "DWord", "MultiString", "QWord"

$result = @{
    changed = $false
}

$existing_value = Get-GPRegistryValue -Name $gpo -Key $path -ValueName $name
$before_value = $existing_value.Value
$before_type = $existing_value.Type.ToString()

# it seems like strings values returned with Get-GPRegistryValue have a null
# terminator on the end, Set-GPRegistryValue does not require this and takes
# the string literally so we will lop it off before comparing with our value
if ($before_type -in @("String", "ExpandString")) {
    if ($before_value.EndsWith([char]0x0000)) {
        $before_value = $before_value.Substring(0, $before_value.Length - 1)
    }
}

$result.before_value = $before_value
$result.before_type = $before_type
if (($before_value -ne $value) -or ($before_type -ne $type)) {
    Set-GPRegistryValue -Name $gpo -Key $path -ValueName $name -Value $value -Type $type -WhatIf:$check_mode > $null
    $result.changed = $true
}

Exit-Json -obj $result
