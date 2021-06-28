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
        
        ///Initializer for compliance with the `CommandExecutor` protocol
        public required init(){
            //Litterally does nothing since this class is used more like a namespe and so it doesn't contain any stored values to intialize
        }
        
        ///The contents of the notification sent when the current app/program needs the user to authenticate
        public static var authNotification: TINUNotificationDescriptor = TINUNotifications.BaseDescriptor.init(id: "defaultAuthDescription", title: "Please login now", description: "Please login now to continue")
        
        ///Determinates if the current app/program should notify the user to enter credentials when needed
        public static var canSendNotifications: Bool = true
        
        ///Comodity string just to avoid repeting this bit over and over
        private static let extra = " with administrator privileges"
        ///Tracks the authentication notification
        private static var notification: NSUserNotification!
       
        ///This function sends a notification to tell the user to authenticate
        private class func sendAuthNotification(){
            if (canSendNotifications){
                
                retireAuthNotification()
                Command.Sudo.notification = nil
                
                Command.Sudo.notification = authNotification.send()
            }
        }
        
        ///This function removes the notification sent with the `Command.Sudo.sendAuthNotification` function from the Notifications center
        private class func retireAuthNotification(){
            if let noti = Command.Sudo.notification{
                NSUserNotificationCenter.default.removeDeliveredNotification(noti)
            }
        }
        
        
        /**
         Uses an apple script to get the standard output of a command run using root privileges (done via apple script).
            - Returns: A `String?` value that contains the standard output of the script provvided using the `cmd` arg. `nil` is returned if the apple script failed to execute.
         
            - Parameters:
                    - cmd: The terminal command/script that should be executed by the apple script
                    - escapeQuotes: Determinates if the command/script that will be executed should have it's quites characters escaped first
         
            - Precondition:
                - The parameter `cmd` must not be empty, or otherwise an assertion error will be triggered.
                - This function should not be run from the main thread, that will cause an assertion error!
                - This function will most likely not work if sandboxxing is enabled and executables present outside the app/programs's bundle are used inside the script.
         
         */
        public class func getOut(cmd: String, escapeQuotes: Bool = true) -> String?{
            
            if CurrentUser.isRoot{
                return Command.getOut(cmd: cmd)
            }
            
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
            
            print(theScript)
            
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
         Uses an apple script to get the standard output of a command run using root privileges (done via apple script).
         
            - Returns: A `String?` value that contains the standard output of the script provvided using the `cmd` arg. `nil` is returned if the apple script failed to execute.
         
            - Parameters:
                    - cmd: The terminal command/script that should be executed by the apple script.
         
            - Precondition:
                - The parameter `cmd` must not be empty, or otherwise an assertion error will be triggered.
                - This function should not be run from the main thread, that will cause an assertion error!
                - This function will most likely not work if sandboxxing is enabled and executables present outside the app/programs's bundle are used inside the script.
         
         */
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
                - The parameter `cmd` must not be empty or an assertion error will be triggered.
                - Executing this function will very likely need sandboxing to be disabled or the `Process` will not launch.
         
         */
        public class func start(cmd : String, args: [String]) -> Handle?{
            if CurrentUser.isRoot {
                return Command.start(cmd: cmd, args: args)
            }
            
            assert(!cmd.isEmpty, "The process needs a script to execute!")
            
            sendAuthNotification()
            
            var pcmd = "sudo "
            
            for i in args[1]{
                if i == "\""{
                    pcmd += "\'\"\'\"\'"
                }else{
                    pcmd += String(i)
                }
            }
            
            pcmd += ""
            
            let baseCMD = "osascript -e \'do shell script \"\(pcmd)\"\(Sudo.extra)\'"
            
            print(baseCMD)
            
            let start = Command.start(cmd: cmd, args: [args[0], baseCMD])
            
            retireAuthNotification()
            
            return start
        }
        
        /**
         This function manages a `Process` object from start to execution finish using root privileges (obtained using the osascript executable and a slittle apple script).
            
            - Parameters:
                - cmd: The path to the executable to launch in order to perform the command, or the command/script to execute int he terminal (see the description of the `args` parameter to learn more).
                - args: The arguments for the specified executable, if this value is `nil` the `cmd` parameter will be run as a terminal command/script using the sh shell.
         
            - Returns: The `Command.Result` object obtained from the execution of the `Process` object, `nil` is returned if the process failed to start
         
            - Precondition:
                - This will suspend the thread it's running on, avoid running this from the main thread or the app/program will stop responding (also an assertion error could be triggered)!
                - The parameter `cmd ` should not be an empty string, that will trigger an assertion error.
                - This function requres sandboxing to be dissbled.
         */
        public class func run(cmd : String, args : [String]?) -> Result? {
            Command.genericRun(Sudo(), cmd: cmd, args: args)
        }
        
        /**
         This function manages a `Process` object from start to execution finish using root privileges (obtained using the osascript executable and a slittle apple script).
            
            - Parameters:
                - cmd: The command/script to execute using the sh shell.
         
            - Returns: The `Command.Result` object obtained from the execution of the `Process` object, `nil` is returned if the process failed to start
         
            - Precondition:
                - This will suspend the thread it's running on, avoid running this from the main thread or the app/program will stop responding (also an assertion error could be triggered)!
                - The parameter `cmd ` should not be an empty string, that will trigger an assertion error.
                - This function requres sandboxing to be dissbled.
         */
        public static func run(cmd: String) -> Command.Result? {
            Command.genericRun(Sudo(), cmd: cmd, args: nil)
        }
        
        
    }
    
}

#endif
