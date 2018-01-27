<#  
.SYNOPSIS
   PowerShell Template Script
.DESCRIPTION
.NOTES
   - Treat the script just like a function
      - All values that the script needs should be in the param() list
      - Use default values
      - Use a second parameterset for input file as an alternative to separate parameters
      - Use "undefined" for required parameter values as an alternative to the Mandatory attribute so that there is no interactive prompting
      - For scripts called from MDT, use MDT environment values to override the default parameter values
      - Print out success/failure string and return success/failure code
   - Use transcipt logging instead of a special function, however it does not catch Write-Host output, but Write-Host is bad anyways
      - Use "xxxx" | Out-Default for normal messages (white)
      - Use $script:VerbosePreference = "Continue" and Write-Verbose for trace/progress messages (yellow)
      - Use $script:DebugPreference = "Continue" and Write-Debug for "debug" messages (yellow)
      - Use Write-Warning for warning messages (yellow)
      - Use Write-Error for error messages (red)
   - Use robust error handling
      - Use the advanced function paradigm so that -ErrorAction works on the function
      - Add -ErrorAction Stop on all cmdlet and function calls so that they throw on an error
      - Wrap "main" in a try/catch
   - Use full cmdlet and parameter names, i.e. do not abbreviate, Format-Table instead of ft
   ! Function return values are tricky; Powershell returns all uncaptured output, the return statement value is not the only value "returned"
#>

[CmdLetBinding(DefaultParameterSetName="params")]
param
(
   [Parameter(ParameterSetName="params")]
   [string]$ParamA = "paramavalue",
   [Parameter(ParameterSetName="params")]
   [string]$ParamB = "parambvalue",
   [Parameter(ParameterSetName="datafile", ValueFromPipeline=$true)]
   [string]$InputFile = "template.json",
   [string]$Now = (Get-Date -Format "yyyyMMddHHmm"),
   [string]$Self = "undefined",
   [string]$Root = "undefined"
)
$Self = $script:MyInvocation.MyCommand.Path
$Root = Split-Path -Path $Self -Parent

# include shared functions
#. $PSScriptRoot\SharedFunctions.ps1

# local functions
function LocalFunction
{
   [CmdLetBinding()]
   param
   (
      [string]$Name = "explorer"
   )

   begin
   {
      Write-Verbose "$($MyInvocation.MyCommand) Begin"
      $Parameters = (Get-Command -Name $MyInvocation.InvocationName).Parameters.Keys | Sort-Object | % { Get-Variable -Name $_ -ErrorAction SilentlyContinue }
      $Parameters | Format-Table -AutoSize -Wrap | Out-Default
      $Undefined = $Parameters | ? { $_.Value -eq "undefined" }
      if ($Undefined -ne $null) { throw "The following parameters where undefined: $($Undefined | % Name )" }
   }
   process
   {
      # get processes
      "Getting $Name processes..." | Out-Default
      Get-Process -Name $Name
      return "Found"
   }
   end
   {
      Write-Verbose "$($MyInvocation.MyCommand) End"
   }
}


function Execute-SQLQuery()
{
   [CmdLetBinding()]
   param
   (
      [string]$Server = "myserver.domain.local",
      [string]$Port = "1111",
      [string]$Database = "mydatabase",
      [string]$User = "myusername",
      [string]$Password = "myuserpassword",
      [string]$Query = "SELECT * FROM mytable"
   )

   begin
   {
      Write-Verbose "$($MyInvocation.MyCommand) Begin"
      $Parameters = (Get-Command -Name $MyInvocation.InvocationName).Parameters.Keys | Sort-Object | % { Get-Variable -Name $_ -ErrorAction SilentlyContinue }
      $Parameters | Format-Table -AutoSize -Wrap | Out-Default
      $Undefined = $Parameters | ? { $_.Value -eq "undefined" }
      if ($Undefined -ne $null) { throw "The following parameters where undefined: $($Undefined | % Name )" }

      $Connnection = $null
   }
   process
   {
      # 1. connect   (test postgres database requires psqlodbc_09_06_0200-x64.zip)
      $Connection = New-Object System.Data.Odbc.OdbcConnection
      $Connection.ConnectionString = "Driver={PostgreSQL Unicode(x64)};Server=$Server;Port=$Port;Database=$Database;Uid=$User;Pwd=$Password;"
      $Connection.Open()

      # 2. query
      $Command = New-Object System.Data.Odbc.OdbcCommand($Query,$Connection)
      $DataSet = New-Object System.Data.DataSet
      $Adapter = New-Object System.Data.Odbc.OdbcDataAdapter($Command)
      $Adapter.SelectCommand.CommandTimeout = 300
      $Adapter.Fill($DataSet) | Out-Null
      $Connection.Close()
      $Connection = $null
      if ($DataSet.Tables.Count -eq 0 -or $DataSet.Tables[0].Rows.Count -eq 0) { throw "Query returned no results" }

      # 3. convert DataRow(s) to custom object(s)
      $Records = @()
      foreach ($Row in $DataSet.Tables[0].Rows)
      {
         $Properties = @{}
         $Row | Get-Member -MemberType Property | % { $Properties.($_.Name) = $Row.($_.Name) }
         $Records += New-Object -TypeName PSObject -Property $Properties
      }
      return $Records
   }
   end
   {
      if ($Connection -ne $null) { $Connection.Close() }

      Write-Verbose "$($MyInvocation.MyCommand) End"
   }
}


function Execute-Process()
{
   [CmdLetBinding()]
   param
   (
      [string]$Command = "Undefined",
      [string]$Arguments
   )

   begin
   {
      Write-Verbose "$($MyInvocation.MyCommand) Begin"
      $Parameters = (Get-Command -Name $MyInvocation.InvocationName).Parameters.Keys | Sort-Object | % { Get-Variable -Name $_ -ErrorAction SilentlyContinue }
      $Parameters | Format-Table -AutoSize -Wrap | Out-Default
      $Undefined = $Parameters | ? { $_.Value -eq "undefined" }
      if ($Undefined -ne $null) { throw "The following parameters where undefined: $($Undefined | % Name )" }
   }
   process
   {
      $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
      $ProcessInfo.FileName = $Command
      $ProcessInfo.RedirectStandardError = $true
      $ProcessInfo.RedirectStandardOutput = $true
      $ProcessInfo.UseShellExecute = $false
      $ProcessInfo.Arguments = $Arguments
      $ProcessInfo.WorkingDirectory = "C:\"
      $Process = New-Object System.Diagnostics.Process
      $Process.StartInfo = $ProcessInfo
      $Process.Start() | Out-Null
      $Process.WaitForExit()
      $Result = $Process.ExitCode
      $StdOut = $Process.StandardOutput.ReadToEnd()
      $StdErr = $Process.StandardError.ReadToEnd()
      $StdOut | Out-Default
      $StdErr | Out-Default
      # for processes that don't return a useful exit code, could parse stdout and calculate an exit code, e.g. InstallShield
      return $Result
   }
   end
   {
      Write-Verbose "$($MyInvocation.MyCommand) End"
   }
}


try
{
   # start logging
   $script:DebugPreference = "Continue"     # manual override
   $script:VerbosePreference = "Continue"   # manual override
   Start-Transcript -Path ($Self + "." + $Now + ".log")

   Write-Verbose "STARTING"
   # convert relative paths into full paths
   if (-not [System.IO.Path]::IsPathRooted($InputFile)) { $InputFile = Join-Path -Path $PSScriptRoot -Childpath $InputFile }
   # display and validate parameters
   $Parameters = (Get-Command -Name ".\$($MyInvocation.MyCommand)").Parameters.Keys | Sort-Object | % { Get-Variable -Name $_ -ErrorAction SilentlyContinue } # do it this way for right-click initiation support
   $Parameters | Format-Table -AutoSize -Wrap | Out-Default
   $Undefined = $Parameters | ? { $_.Value -eq "undefined" }
   if ($Undefined -ne $null) { throw "The following parameters where undefined: $($Undefined | % Name )" }
   " " | Out-Default

   Write-Verbose "Parsing input..."
   $Data = @{}
   switch ($PsCmdlet.ParameterSetName)
   {
      # add parameters to the hashtable
      "params" 
      {
         $Data.Add("ParamA", $ParamA)
         $Data.Add("ParamB", $ParamB)
      }
      # add json key-value pair to the hashtable
      "datafile"
      {
         $json = Get-Content -Path $InputFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
         $json | Get-Member -MemberType NoteProperty | % { $Data.Add($_.name,$json."$($_.name)") }
      }
   }
   try
   {
      # override hash table values with MDT values
      $mdt= New-Object -ComObject Microsoft.SMS.TSEnvironment
      $Data.ParamA = $mdt.Value("ParamA")
      $Data.ParamB = $mdt.Value("ParamB")
   }
   catch
   {
       #Write-Warning "MDT environment does not exist"
   }
   $Data | Out-Default
   " " | Out-Default


   ### SQL
   Write-Verbose "Testing SQL..."
   #$Records = Execute-SQLQuery -ErrorAction Stop
   #"SQL Records:" | Out-Default
   #$Records | Format-Table
   " " | Out-Default


   ### Remoting https://www.howtogeek.com/138624/geek-school-learn-to-use-remoting-in-powershell/ remote machine: Enable-PSRemoting -Force, local  machine: Set-Item wsman:\localhost\Client\TrustedHosts -value 10.21.84.240
   Write-Verbose "Testing remote..."
   #$ComputerName = "10.10.10.10"
   #$UserName = "myusername"
   #$UserPassword = "myuserpassword"
   #$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $UserName, (ConvertTo-SecureString -AsPlainText $UserPassword -Force)
   #$Script = {Write-Output "TEST" | Out-File "c:\test.txt"}
   #$SessionOption = New-PSSessionOption -ProxyAccessType NoProxyServer
   #$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -SessionOption $SessionOption
   #$Job = Invoke-Command -Session $Session -ScriptBlock $Script
   #$Job | Out-Default
   #Remove-PSSession -Session $Session
   " " | Out-Default


   ### Jobs https://www.howtogeek.com/138856/geek-school-learn-how-to-use-jobs-in-powershell/


   ### Process Handling
   Write-Verbose "Testing process handling..."
   Write-Verbose "A. direct call"                 # see normal program stdout and stderr output
   #&"$PSScriptRoot\returncode.exe" "5"
   #$Result = $LastExitCode
   Write-Verbose "B. start-process"               # see no output
   #$Process = Start-Process -FilePath "$PSScriptRoot\returncode.exe" -ArgumentList "5" -WorkingDirectory $PSScriptRoot -Verb Open -WindowStyle Hidden -PassThru
   #Wait-Process -InputObject $Process
   #$Result = $Process.ExitCode
   Write-Verbose "C. system.diagnostic.process"   # see stdout and stderr in the order the function outputs them
   #$Result = (Execute-Process "$PSScriptRoot\returncode.exe" "5" -ErrorAction Stop)[-1]
   "Result = $Result" | Out-Default
   " " | Out-Default


   ### Error handling demonstration with default $script:ErrorActionPreference = "Continue"
   Write-Verbose "Testing error handling..."
   # 1. cmdlet
   Write-Verbose "Cmdlet Test"
   #Get-Process -Name "explorer"                   # = succeeds
   #Get-Process -Name "foobar"                     # = error message, continues on
   #Get-Process -Name "foobar" -ErrorAction Stop   # = goes to catch
   " " | Out-Default

   # 2. advanced function
   Write-Verbose "Function Test"
   #$Result = (LocalFunction)[-1]                                    # = succeeds, result = "Found"
   #$Result = (LocalFunction -Name "foobar")[-1]                     # = error message, continues on, result = "d"
   #$Result = (LocalFunction -Name "foobar" -ErrorAction Stop)[-1]   # = goes to catch
   "Result = $Result" | Out-Default
   " " | Out-Default

   # 3. native command
   Write-Verbose "Command Test"
   #&"net" user 2>&1                                  # = succeeds
   #&"net" user foobar 2>&1                           # = error message, continues on
   #&"net" user foobar 2>&1; if (-not $?) { throw }   # = error message, goes to catch; use "throw" with no message
   " " | Out-Default

   # 4. custom .exe
   Write-Verbose "Exe Test"
   #&"$PSScriptRoot\returncode.exe" 0                                                                   # = succeeds
   #&"$PSScriptRoot\returncode.exe" 5                                                                   # = continues on
   #&"$PSScriptRoot\returncode.exe" 5; if (-not $?) { throw "returncode.exe failed [$LastExitCode]" }   # = goes to catch
   " " | Out-Default

   Write-Verbose "SUCCEEDED"
   return 0
}
catch
{
   if ($_.FullyQualifiedErrorId -ne "ScriptHalted") # filter out simple "throw" to avoid double exception messages
   {
      Write-Verbose "EXCEPTION"
      Write-Error $_
   }

   Write-Verbose "FAILED"
   return 9
}
finally
{
   #Write-Verbose "Cleanup..."
   #" " | Out-Default

   Write-Verbose "FINISHED"

   # stop logging
   Stop-Transcript
}
