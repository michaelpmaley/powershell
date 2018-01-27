// C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe returncode.cs
using System;
namespace Project
{
  class Application
  {
     static int Main(string[] args)
     {
        Console.WriteLine("Starting...");

        Console.WriteLine("Checking args...");
        if (args.Length == 0)
        {
           Console.Error.WriteLine("No argument was specified. Return code = 99");
           return 99;
        }

        Console.WriteLine("Calculating return code...");
        int rc = Int32.Parse(args[0]); // will throw an unhandled exception if the first argument is not numeric, that can be useful for testing purposes

        Console.WriteLine("Return code = {0}", rc);
        return rc;
     }
  } // class
} // namespace