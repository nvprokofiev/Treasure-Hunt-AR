# Treasure Hunt AR

Treasure Hunt AR is an iOS app designed to make treasure hunts more exciting using Augmented Reality (AR). I built this app in about 8 hours for my kid’s birthday, combining their love for treasure hunts and secrets into a fun game.

| **Drawing** | **Scanning** |
|-------------|--------------|
| ![Drawing](https://github.com/user-attachments/assets/5e77301f-5999-44f9-ae2f-d5b2d6afa3a1) | ![Scanning](https://github.com/user-attachments/assets/7c42494c-2809-44e3-bb02-53eec06e276e) |


## How It Works

1. **Setup**: I hide gifts in a box with a code (e.g., 78345). Then, I take pictures of locations, mark each picture with a number, and use the app to draw that number in AR at the corresponding place. The numbers are stored with GPS coordinates.

2. **Hunt**: My kid uses the app in scan mode to find the places based on the photos. When they reach the correct spot, the hidden number appears in AR. Collecting all the numbers gives them the code to open the box and get the gifts.

**Note**: The app launches in the Scan mode, to switch to the "Artist" mode tap three times to the area below the notch(island). Do the same to switch back. It is done this way to prevent accidental activation when the kid gets too excited.

## Development

- Built in Swift and SwiftUI.
- Uses ARKit for augmented reality features.
- Took around 8 hours to develop after getting the idea a couple of nights before the birthday.

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/TreasureHuntAR.git
