/*
 
 CommandSudo: A library for the execution of privileged operations.
 Copyright (C) 2021 Pietro Caruso (ITzTravelInTime)

 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

 
 */

import Foundation

#if os(macOS)
import AppKit
import TINURecovery
import TINUNotifications
import Command

extension Command{
    /**This class contains the extensions for `Command` that allows it to execute priviledged operations
            - Precondition: This should work only if the current app/program is not sandboxed.
     */
    public class Sudo: CommandExecutor{
        
        ///The contents of the notification sent when the current app/program needs the user to authenticate
        public static var authNotification: TINUNotifications.Notification = .init(id: "defaultAuthDescription", message: "Please login now", description: "Please login now to continue")
        
        ///Determinates if the current app/program should notify the user to enter credentials when needed
        public static var canSendNotifications: Bool = true
        
        ///Comodity string just to avoid repeting this bit over and over
        private static let extra = " with administrator privileges"
        ///Tracks the authentication notification
        private static var notification: NSUserNotification!
       
        ///This function sends a notification to tell the user to authenticate
        private class func sendAuthNotification(){
            if (canSendNotifications){
                print("Sending authentication notification")
                retireAuthNotification()
                Command.Sudo.notification = nil
                Command.Sudo.notification = authNotification.send()
                print("Authentication notification sent")
            }
        }
        
        ///This function removes the notification sent with the `Command.Sudo.sendAuthNotification` function from the Notifications center
        private class func retireAuthNotification(){
            if let noti = Command.Sudo.notification{
                NSUserNotificationCenter.default.removeDeliveredNotification(noti)
                print("Authentication notification retired")
            }
        }
        
        /**
         Uses an apple script to get the standard output of a command run using root privileges.
            - Returns: A `String?` value that contains the standard output of the script provvided using the `cmd` arg. `nil` is returned if the apple script failed to execute.
         
            - Parameters:
                    - cmd: The terminal command/script that should be executed by the apple script
                    - escapeQuotes: Determinates if the command/script that will be executed should have it's quites characters escaped first
         
            - Precondition:
                - The parameter `cmd` must not be empty, or otherwise an assertion error will be triggered.
                - This function should not be run from the main thread, that will cause an assertion error!
                - This function will most likely not work if sandboxxing is enabled and executables present outside the app/programs's bundle are used inside the script.
         
         */
        public class func executeScriptUsingAppleScript(cmd: String, escapeQuotes: Bool = true) -> String?{
            
            print("Executing \(cmd) with administrator privileges")
            
            assert(!cmd.isEmpty, "The process needs a script to execute!")
            //Dropped this assrtion because it's unreliable and gave lots of false positives during testing
            /*assert(!Thread.current.isMainThread, """
                /-------------------------------------------------------\\
                |Running a command from the main thread is unsupported!!|
                \\-------------------------------------------------------/
            """)*/
            
            sendAuthNotification()
            
            //if simulateUseScriptAuth{
            var ncmd = escapeQuotes ? "" : cmd
            
            if escapeQuotes{
                
                for c in cmd{
                    if String(c) == "\""{
                        ncmd.append("\'")
                    }else{
                        ncmd.append(c)
                    }
                }
                
            }
            
            let theScript = "do shell script \"echo $(\(ncmd))\"" + Sudo.extra
            
            print("The apple script that will be executed: \(theScript)")
            
            let appleScript = NSAppleScript(source: theScript)
            
            let result = appleScript?.executeAndReturnError(nil)
            
            retireAuthNotification()
            
            if let eventResult = result{
                return eventResult.stringValue
            }else{
                return nil
            }
        }
        
        
        /**
         Uses an apple script to get the standard output of a command run using root privileges.
            - Returns: A `String?` value that contains the standard output of the script provvided using the `cmd` arg. `nil` is returned if the apple script failed to execute.
         
            - Parameters:
                    - cmd: The terminal command/script that should be executed by the apple script
                    - escapeQuotes: Determinates if the command/script that will be executed should have it's quites characters escaped first
         
            - Precondition:
                - The parameter `cmd` must not be empty, or otherwise an assertion error will be triggered.
                - This function should not be run from the main thread, that will cause an assertion error!
                - This function will most likely not work if sandboxxing is enabled and executables present outside the app/programs's bundle are used inside the script.
         
         */
        @available(*, deprecated, message: "This method can lead to dangerous exploits using the shell PATH variable, it's highly reccomended not use it")
        public class func getOut(cmd: String, escapeQuotes: Bool) -> String?{
            
            print("Executing \(cmd) with administrator privileges")
            
            if CurrentUser.isRoot{
                return Command.getOut(cmd: cmd)
            }
            
            return executeScriptUsingAppleScript(cmd: cmd, escapeQuotes: true)
        }
        
        /**
         Uses an apple script to get the standard output of a command run using root privileges.
         
            - Returns: A `String?` value that contains the standard output of the script provvided using the `cmd` arg. `nil` is returned if the apple script failed to execute.
         
            - Parameters:
                    - cmd: The terminal command/script that should be executed by the apple script.
         
            - Precondition:
                - The parameter `cmd` must not be empty, or otherwise an assertion error will be triggered.
                - This function should not be run from the main thread, that will cause an assertion error!
                - This function will most likely not work if sandboxxing is enabled and executables present outside the app/programs's bundle are used inside the script.
         
         */
        @available(*, deprecated, message: "This method can lead to dangerous exploits using the shell PATH variable, it's highly reccomended not use it")
        public static func getOut(cmd: String) -> String? {
            return Sudo.getOut(cmd: cmd, escapeQuotes: true)
        }
        
        /**
         This function stars a `Process` object using root privileges (obtained using the osascript executable and a slittle apple script).
         
            - Parameters:
               - cmd: The path to the executable to launch in order to launch the `Process` object, must not be empty or an assertion error will be triggered.
               - args: The args for the executable.
         
            - Returns: If the `Process` object launched successfully an `Handle` object is returned to track it, otherwise `nil` is returned.
         
            - Precondition:
                - The parameter `cmd` must not be empty and must be the path to a file that exists or an assertion error will be triggered.
                - Executing this function will very likely need sandboxing to be disabled or the `Process` will not launch.
         
         */
        public class func start(cmd: String, args: [String]! = nil) -> Handle?{
            return start(cmd: cmd, args: args, shouldActuallyUseSudo: true)
        }
        
        /**
         This function stars a `Process` object using root privileges (obtained using the osascript executable and a slittle apple script).
         
            - Parameters:
               - cmd: The path to the executable to launch in order to launch the `Process` object, must not be empty or an assertion error will be triggered.
               - args: The args for the executable.
               - shouldActuallyUseSudo: Determinates if the shell script to be executed should also prefix sudo in front of the provvided executable and args.
         
            - Returns: If the `Process` object launched successfully an `Handle` object is returned to track it, otherwise `nil` is returned.
         
            - Precondition:
                - The parameter `cmd` must not be empty and must be the path to a file that exists or an assertion error will be triggered.
                - Executing this function will very likely need sandboxing to be disabled or the `Process` will not launch.
         
         */
        public class func start(cmd: String, args: [String]!, shouldActuallyUseSudo: Bool) -> Handle?{
            print("Executing \(cmd) with args \(args ?? []) with administrator privileges")
            
            //De-escapes the space for a check of the executable
            var check = cmd
            if check.first == "\""{
                check.removeFirst()
            }
            if check.last == "\""{
                check.removeLast()
            }
            
            assert(!check.isEmpty, "The process needs a script to execute!")
            assert(FileManager.default.fileExists(atPath: check), "A valid path to an executable file that exist must be specified for this arg")
            
            if CurrentUser.isRoot {
                return Command.start(cmd: check, args: args)
            }
            
            sendAuthNotification()
            
            var pcmd = shouldActuallyUseSudo ? "/usr/bin/sudo " : ""
            
            //var cmdList = ["\(((cmd.first ?? " ") == "\"") ? "" : "\"")\(cmd)\(((cmd.last ?? " ") == "\"") ? "" : "\"")"]
            var cmdList = [cmd]
            cmdList.append(contentsOf: args ?? [])
            
            for i in cmdList{
            eee: for ii in i{
                    if ii == "\""{
                        pcmd += "\'\"\'\"\'"
                        continue eee
                    }
                
                    pcmd += String(ii)
                }
                
                pcmd += " "
            }
            
            if (pcmd.last ?? Character("A")) == " "{
                pcmd.removeLast()
            }
            
            let baseCMD = "\'do shell script \"\(pcmd)\"\(Sudo.extra)\'"
            
            print("The apple script execution script that will be used: ")
            
            print("/bin/zsh -c /usr/bin/osascript -e " + baseCMD)
            
            let start = Command.start(cmd: "/bin/zsh", args: ["-c", "/usr/bin/osascript -e " + baseCMD])
            
            retireAuthNotification()
            
            return start
        }
        
        /**
         Manages a complete execution for a `Command.Sudo` object from start to finish.
            
            - Parameters:
                - cmd: The path to the executable to launch in order to perform the command, or the command to execute (see the description of the `args` parameter to learn more).
                - args: The arguments for the specified executable, if nil the `cmd` parameter will be run as a terminal command using the sh shell.
                - shouldActuallyUseSudo: Determinates if the shell script to be executed should also prefix sudo in front of the provvided executable and args.
         
            - Returns: The `Command.Result` object obtained from the execution of the `Process` object
         
            - Precondition:
                - This will suspend the thread it's running on, avoid running this from the main thread or the app/program will stop responding!
                - This function requres sandboxing to be dissbled unless it's run by passing the path for an executable embedded into the current bundle into the `cmd` argument and the `args` argument is not nil
         */
        public class func run(cmd : String, args : [String]?, shouldActuallyUseSudo: Bool) -> Command.Result? {
            var ret: Command.Result!
            
            if let cargs = args{
                ret = Self.start(cmd: cmd, args: cargs, shouldActuallyUseSudo: shouldActuallyUseSudo)?.result()
            }else{
                assert(!cmd.isEmpty, "The process needs a path to an executable to execute!")
                //assert(FileManager.default.fileExists(atPath: cmd), "A valid path to an executable file that exist must be specified for this arg")
                //assert(!Sandbox.isEnabled, "The app sandbox should be disabled to perform this operation!!")
                ret = Self.start(cmd: "/bin/zsh", args: ["-c", cmd])?.result()
            }
            
            print("Executed command: \(cmd) \(args?.stringLine() ?? "")")
            
            if ret != nil{
                print("Exit code: \(ret.exitCode)")
                print("Output:\n\(ret.outputString())")
                print("Error:\n\(ret.errorString())")
            }else{
                print("Command returned nil")
            }
            
            return ret
        }
        
        
    }
    
}

#endif
