//
//  MenuItemView.swift
//  iStatus
//
//  Created by Гарик Джан on 09.02.2025.
//

import AppKit
import SwiftUI

func createDataMenuItem(_ appData: AppData) -> NSMenuItem {
    let menuItem = NSMenuItem()
    let hostingView = NSHostingView(
        rootView: MunuItemView().environmentObject(appData))
    hostingView.setFrameSize(hostingView.intrinsicContentSize)

    menuItem.view = hostingView

    return menuItem
}

struct MunuItemView: View {
    @EnvironmentObject var data: AppData

    var body: some View {
        VStack {
            HStack {
                Text("test")
                    .bold()
                Spacer()
                Text("test")
                    .opacity(0.75)
            }
            Text(data.someText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .padding(.top, 4)

        .frame(minWidth: 200)
    }
}

#Preview {
    MunuItemView().environmentObject(AppData())
}
