# 🪽 윙키(Winky)

![UT용 스크린샷 최종본](https://github.com/user-attachments/assets/067b02e2-a1d9-4b2a-9861-baa8872b6352)

> 윙키와 함께 사진 한 장으로, 멀리 있어도 특별한 추억을 쌓아요

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)]()
[![Xcode](https://img.shields.io/badge/Xcode-15.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

---

## 🗂 목차
- [소개](#소개)
- [프로젝트 기간](#프로젝트-기간)
- [기술 스택](#기술-스택)
- [기능](#기능)
- [시연](#시연)
- [폴더 구조](#폴더-구조)
- [팀 소개](#팀-소개)
- [Git 컨벤션](#git-컨벤션)
- [테스트 방법](#테스트-방법)
- [프로젝트 문서](#프로젝트-문서)
- [라이선스](#lock_with_ink_pen-license)

---

## 📱 소개

> 가족들이 셀카 한 장으로 더 자연스럽게 연락하고, 즐겁게 소통할 수 있는 앱.

팀원들 모두 부모님과 떨어져 지내는 20대입니다. 
바쁜 일상 속에서 문득 부모님께 연락을 드릴 때, '지금 연락드려도 괜찮을까?', '이런 사소한 일까지 말씀드려도 될까?'와 같은 **고민들** 때문에 연락을 망설이게 될 때가 많습니다.
결국 "잘 지내시죠?" 같은 상투적인 말만 오가고, 일상의 소소한 교류는 점점 줄어들고 있었습니다. 저희는 이처럼 작은 것이라도 부담 없이 나누기 어려운 상황을 개선하고 싶었습니다.
그래서 이러한 상황을 자녀와 부모님 모두 익숙한 ‘사진’이라는 매체를 통해 개선해보려 합니다
- **자녀는 용건 없이도 부담 없이 자신의 일상을 공유하고**
- **부모님은 보고 싶은 자녀의 모습을 사진으로 바로 확인하며 안심하고**
- **자녀 또한 부모님의 사진을 보며 멀리서도 서로의 평안을 나눌 수 있도록 말이에요**
  
[🔗 테스트플라이드(빌드 4) 링크](https://testflight.apple.com/join/VUU891vx )


## 📆 프로젝트 기간
- 전체 기간: `2025.09.01 - 2025.11.28`
- 개발 기간: `2025.10.02 - YYYY.MM.DD`


## 🛠 기술 스택

- Swift / SwiftUI / UIKit / Firebase
- 아키텍처: MVVM
- 기타 도구: Figma, Notion, Discord


## 🌟 주요 기능

- 게시물 업로드하고 소통하기
- 상대방이 올린 사진에 댓글, 스티커로 반응하기
- 지난 게시물 둘러보기


## 🖼 화면 구성 및 시연

| 기능 | 설명 | 이미지 |
|------|------|--------|
| 게시물 업로드하기 | 카메라를 켜 전면, 후면을 촬영하고 캡션과 함께 올려보세요 | ![gif](링크) |
| 상대방 게시물에 리액션 남기기 | 스티커와 댓글 남기기 | ![gif](링크) |


## 🧱 폴더 구조

```
📦DonDog-iOS
┣ 📂App
┃ ┣ 📂AppDelegate
┃ ┣ 📂Coordinator
┃ ┗ 📂Factory
┣ 📂Core
┃ ┣ 📂Extensions
┃ ┣ 📂Resources
┃ ┣ 📂Services
┃ ┗ 📂Utils
┣ 📂Presentation
┃ ┣ 📂Archive
┃ ┃ ┣ 📂Models
┃ ┃ ┣ 📂ViewModels
┃ ┃ ┗ 📂Views
┃ ┣ 📂Auth
┃ ...
```


## 🧑‍💻 팀 소개

| 이름 | 역할 | GitHub |
|------|------|--------|
| 체리 | Desinger | [@zz6cherry](https://github.com/zz6cherry) |
| 앤지 | Desinger | [@legnasy](https://github.com/legnasy) |
| 현 | iOS Developer | [@nuyhhyun](https://github.com/nuyhhyun) |
| 유우 | iOS Developer | [@ohcuy](https://github.com/ohcuy) |
| 이토 | iOS Developer | [@changjaemun](https://github.com/changjaemun) |
| 주디제이 | iOS Developer | [@JUDYLEE-cloud](https://github.com/JUDYLEE-cloud) |


## 🔖 브랜치 전략
- `main`: 배포 가능한 안정 버전
- `dev`: 통합 개발 브랜치
- `feat/*`: 기능 개발 브랜치
- `fix/*`: 버그 수정 브랜치

## 🌀 커밋 메시지 컨벤션 예시
- feat/fix/docs/design/refact/test/chore

## ✅ 테스트 방법

1. 이 저장소를 클론합니다.
2. Firestore에서 GoogleService-Info.plist 파일을 저장받아 추가한다. 
3. 시뮬레이터 환경 설정: iOS 18 이상
4. `Cmd + R`로 실행 / `Cmd + U`로 테스트 실행


## 📎 프로젝트 문서

- [기획/디자인/개발 문서 및 회의록 노션(비공개)](https://www.notion.so/posacademy/DONDOG-25d2b843d5af804196a6d5a842a0a295?source=copy_link)


## 📝 License

This project is licensed under the ~~[CHOOSE A LICENSE](https://choosealicense.com). and update this line~~
