import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
      
    var statusItem: NSStatusItem?
    var spacesMenu: NSMenu?
    var refreshTimer: Timer?
    var statusItems = [NSStatusItem]()

    struct Space {
        let index: Int
        let hasOpenWindows: Bool
        let isFocused: Bool
        let display:Int
    }
    
    struct Frame {
        let x: Float
        let y: Float
        let w: Float
        let h: Float
    }
    
    struct Display {
        let index: Int
        let spaces: [Int]
        let frame: Frame
        let has_focus: Bool
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
          
        refreshSpaces()
        setupRefreshTimer(interval: 0.5)
        NSApp.setActivationPolicy(.accessory)
    }
      
    func applicationWillTerminate(_ aNotification: Notification) {
        refreshTimer?.invalidate()

    }
    
    func setupRefreshTimer(interval: TimeInterval) {
        refreshTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(refreshSpaces), userInfo: nil, repeats: true)
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
    
    
    func sortDisplays(displays: [Display]) -> [Display] {
        return displays.sorted { (a, b) -> Bool in
            return a.frame.x < b.frame.x
        }
    }

    
    @objc func refreshSpaces() {
        let display = shell("yabai -m query --displays");
        let parsedDisplays = parseDisplays(fromOutput: display)
        let sortedParsedDisplays = sortDisplays(displays: parsedDisplays)
        let yabaiOutput = shell("yabai -m query --spaces")
        let spaces = parseSpaces(fromOutput: yabaiOutput)
        updateStatusItem(withSpaces: spaces, withDisplays: sortedParsedDisplays)
    }
    
    

    

    
    func updateStatusItem(withSpaces spaces: [Space], withDisplays displays: [Display]) {
        if let button = statusItem?.button {
            let attributedString = NSMutableAttributedString()
            let separatorString = NSAttributedString(string: "| ", attributes: [.foregroundColor: NSColor.separator])

            // Iterate over each display
            for (index, display) in displays.enumerated() {
                display.spaces.forEach { spaceIndex in
                    if let space = spaces.first(where: { $0.index == spaceIndex }) {
                        let title = "\(space.index) "
                        let attributes: [NSAttributedString.Key: Any]
                        
                        if display.has_focus{
                            if space.isFocused {
                                attributes = [.foregroundColor: NSColor.focusSpace]
                            } else if space.hasOpenWindows {
                                attributes = [.foregroundColor: NSColor.activeSpace]
                            } else {
                                attributes = [.foregroundColor: NSColor.inactiveSpace]
                            }
                        }else{
                            if space.isFocused {
                                attributes = [.foregroundColor: NSColor.focusFocusSpace]
                            } else if space.hasOpenWindows {
                                attributes = [.foregroundColor: NSColor.activeFocusSpace]
                            } else {
                                attributes = [.foregroundColor: NSColor.inactiveFocusSpace]
                            }
                        }

                        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
                        attributedString.append(attributedTitle)
                    }
                }
                // Append separator only if it's not the last display
                if index < displays.count - 1 {
                    attributedString.append(separatorString)
                }
            }

            button.attributedTitle = attributedString
        }
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
                            let spaceDisplay  = spaceDict["display"] as? Int ?? 0
                            spaces.append(Space(index: spaceIndex, hasOpenWindows: hasOpenWindows, isFocused: isFocused, display: spaceDisplay))
                        }
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        return spaces
    }
    
    
    func parseDisplays(fromOutput output: String) -> [Display] {
        var displays = [Display]()
      
        if let data = output.data(using: .utf8) {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for displayDict in jsonArray {
                        if let displayID = displayDict["id"] as? Int {
                            let displaySpaces = displayDict["spaces"] as? [Int] ?? [0]
                            var DisplayFrame = Frame(x: 0, y: 0, w: 0, h: 0)
                            if let frameDict = displayDict["frame"] as? [String: Float] {
                                DisplayFrame = Frame(
                                    x: frameDict["x"] ?? 0,
                                    y: frameDict["y"] ?? 0,
                                    w: frameDict["w"] ?? 0,
                                    h: frameDict["h"] ?? 0
                                )
                            }
                            let display_has_focus = displayDict["has-focus"] as? Bool ?? false
                            displays.append(Display(index:displayID, spaces:displaySpaces, frame: DisplayFrame, has_focus:display_has_focus ))
                        }
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        return displays
    }



}
