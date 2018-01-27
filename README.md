# PowerShell Scripts

A collection of PowerShell scripts.

## Template.ps1

- Base template for any PowerShell script, especially ones that will be productized
- Demonstrates getting input data via parameters with parameters sets including an input file and MDT environment variables
- Demonstrates process handling using a direct call, Start-Process, and System.Diagnostics.Process
- Demonstrates error handling with a cmdlet, advanced function, native command, and custom .exe
- Demonstrates converting SQL query result (DataRows) into an array of custom PowerShell objects

## XmlToHt.ps1

- Function to convert XML to a HashTable
- Demonstrates how a shared function can be unit tested before being dot sourced into the main script
