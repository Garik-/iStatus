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
        VStack(alignment: .leading) {
            HStack {
                Text("CPU")
                    .bold()
                Spacer()
                Text(data.packet.cpu)
                    .opacity(0.75)
            }.padding(.vertical, 1)

            HStack {
                Text("Memory")
                    .bold()
                Spacer()
                Text(data.packet.mem.usage)
                    .opacity(0.75)
            }.padding(.vertical, 1)

            VStack(alignment: .leading) {
                Text(
                    "Total memory: \((data.packet.mem.total * 1000).formatted(.byteCount(style: .memory)))"
                )
                .foregroundColor(.secondary)
                .font(.subheadline)

                Text(
                    "Used memory: \((data.packet.mem.used * 1000).formatted(.byteCount(style: .memory)))"
                )
                .foregroundColor(.secondary)
                .font(.subheadline)

                Text(
                    "Available memory: \((data.packet.mem.available * 1000).formatted(.byteCount(style: .memory)))"
                )
                .foregroundColor(.secondary)
                .font(.subheadline)

            }.padding(.vertical, 6)

        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .padding(.top, 4)

        .frame(minWidth: menuWidth)
    }
}

#Preview {
    MunuItemView().environmentObject(AppData())
}
