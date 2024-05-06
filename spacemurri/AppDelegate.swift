import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
      
    var statusItem: NSStatusItem?
    var spacesMenu: NSMenu?
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
          
        refreshSpaces()
        setupRefreshTimer(interval: 1)
        NSApp.setActivationPolicy(.accessory)
    }
      
    func applicationWillTerminate(_ aNotification: Notification) {
        refreshTimer?.invalidate()

    }
    
    func setupRefreshTimer(interval: TimeInterval) {
        refreshTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(refreshSpaces), userInfo: nil, repeats: true)
    }
      
    func constructMenu(withSpaces spaces: [Int]) {
        let menu = NSMenu()
                 
               for space in spaces {
                   let menuItem = NSMenuItem(title: "Space \(space)", action: #selector(spaceMenuItemClicked(_:)), keyEquivalent: "")
                   menuItem.tag = space
                   menuItem.target = self
                   menu.addItem(menuItem)
               }
                 
               menu.addItem(NSMenuItem.separator())
               menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                 
               statusItem?.menu = menu
               spacesMenu = menu
    }
      
    
    @discardableResult
    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
      
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["--login", "-c", command]
        if let shellPath = ProcessInfo.processInfo.environment["SHELL"] {
            task.launchPath = shellPath
        } else {
            task.launchPath = "/bin/zsh"
        }
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
    
    
    
    
    @objc func spaceMenuItemClicked(_ sender: NSMenuItem) {
        let spaceNumber = sender.tag

        shell("/opt/homebrew/bin/yabai -m space --focus \(spaceNumber)")
    }
    
    @objc func refreshSpaces() {
         let yabaiOutput = shell("yabai -m query --spaces")
         let spaces = parseSpaces(fromOutput: yabaiOutput)
         updateStatusItem(withSpaces: spaces)
     }
    
    func updateStatusItem(withSpaces spaces: [Space]) {
        if let button = statusItem?.button {
            let spaceTitles = spaces.map { space -> String in
                print("\nSpace:",space);
                let indicator = space.isFocused ? "*" : space.hasOpenWindows ? "+" : " "
                print("\nIndicator:",indicator);
                return "\(indicator)\(space.index)"
            }.joined(separator: " ")
            button.title = spaceTitles
        }
    }
    

    struct Space {
        let index: Int
        let hasOpenWindows: Bool
        let isFocused: Bool
    }
      
    func parseSpaces(fromOutput output: String) -> [Space] {
        var spaces = [Space]()
      
        if let data = output.data(using: .utf8) {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for spaceDict in jsonArray {
                        if let spaceIndex = spaceDict["index"] as? Int {
                            let hasOpenWindows = (spaceDict["windows"] as? [Any])?.isEmpty == false
                            let isFocused = spaceDict["is-visible"] as? Bool ?? false
                            spaces.append(Space(index: spaceIndex, hasOpenWindows: hasOpenWindows, isFocused: isFocused))
                        }
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
      
        return spaces
    }


}
