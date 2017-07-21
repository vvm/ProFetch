#!/usr/bin/env swift

import Foundation

// repository data file
let config_json_file = "config.json"

// repository info key
let RepositoryPathKey = "path"
let RepositoryFolderKey = "folder"

// repostory memeory data
var repositories: NSMutableArray?
var repository: NSMutableDictionary?

func configFileURL() -> URL {
    var fileUrl =  NSURL.fileURL(withPath: FileManager.default.currentDirectoryPath)
    fileUrl = fileUrl.appendingPathComponent(config_json_file)
    return fileUrl
}

/*
 get all reposities from config file
 */
func reposityList() -> NSMutableArray {
    if repositories == nil {
        if let savedArray = NSMutableArray.init(contentsOf: configFileURL()) {
            repositories = savedArray
        } else {
            repositories = NSMutableArray.init()
        }
    }
    
    return repositories!
}

/*
 verify git repostory address
 */
func checkGitPath(path: String) -> String {
    if path.hasSuffix(".git") {
        return path
    }
    print("Incorrect git path!")
    exit(0)
}

/**/
func checkFolderPath(path: String, folder: String?) -> String {
    if let folderPath = folder {
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: folderPath, isDirectory: &isDir) && isDir.boolValue {
            if !folderPath.hasPrefix("/") {
                return (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(folderPath)
            }
            return folderPath
        }
        print("Folder not exist")
        exit(0)
    } else {
        return FileManager.default.currentDirectoryPath
    }
}

/*
 execute shell command
 */
func runCommand(path: String?, cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
    
    var output : [String] = []
    var error : [String] = []
    
    let task = Process()
    if let _ = path {
        task.currentDirectoryPath = path!
    }
    task.launchPath = cmd
    task.arguments = args
    
    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe
    
    task.launch()
    
    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: outdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        output = string.components(separatedBy: "\n")
    }
    
    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: errdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        error = string.components(separatedBy: "\n")
    }
    
    task.waitUntilExit()
    let status = task.terminationStatus
    
    return (output, error, status)
}

/*
 for h
 show help info
 */
func showHelp(){
    print("this is a help")
}

/*
 for l
 show all repositories
 */
func showRepositories(){
    for repostory in reposityList() {
        print("\((repostory as! NSDictionary)[RepositoryFolderKey]!):\t\((repostory as! NSDictionary)[RepositoryPathKey]!)\n")
    }
}

/*
 for add
 add new repository
 */
func addRepository(path: String, folder: String) {
    var pathString: NSString = path as NSString
    pathString = pathString.lastPathComponent as NSString
    pathString = pathString.deletingPathExtension as NSString
    
    pathString = (folder as NSString).appendingPathComponent(pathString as String) as NSString
    
    print("git clone \(path) \(folder)")
    let (_, error, status) = runCommand(path: nil, cmd: "/usr/bin/git",args:"clone", path, pathString as String)
    if status != 0 {
        print("\n\t\tgot error:\n")
        for s in error {
            print("\t\t\(s)")
        }
        print("\n\n")
    } else {
        let list = reposityList()
        let rep = [
            RepositoryPathKey: path,
            RepositoryFolderKey: (folder as NSString).appendingPathComponent(((path as NSString).lastPathComponent as NSString).deletingPathExtension)
            ] as NSDictionary
        list.add(rep)
        repositories = list
        repositories!.write(to: configFileURL(), atomically: true)
    }
}

/*
 for s
 sync special repository
 */
func syncRepository(path: String) -> Bool {
    let (output, error, status) = runCommand(path: path, cmd: "/usr/bin/git",args:"pull", "--all")
    if status != 0 {
        print("\n\t\tgot error:\n")
        for s in error {
            print("\t\t\(s)")
        }
        print("\n\n")
        return false
    }
    return true
}

/*
 for s all
 sync all repositories
 */
func syncAll() {
    
}

// =========
// main code
// =========

if (CommandLine.arguments[1] == "add") { // check if arguments contain add
    var path = ""
    var folder = ""
    if CommandLine.argc == 2 {
        print("No enough arguments")
        exit(0)
    } else if CommandLine.argc == 3 {
        path = checkGitPath(path: CommandLine.arguments[2])
        folder = checkFolderPath(path: CommandLine.arguments[2], folder: nil)
    } else {
        path = checkGitPath(path: CommandLine.arguments[2])
        folder = checkFolderPath(path: CommandLine.arguments[2], folder: CommandLine.arguments[3])
    }
    
    addRepository(path: path, folder: folder)
} else {
    while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, "hlr:ps:"), option != -1 {
        switch UnicodeScalar(CUnsignedChar(option)) {
        case "h": // help
            showHelp()
        case "l": // list all repositories
            showRepositories()
        case "r": // remove one repository
            var oa = String(cString: optarg)
            break
        case "p":
            break
        case "s": // sync
            if strlen(optarg) > 0 {
                let oa = String(cString: optarg)
                syncRepository(path: oa)
            } else {
                print("xxxxxxxxxxx123")
            }
            break
        default:
            print("\(optind) is \(optarg)")
        }
    }
}
