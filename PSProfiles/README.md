
These profiles aren't created by default. They exist only if you create them.

The easiest way to keep track of all this is to simply open the shell, type $profile, and hit Enter. That will give you the full path that the shell is attempting to use as what I think of as the "primary" profile (it's the per-user, shell-specific profile). You can then create or modify that script and it will execute each time the shell starts.

%UserProfile%\Documents\WindowsPowerShell\Micro­soft.PowerShell_profile.ps1 This is for the current user only and only for the Microsoft.PowerShell shell.