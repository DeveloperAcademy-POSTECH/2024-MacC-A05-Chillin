//
//  NWPathMonitor + Extension.swift
//  Reazy
//
//  Created by 문인범 on 11/8/24.
//

import Network


extension NWPathMonitor {
    public func startMonitoring(callBack: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        
        monitor.start(queue: .main)

        monitor.pathUpdateHandler = { path in
            let isConnected = path.status == .satisfied
            
            if isConnected == true {
                print("연결됨")
            } else {
                print("연결안됨")
            }
            
            callBack(path.status == .satisfied)
            monitor.cancel()
        }
    }
}
