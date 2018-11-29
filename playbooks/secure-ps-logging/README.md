# Secure PowerShell Event Logging

Newer versions of PowerShell have added more indepth event logging to
PowerShell and the commands that are run in each PowerShell instance. This
playbook is designed to harden this source of information so only privileged
users have the ability to read the logs.

# Purpose

This playbook will do two things;

* Restrict the read access to the `Microsoft-Windows-PowerShell/Operational` event log
* Clear out any existing entries in the event log

The main purpose of both these actions is to restrict the users who can view
the PowerShell operational logs as currently any user can view them. These logs
can contain very granular, and sometimes sensitive, information around what
PowerShell has executed. This is why it is important to restrict the accounts
that have access to the operational logs so that non-privileged accounts cannot
access info that only privileged accounts should have.

## Restricting Access

This step will restrict the access to the
`Microsoft-Windows-PowerShell/Operational` event log to the following users;

* `SYSTEM`: Will have [STANDARD_RIGHTS_REQUIRED](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/standard-access-rights), `Read`, and `Clear` rights
* `BUILTIN\Administrators`: Will have `Read` and `Clear` rights
* `EVENT_LOG_READERS`: Will only have `Read` rights

This is the same restrictions as the `Security` event log and means that
standard users will be unable to access these logs without elevating their
privileges.

Changing these permissions does not mean it will disable the logging for
PowerShell but rather it just restricts who can read the event logs to more
privileged users.

## Clearing Entries

The second task just clears the existing operational log to remove any
potential sensitive information that is already in the logs themselves.
