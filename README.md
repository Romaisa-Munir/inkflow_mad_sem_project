# InkFlow - Book Reading & Writing Platform

## Overview
InkFlow is a Flutter-based mobile application that provides a platform for reading and writing books. The app allows users to browse through books, follow authors, and maintain their personal library. Writers can create and publish their own stories with customizable chapters. This project is a collaborative semester assignment that will be enhanced with Firebase backend integration in future iterations.

## Features

### For Readers
- **Book Discovery**: Browse through a collection of books with cover images
- **Author Following**: Follow favorite authors to stay updated with their new releases
- **Personal Library**: Save books to your personal library for easy access
- **Book Details**: View comprehensive information about books including descriptions
- **Search Functionality**: Search for books and authors throughout the app

### For Writers
- **Book Creation**: Create new books with title, description, and cover image
- **Chapter Management**: Add and edit chapters for your books
- **Content Pricing**: Set prices for individual chapters
- **Writing Dashboard**: Manage all your written content in one place

### User Authentication
- **Sign Up/Login**: Create an account or log in to access personalized features

## Screenshots
![Picture 1](https://github.com/user-attachments/assets/0c25af0b-6087-4ad2-8e4a-5922fbed0e8c)
![Picture 2](https://github.com/user-attachments/assets/e0749496-3b67-4106-8797-70d6a8f6f463)
![Picture 3](https://github.com/user-attachments/assets/02cda46d-21e5-403b-ab87-b9aee11c2fbd)
![Picture 4](https://github.com/user-attachments/assets/6c2f8251-f651-4002-9c94-cb7d3065be55)
![Picture 5](https://github.com/user-attachments/assets/7990a5e9-a0e6-41a3-8d8d-58b4e4dff310)
![Picture 6](https://github.com/user-attachments/assets/0c11f4ef-b460-4684-baf8-45a0a61c7f49)
![Picture 7](https://github.com/user-attachments/assets/9114a943-3e51-47a0-b0ea-98cdb41ee77b)

## Technologies Used
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: StatefulWidget
- **UI Components**: Material Design
- **Packages**:
  - `google_fonts` - For custom typography
  - `standard_searchbar` - For search functionality
  - `image_picker` - For selecting book cover images

## Installation and Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio or VS Code
- An Android or iOS device/emulator

### Steps
1. Clone the repository
   ```
   git clone https://github.com/Romaisa-Munir/inkflow_mad_sem_project.git
   ```

2. Navigate to the project directory
   ```
   cd inkflow_mad_sem_project
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## Project Structure
```
inkflow_mad_sem_project/
├── .dart_tool/
├── .idea/
├── android/
├── assets/
├── build/
├── lib/
│   ├── models/
│   │   ├── book_model.dart
│   │   └── chapter_model.dart
│   ├── pages/
│   │   ├── login_signup/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── profile/
│   │   ├── AddChapterPage.dart
│   │   ├── BookDetailsPage.dart
│   │   ├── create_book_page.dart
│   │   └── writing_dashboard.dart
│   ├── widgets/
│   │   ├── book_card.dart
│   │   └── chapter_card.dart
│   └── main.dart
```

## Current Status
- Frontend implementation complete with navigation and UI elements
- User authentication screens implemented
- Book browsing and creation functionality
- Author profiles and following system
- Chapter creation and management for writers

## Future Plans
- Firebase integration for backend functionality
- User authentication with Firebase Auth
- Cloud storage for book covers and content
- Real-time updates for new book releases
- Social features such as comments and ratings
- Payment integration for purchasing books

## Contributors
- **Romaisa Munir** ([@Romaisa-Munir](https://github.com/Romaisa-Munir))
- **Warda Khan** ([@wardakhan0101](https://github.com/wardakhan0101))

## License

This project is for educational purposes.

- [GitHub Repository](https://github.com/Romaisa-Munir/WebTechSemProject)
