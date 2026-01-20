# Bio Metric System

A cross-platform **Advanced Fingerprint Matching System** built with Flutter and Firebase. This application manages user authentication and biometric data visualization through a responsive dashboard.

## 📸 Screenshots

### 📱 Mobile App Interface

| Login Screen | Create Account | Dashboard |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/5a6464f4-4e26-4607-8387-ec6e86461af0" width="250" /> | <img src="https://github.com/user-attachments/assets/dd933775-2e4d-4f1b-901d-7abdfef18cd1" width="250" /> | <img src="https://github.com/user-attachments/assets/7b9661bb-16f7-4dcf-976f-5aa47060140e" width="250" /> |

| Drawer Menu | Upload Fingerprint | Case Management |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/ecf65d04-b49e-4a27-8e07-ff2266b8cb84" width="250" /> | <img src="https://github.com/user-attachments/assets/0b38a353-3109-41a1-9ee3-f35c9783ea94" width="250" /> | <img src="https://github.com/user-attachments/assets/1e68c782-8780-4f04-b025-493596769250" width="250" /> |

### 📊 Results & Management

| Match Result (Mobile) | Match Result (Detail) | Citizen Management |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/576261f8-2a4d-417e-8243-aa8de508c0d6" width="250" /> | <img src="https://github.com/user-attachments/assets/bd6cfb12-5da6-4495-a445-1a8fcfdcbf71" width="250" /> | <img src="https://github.com/user-attachments/assets/760e01da-98f5-4c49-aa9f-146564643b7e" width="250" /> |



## 🚀 Features

- **Cross-Platform Support:** Runs smoothly on Android, iOS, and Web.
- **Responsive Design:** Adaptive UI that fits large desktop screens and smaller mobile devices.
- **User Authentication:** Secure login system verifying credentials against a cloud database.
- **Admin Panel:** Special access controls for system administrators.
- **Biometric Data Management:** Interface for handling fingerprint data (integration pending/active).

### 1. Frontend (Flutter)
The user interface is built using **Flutter**, ensuring a seamless experience across Web, Windows, Linux, and Mobile.
- **Responsive Design:** Adapts to different screen sizes (Desktop vs Mobile).
- **Key Features:** User Login, Admin Dashboard, File Uploads.

### 2. Backend (Firebase)
- **Cloud Firestore:** Stores user data, logs, and authentication details.
- **Authentication:** Verifies user credentials (NIC/Password) against the database.

### 3. Biometric Engine (Python)
The core fingerprint matching logic is handled by a Python script: `fingerprint_matcher.py`.
- **Functionality:** Processes fingerprint images and performs matching algorithms to verify identity.
- **Integration:** Works alongside the main application to provide accurate biometric verification results.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Python 3.x
- Firebase Project configured

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/bio_metric_system.git
   ```

2. **Flutter App:**
   ```bash
   cd bio_metric_system
   flutter pub get
   flutter run
   ```

3. **Python Backend:**
   Ensure you have the required Python libraries installed (e.g., OpenCV, NumPy).
   ```bash
   # Example installation
   pip install opencv-python numpy
   python fingerprint_matcher.py
   ```

## 🔑 Admin Access
The admin ID and Password work only in Web
- **Default Admin ID:** `admin`
- **Default Password:** `admin123`
