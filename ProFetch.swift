#!/usr/bin/env swift

import Foundation

let config_json_file = "config.json"

let RepositoryPathKey = "path"
let RepositoryFolderKey = "folder"

var repositories: NSMutableArray?
var repository: NSMutableDictionary?

// 得到json中的仓库列表
func reposityList() -> NSMutableArray {
    if let _ = repositories {
        
    } else {
        var fileUrl =  NSURL.fileURL(withPath: FileManager.default.currentDirectoryPath)
        var fileUrl = fileUrl.appendingPathComponent(config_json_file)
        if let savedArray = NSMutableArray.init(contentsOf: fileUrl) {
            repositories = savedArray
        } else {
            repositories = NSMutableArray.init()
        }
    }
    
    return repositories!
}

func checkGitPath(path: String) -> String {
    if path.hasSuffix(".git") {
        return path
    }
    print("Incorrect git path!")
    exit(0)
}

func checkFolderPath(path: String, folder: String?) -> String {
    if let folderPath = folder {
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: folderPath, isDirectory: &isDir) && isDir.boolValue {
            return folderPath
        }
        print("Folder not exist")
        exit(0)
    } else {
        return "."
    }
}

func showHelp(){
    print("this is a help")
}

func showRepositories(){
    print("this is a help")
}

func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
    
    var output : [String] = []
    var error : [String] = []
    
    let task = Process()
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

func addRepository(path: String, folder: String) {
    var pathString: NSString = path as! NSString
    pathString = pathString.lastPathComponent as! NSString
    pathString = pathString.deletingPathExtension as! NSString
    
    pathString = (folder as! NSString).appendingPathComponent(pathString as! String) as! NSString
    
    print("git clone \(path) \(folder)")
    let (output, error, status) = runCommand(cmd: "/usr/bin/git",args:"clone", path, pathString as! String)
    if status != 0 {
        print("\n\t\tgot error:\n")
        for s in error {
            print("\t\t\(s)")
        }
        print("\n\n")
    } else {
        var list = reposityList()
        var rep = [
            RepositoryPathKey: path,
            RepositoryFolderKey: folder
            ] as! NSDictionary
        list.add(rep)
        repositories = list
        var fileUrl =  NSURL.fileURL(withPath: FileManager.default.currentDirectoryPath)
        fileUrl.appendingPathComponent(config_json_file)
        repositories!.write(to: fileUrl, atomically: true)
    }
}

func syncRepository(path: String) {
    
}

func syncAll() {
    
}

if (CommandLine.arguments[1] == "add") {
    var path = ""
    var folder = ""
    if CommandLine.argc == 2 {
        
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
        case "s": // 同步
            break
        default:
            print("\(optind) is \(optarg)")
        }
    }
}
