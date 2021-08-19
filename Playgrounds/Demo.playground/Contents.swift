import Foundation
import Command
import CommandSudo

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


#warning("If you want to test this for youserself please replace `disk0s1` with the BSD Name of the volume you want to get mounted, to get said BSD Name use the `diskutil list` command in the terminal")
print("Is the EFI partition now mounted? \((mountEFIPartition("disk0s1") ? "Yes" : "No"))")
