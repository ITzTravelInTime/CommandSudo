# CommandSudo
Extension Swift Library for [ITzTravelInTime/Command](https://github.com/ITzTravelInTime/Command) that provides support for privileged operations.

# Features

- Can start, run and just get the output of privileged command-line commands/scripts
- Makes privileged executions using Apple scripts.
- Has a notification system for the end user so, they can be reminded to do the authentication step
- Debug checks to ensure the library code is used as intended

# Usage

Usage is well documented into the source code, so check that out for more info. To prevent having mirrors of this information, this file will be just limited to the following very usefoul example usage:

```swift

import Command
import CommandSudo

//TODO: Remove this warning when I understood what I need to do
#warning("This code needs the app sandbox to be tuned off for the current project! (unless you decide to execute an embedded executable inside your app's bundle)")

/**
 Mounts an EFI partition.

    - Parameter id: The BSD Identifier string of the volume that needs mounting.
    
    - Returns: `true` if the mount operation had success, `false` if it failed.
    
    - Precondition:
      - This function requires sandboxing to be disabled
      - The `id` paramter should not be an empty string or an assertion error will be triggered.
      - the `id` paramter has to be a valid EFI partition's BSD Identifier, like: `disk0s1`, `disk2s1`, `disk3s1`, ... and so on.
*/
func mountEFIPartition( _ id: String) -> Bool{
    
    assert(!id.isEmpty, "A volume to mount is needed!")
    assert(id.starts(with: "disk") && id.contains("s"), "A valid BSD idefier for the volume is needed")
    
    var out: String?
        
    //Execution of the command must be in a separated thread, not the main!
    DispatchQueue.global(qos: .background).sync {
        //Executes the `diskutil mount` command and returns it's ouput as a string if the operation was executed correctly.
        out = Command.Sudo.run(cmd: "/usr/sbin/diskutil", args: ["mount \(id)"])?.outputString()
    }
    
    //if the operation was correctly executed it's output is analised to determinate if the mount operation had success.
    if let text = out{
    
        return (text.contains("mounted") && (text.contains("Volume EFI on") || text.contains("Volume (null) on") || (text.contains("Volume ") && text.contains("on")))) || (text.isEmpty)
    
    }
    
    return false
}

//TODO: Remove this warning when I understood what I need to do
#warning("If you want to test this for youserself please replace `disk0s1` with the BSD ID of the volume you want to get mounted")
print("Is the EFI partition now mounted? \((mountEFIPartition("disk0s1") ? "Yes" : "No"))")

```

# What apps/programs is this Library intended for?

This library should be used by non-sandboxed swift apps/programs (unless it's used from a priviledged embedded helper executable), that needs to run terminal scripts/commands or separated executables from their own using root privileges.

This code is intended for macOS only since it requires the system library `Process` type from the Swift API, that is only available on that platform.

# **Warnings**

 - To let the code to work your app/program might most likely need to not be sandboxed, unless this code is used only by some privileged program like an embedded helper tool.
 - All functions from the `Command.Sudo` class needs to be run from a non-main thread, except from the `Command.Sudo.start` function.

# About the project

This code was created as part of my [TINU project](https://github.com/ITzTravelInTime/TINU) and it has been separated and made into it's own library to make the main project's source less complex and more focused on it's aim. 

Also having this as it's own library allows for code to be updated separately and so various versions of the main TINU app will be able to be compiled all with the latest version of this library.

# Credits

 - ITzTravelInTime (Pietro Caruso) - Project creator and main developer

# Contacts

 - ITzTravelInTime (Pietro Caruso): piecaruso97@gmail.com

# Legal info

CommandSudo: A library for the execution of privileged operations.
Copyright (C) 2021 Pietro Caruso (ITzTravelInTime)

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
