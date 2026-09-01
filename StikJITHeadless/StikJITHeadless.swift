//
//  StikJITHeadless.swift
//  StikJITHeadless
//
//  Created by Duy Tran on 30/8/26.
//

import Foundation
import StikJIT

@objc(StikJITWrapper) public class StikJITWrapper: NSObject {
    @objc public static func enableJIT(with pid: Int32, pairingFile: URL, ddiPath: URL, scriptType: Int, scriptString: String?) -> String {
        let ddiPaths = DDIPaths.default(in: ddiPath)
        let readiness = StikJIT.prepareDevice(pairingFile: pairingFile, paths: ddiPaths)
        switch readiness {
        case .ready(_):
            break
        case .unreachable(let reason):
            return "StikJIT.prepareDevice returned .unreachable: \(reason)"
        case .preparationFailed(let reason):
            return "StikJIT.prepareDevice returned .preparationFailed: \(reason)"
        @unknown default:
            return "Unknown error"
        }

        do {
            if scriptType == 0 {
                try StikJIT.enableJIT(targetPID: pid, pairingFile: pairingFile, ddiPaths: ddiPaths)
            } else {
                let script: StikJIT.Script
                switch scriptType {
                case 1:
                    script = .universal
                case 2:
                    script = .legacy
                case 3:
                    guard let scriptString, !scriptString.isEmpty else {
                        return "Custom JIT script is not selected."
                    }
                    let scriptURL = URL.temporaryDirectory.appending(component: "script.js")
                    try scriptString.write(to: scriptURL, atomically: true, encoding: .utf8)
                    script = .custom(scriptURL)
                default:
                    return "Unknown JIT script type."
                }
                try StikJIT.enableJIT(targetPID: pid, pairingFile: pairingFile, ddiPaths: ddiPaths, script: script, forceScript: true)
            }
            return ""
        } catch {
            return error.localizedDescription
        }
    }
}
