//
//  practice.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import SwiftUI

struct practice: View {
    @State private var number = ""

    var body: some View {
        TextField("숫자 입력", text: $number)
            .keyboardType(.numberPad)
            .onChange(of: number) { newValue in
                let digits = newValue.filter { $0.isNumber }
                // 4글자마다 하이픈 추가
                let withHyphens = digits.chunked(by: 4).joined(separator: "-")
                // 원래 값과 다르면 갱신
                if withHyphens != number {
                    number = withHyphens
                }
            }
    }

}

// String extension
extension String {
    func chunked(by length: Int) -> [String] {
        stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
}

#Preview {
    practice()
}
