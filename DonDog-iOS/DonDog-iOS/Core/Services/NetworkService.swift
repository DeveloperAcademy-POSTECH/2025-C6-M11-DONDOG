//
//  NetworkService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/20/25.
//

import Combine
import Foundation
import Network

final class NetworkService: ObservableObject {
    enum Status { case satisfied, unsatisfied, unknown }
    @Published private(set) var status: Status = .satisfied

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "net.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.status = .satisfied
                } else if path.status == .requiresConnection {
                    self?.status = .unknown
                } else {
                    self?.status = .unsatisfied
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
