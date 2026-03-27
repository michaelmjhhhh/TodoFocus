import Foundation

// Agent entry point
// Compiled as a separate executable: TodoFocusAgent
// Runs as a LaunchAgent (always-alive)

autoreleasepool {
    let controller = AgentSessionController()
    controller.run()
}

RunLoop.main.run()