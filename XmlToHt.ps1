<#  
.SYNOPSIS
   XmlToHashtable function
.DESCRIPTION
   PowerShell example script to convert simple xml into a hashtable
.NOTES
#>

[CmdLetBinding()]
param
(
   [switch]$UnitTest1,
   [switch]$UnitTest2,
   [switch]$UnitTest3
)


function Convert-XmlToHt()
{
   [CmdLetBinding()]
   param
   (
      $Node,
      [string]$Prefix = ""
   )

   begin
   {
      # display and validate parameters
      $Parameters = (Get-Command -Name $MyInvocation.InvocationName).Parameters.Keys | Sort-Object | % { Get-Variable -Name $_ -ErrorAction SilentlyContinue }
      #$Parameters | Format-Table -AutoSize -Wrap | Out-Default
      $Undefined = $Parameters | ? { $_.Value -eq "undefined" }
      if ($Undefined -ne $null) { throw "The following parameters where undefined: $($Undefined | % Name )" }
   }
   process
   {
      $ht = @{}

      # attributes
      foreach ($attr in $Node.Attributes)
      {
         $key = if ($Prefix -eq "") {$Node.localname + "-" + $attr.name} else {$Prefix + "-" + $Node.localname + "-" + $attr.name}
         $value = $attr.value
         $ht.Add($key, $value)
      }

      # value
      if ($Node.SelectNodes("*").count -eq 0)
      {
         $key = if ($Prefix -eq "") {$Node.LocalName} else {$Prefix + "-" + $Node.LocalName}
         $value = $Node.InnerText
         if ($value -ne "") { $ht.Add($key, $value) }
      }

      # children
      foreach ($child in $Node.SelectNodes("*"))
      {
         $key = if ($Prefix -eq "") {$Node.Name} else {$Prefix + "-" + $Node.Name}
         $ht += Convert-XmlToHt -Node $child -Prefix $key
      }

      return $ht
   }
   end
   {
   }
}


###### Unit Tests ######
### if not running unit tests, then simply return
if (-not $UnitTest1 -and -not $UnitTest2 -and -not $UnitTest3)
{
   return
}

### Unit Test 1
if ($UnitTest1)
{
   try
   {
      "Unit Test 1" | Out-Default
      $InputFile = Join-Path -Path $PSScriptRoot -Childpath "xmltoht-ut1.xml"
      [xml]$InputXml = Get-Content -Path $InputFile
      $OutputHt = Convert-XmlToHt -Node $InputXml.SelectSingleNode("/unittest1") -ErrorAction Stop

      $OutputHt.GetEnumerator() | Sort-Object Name | Format-Table -AutoSize

      $Keys = $("unittest1-element2", "unittest1-element3-attr3", "unittest1-element4", "unittest1-element4-attr4", "unittest1-element5-element5b", "unittest1-element5-element5c-attr5c", "unittest1-element5-element5d", "unittest1-element5-element5d-attr5d")
      if ($OutputHt.Count -ne $Keys.Length)
      {
         Write-Error "UnitTest1: Hash table count is incorrect."
      }
      foreach ($Key in $Keys)
      {
         if (-not $OutputHt.ContainsKey($Key))
         {
            Write-Error ("UnitTest1: Hash table is missing key {0}." -f $Key)
         }
      }
   }
   catch
   {
      Write-Error ("UnitTest1: " + $_)
   }
}

### Unit Test 2
if ($UnitTest2)
{
   try
   {
      "Unit Test 2" | Out-Default
      $InputFile = Join-Path -Path $PSScriptRoot -Childpath "xmltoht-ut2.xml"
      [xml]$InputXml = Get-Content -Path $InputFile
      $OutputHt = @{}
      $nodes = $InputXml.SelectNodes("/applianceDefinition/virtualMachines/vm")
      foreach ($node in $nodes)
      {
         $OutputHt += Convert-XmlToHt -Node $node -Prefix $node.role.ToUpper() -ErrorAction Stop
      }
      $OutputHt += Convert-XmlToHt -Node $InputXml.SelectSingleNode("/applianceDefinition/settings") -ErrorAction Stop

      $OutputHt.GetEnumerator() | Sort-Object Name | Format-Table -AutoSize

      if ($OutputHt.Count -ne 41)
      {
         Write-Error "UnitTest2: Hash table count is incorrect."
      }
      if ($OutputHt["DATABASE-vm-role"] -ne 'DATABASE')
      {
         Write-Error "UnitTest2: [DATABASE-vm-role] is not equal to 'DATABASE'"
      }
      if ($OutputHt["DATABASE-vm-name"] -ne 'SQL')
      {
         Write-Error "UnitTest2: [DATABASE-vm-name] is not equal to 'SQL'"
      }
      if ($OutputHt["DATABASE-vm-ip"] -ne '192.168.1.3')
      {
         Write-Error "UnitTest2: [DATABASE-vm-ip] is not equal to '192.168.1.3'"
      }
      if ($OutputHt["DATABASE-SQL-usersConfig-saUser-name"] -ne 'sa')
      {
         Write-Error "UnitTest2: [DATABASE-SQL-usersConfig-saUser-name] is not equal to 'sa'"
      }
      if ($OutputHt["DATABASE-SQL-usersConfig-password"] -ne 'p@$$worD')
      {
         Write-Error "UnitTest2: [DATABASE-SQL-usersConfig-password] is not equal to 'p@$$worD'"
      }
   }
   catch
   {
      Write-Error ("UnitTest2: " + $_)
   }
}

### Unit Test 3
if ($UnitTest3)
{
   try
   {
      Convert-XmlToHt -Node $InputXml -ErrorAction Stop
      Write-Error "UnitTest3: Did not fail with bad input."
   }
   catch
   {
   }
}
