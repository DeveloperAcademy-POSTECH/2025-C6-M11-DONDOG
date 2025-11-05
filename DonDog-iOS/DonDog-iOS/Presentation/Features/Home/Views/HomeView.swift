//
//  HomeView.swift
//  DonDog-iOS
//
//  Created by Ito on 11/3/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: FeedViewModel
    @State var currentIndex: Int = 0
    @State var showCameraView: Bool = false
    @StateObject private var cameraViewModel = CameraViewModel()
    
    var body: some View {
        VStack {
            CustomNavigationBar(leadingType: .none, centerType: .title(title: "LOGO"), trailingType: .none, navigationColor: .black)
            
            Text("\(DateUtils.string(from: .now, format: .weekDay))")
            
            Spacer()
            
            Text(currentIndex == 0 ? "오전을 기록해보세요" : "오후를 기록해보세요")
            
            Spacer()
            
            HStack {
                Image(systemName: "clock")
                Text("1:32")
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 99)
                    .fill(.ddGray200)
            }
            Spacer()
            
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.ddGray300)
                    HStack {
                        Image(systemName: "person")
                            .resizable()
                            .padding(7)
                            .frame(maxWidth: 86)
                        Text("name")
                        Spacer()
                        
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.ddGray300)
                    HStack {
                        Spacer()
                        Text("name")
                        Image(systemName: "person")
                            .resizable()
                            .padding(7)
                            .frame(maxWidth: 86)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: 102)
            
            TabView(selection: $currentIndex) {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DateUtils.isOver3daysSinceLastUpload() ? .red : .ddGray200 )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DateUtils.isOver3daysSinceLastUpload() ? .red : .ddGray200 )
                }.padding(.horizontal, 20)
                    .tag(0)
                
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ddGray400)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ddGray400)
                }.padding(.horizontal, 20)
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(maxHeight: 270)
            
            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(currentIndex == 0 ? .ddGray700 : .ddGray100)
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(currentIndex == 0 ? .ddGray100 : .ddGray700)
            }
            .padding()
            
            Spacer()
            
            ZStack {
                Rectangle()
                    .frame(maxHeight: 117)
                    .foregroundStyle(.ddGray400)
                
                HStack {
                    Spacer()
                    Button {
                        coordinator.push(.archive)
                    } label: {
                        VStack(spacing: 2) {
                            Image("CalendarButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                                .foregroundStyle(.ddPrimaryBlue)
                            Text("보관함")
                                .foregroundStyle(.ddPrimaryBlue)
                                .font(.captionRegular14)
                        }
                    }
                    .hapticFeedback(.medium)
                    Spacer()
                    Button {
                        showCameraView = true
                    }label: {
                        Circle()
                            .foregroundColor(.ddWhite)
                            .frame(width: 80, height: 80)
                            .background {
                                Circle()
                                    .foregroundColor(.ddPrimaryBlue)
                                    .frame(width: 90, height: 90)
                            }
                            .offset(y: -10)
                    }
                    .hapticFeedback(.medium)
                    Spacer()
                    Button {
                        //
                    } label: {
                        VStack(spacing: 2) {
                            Image("AddStickerButtonDisabled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                            Text("스티커")
                                .foregroundStyle(.ddGray500)
                                .font(.captionRegular14)
                        }
                        
                    }
                    .hapticFeedback(.medium)
                    Spacer()
                }.padding(.bottom, 22)
            }
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraViewContainer(
                cameraViewModel: cameraViewModel,
                feedViewModel: viewModel,
                isPresented: $showCameraView
            )
        }
    }
}
