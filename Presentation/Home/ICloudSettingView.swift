//
//  ICloudSettingView.swift
//  Reazy
//
//  Created by Claude on 7/19/26.
//

import SwiftUI

struct ICloudSettingView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel

    @State private var useICloud: Bool = UserDefaults.standard.isICloudEnabled
    @State private var showTurnOffConfirm: Bool = false
    @State private var now: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    homeViewModel.homeViewAction = .setting
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("설정")
                            .reazyFont(.text1)
                    }
                    .foregroundStyle(.primary1)
                }

                Spacer()

                Text("iCloud 설정")
                    .reazyFont(.button1)

                Spacer()

                Button(action: {
                    homeViewModel.homeViewAction = .none
                }) {
                    Text("완료")
                        .reazyFont(.text1)
                        .foregroundStyle(.primary1)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)

            Divider()
                .padding(0)

            VStack(alignment: .leading, spacing: 0) {
                List {
                    Toggle("iCloud 사용", isOn: iCloudToggleBinding)
                        .foregroundStyle(.gray800)
                        .disabled(homeViewModel.isICloudMigrating)
                }
                .environment(\.defaultMinListRowHeight, 52)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(height: 52)
                .scrollDisabled(true)

                if let statusText {
                    Text(statusText)
                        .reazyFont(.body1)
                        .foregroundStyle(.gray700)
                        .padding(.top, 10)
                }

                Spacer()
            }
            .padding(20)
        }
        .background(.gray200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: 520, maxHeight: 620)
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
        .alert("iCloud를 끄면 이 기기에서만 데이터가 저장됩니다", isPresented: $showTurnOffConfirm) {
            Button("취소", role: .cancel) {}
            Button("끄기", role: .destructive) {
                useICloud = false
                Task { await homeViewModel.syncICloudStorage(toICloud: false) }
            }
        }
    }

    // OFF로 전환할 때는 확인 alert부터 띄우고, alert에서 실제로 끄기를 선택했을 때만 값을 반영한다
    private var iCloudToggleBinding: Binding<Bool> {
        Binding(
            get: { useICloud },
            set: { newValue in
                if newValue {
                    useICloud = true
                    Task { await homeViewModel.syncICloudStorage(toICloud: true) }
                } else {
                    showTurnOffConfirm = true
                }
            }
        )
    }

    private var statusText: String? {
        if homeViewModel.isICloudMigrating {
            return "동기화 중"
        }

        guard let lastSync = UserDefaults.standard.lastICloudSyncDate else {
            return nil
        }

        return "마지막 동기화: \(relativeSyncTimeText(from: lastSync, now: now))"
    }

    private func relativeSyncTimeText(from date: Date, now: Date) -> String {
        let seconds = max(0, now.timeIntervalSince(date))

        if seconds < 60 {
            return "방금 전"
        }

        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes)분 전"
        }

        let hours = Int(seconds / 3600)
        if hours < 24 {
            return "\(hours)시간 전"
        }

        let days = Int(seconds / 86400)
        return "\(days)일 전"
    }
}
